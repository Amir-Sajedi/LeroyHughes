extends Node
## Owns persistent progress and save-file I/O.
##
## Gameplay code talks to this autoload through save_game(), load_game(),
## has_save(), delete_save(), get_value() and set_value(). The data dictionary
## is intentionally JSON-friendly so it can be written with JSON.stringify().

signal save_started
signal save_finished(success: bool)
signal save_loaded(success: bool)
signal progress_reset

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://savegame.json"
const TEMP_PATH: String = "user://savegame.json.tmp"
const BACKUP_PATH: String = "user://savegame.json.bak"
const DEFAULT_DIFFICULTY: String = "hard"

const FIRST_LEVEL_PATH: String = "res://scenes/Level1.tscn"
const LEVEL_ORDER: Array[String] = [
	"res://scenes/Level1.tscn",
	"res://scenes/level_2.tscn",
	"res://scenes/Level3.tscn",
]

## Persistent progress only. Run state (velocity, level timer, etc.) stays in
## the level/player scripts and is never written to disk.
var _data: Dictionary = {}
var _save_exists: bool = false
var _session_active: bool = false
var _is_saving: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_data = _default_data()
	load_game()


func _notification(what: int) -> void:
	# The window close request is handled synchronously, before Godot quits.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _session_active:
			save_game("window_close")


## Writes the current progress atomically. Returns true on success.
func save_game(reason: String = "manual") -> bool:
	if _is_saving:
		return false
	if _data.is_empty():
		_data = _default_data()

	_is_saving = true
	save_started.emit()

	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"reason": reason,
		"data": _data.duplicate(true),
	}
	var success: bool = _write_atomic(JSON.stringify(payload, "\t"))

	if success:
		_save_exists = true
		_session_active = true

	_is_saving = false
	save_finished.emit(success)
	return success


## Loads the save from disk, with fallbacks for missing/corrupted files.
## Returns false when no usable save exists; _data is then a fresh default.
func load_game() -> bool:
	_data = _default_data()
	_save_exists = false
	_session_active = false

	var loaded: Variant = _read_valid_save(SAVE_PATH)
	var source_path: String = SAVE_PATH
	if loaded == null:
		loaded = _read_valid_save(BACKUP_PATH)
		source_path = BACKUP_PATH
	if loaded == null:
		loaded = _read_valid_save(TEMP_PATH)
		source_path = TEMP_PATH

	if loaded == null:
		_data = _default_data()
		save_loaded.emit(false)
		return false

	_data = _sanitize(loaded)

	# If we recovered from the backup/temp file, repair the main file too.
	if source_path != SAVE_PATH:
		_repair_main_file(source_path)

	_save_exists = true
	save_loaded.emit(true)
	return true


func has_save() -> bool:
	return _save_exists


## True when any save file exists on disk, even if it could not be loaded.
func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


func delete_save() -> bool:
	var success: bool = true
	for path: String in [SAVE_PATH, TEMP_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			success = false

	_data = _default_data()
	_save_exists = false
	_session_active = false
	progress_reset.emit()
	return success


## Starts a fresh run and immediately persists it.
func start_new_game(difficulty: String = DEFAULT_DIFFICULTY) -> bool:
	_data = _default_data()
	_data["difficulty"] = _sanitize_difficulty(difficulty)
	_session_active = true
	return save_game("new_game")


func quit_game() -> void:
	if _session_active:
		save_game("quit")
	get_tree().quit()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


## Values must be JSON-compatible (String, int, float, bool, Array, Dictionary).
func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	_session_active = true


func get_difficulty() -> String:
	return _sanitize_difficulty(_data.get("difficulty", DEFAULT_DIFFICULTY))


func set_difficulty(difficulty: String) -> void:
	_data["difficulty"] = _sanitize_difficulty(difficulty)
	_session_active = true


func get_first_level_path() -> String:
	return FIRST_LEVEL_PATH


func get_current_level() -> String:
	var level: String = str(_data.get("current_level", FIRST_LEVEL_PATH))
	return level if _is_known_level(level) else FIRST_LEVEL_PATH


func get_checkpoint_position(level_path: String) -> Vector2:
	var checkpoint: Dictionary = _data.get("checkpoint", {})
	if str(checkpoint.get("level", "")) != level_path:
		return Vector2.INF

	var x: Variant = checkpoint.get("x", null)
	var y: Variant = checkpoint.get("y", null)
	if not _is_number(x) or not _is_number(y):
		return Vector2.INF

	var position := Vector2(float(x), float(y))
	return position if position.is_finite() else Vector2.INF


func has_checkpoint(level_path: String) -> bool:
	return get_checkpoint_position(level_path).is_finite()


func set_checkpoint(level_path: String, position: Vector2) -> void:
	if not _is_known_level(level_path) or not position.is_finite():
		return
	_data["checkpoint"] = {
		"level": level_path,
		"x": position.x,
		"y": position.y,
	}
	_session_active = true


## Called by Checkpoint.tscn when the player touches one.
func checkpoint_reached(level_path: String, position: Vector2) -> bool:
	set_checkpoint(level_path, position)
	return save_game("checkpoint")


## Called when a level scene starts. This only updates in-memory state; the
## level-completed save already recorded the transition, so we avoid writing
## in the middle of a scene load/death reload.
func begin_level(level_path: String, default_spawn: Vector2) -> void:
	if not _is_known_level(level_path):
		return

	_data["current_level"] = level_path
	_unlock_level(level_path)
	_session_active = true

	if not has_checkpoint(level_path):
		set_checkpoint(level_path, default_spawn)


## Called before moving to the next level.
func complete_level(completed_level: String, next_level_path: String) -> bool:
	_mark_level_completed(completed_level)

	if _is_known_level(next_level_path):
		_data["current_level"] = next_level_path
		_unlock_level(next_level_path)
		_data["checkpoint"] = {"level": next_level_path}
	else:
		_data["game_completed"] = true

	_session_active = true
	return save_game("level_completed")


## Called when the final level is finished.
func complete_game(completed_level: String) -> bool:
	_mark_level_completed(completed_level)
	_data["game_completed"] = true
	# The game is finished, so a future Continue starts a fresh replay.
	_data["current_level"] = FIRST_LEVEL_PATH
	_data["checkpoint"] = {}
	_session_active = true
	return save_game("game_completed")


func get_next_level_path(level_path: String) -> String:
	var index: int = LEVEL_ORDER.find(level_path)
	if index >= 0 and index + 1 < LEVEL_ORDER.size():
		return LEVEL_ORDER[index + 1]
	return ""


func get_unlocked_levels() -> Array:
	return (_data.get("unlocked_levels", [FIRST_LEVEL_PATH]) as Array).duplicate()


func is_level_unlocked(level_path: String) -> bool:
	return (_data.get("unlocked_levels", []) as Array).has(level_path)


func is_game_completed() -> bool:
	return bool(_data.get("game_completed", false))


func _default_data() -> Dictionary:
	return {
		"current_level": FIRST_LEVEL_PATH,
		"checkpoint": {},
		"unlocked_levels": [FIRST_LEVEL_PATH],
		"completed_levels": [],
		"game_completed": false,
		"difficulty": DEFAULT_DIFFICULTY,
	}


func _sanitize(raw: Dictionary) -> Dictionary:
	var clean: Dictionary = _default_data()

	# Keep unknown JSON-safe keys so callers can extend progress through
	# set_value() (for example coins, lives or collected items).
	for key: Variant in raw.keys():
		if not clean.has(key):
			clean[key] = raw[key]

	var current_level: String = str(raw.get("current_level", FIRST_LEVEL_PATH))
	if not _is_known_level(current_level):
		current_level = FIRST_LEVEL_PATH
	clean["current_level"] = current_level

	var completed: Array = _valid_level_array(raw.get("completed_levels", []))
	var unlocked: Array = _valid_level_array(raw.get("unlocked_levels", []))
	if not unlocked.has(FIRST_LEVEL_PATH):
		unlocked.append(FIRST_LEVEL_PATH)

	for level: String in completed:
		if not unlocked.has(level):
			unlocked.append(level)
		var index: int = LEVEL_ORDER.find(level)
		if index >= 0 and index + 1 < LEVEL_ORDER.size():
			var next_level: String = LEVEL_ORDER[index + 1]
			if not unlocked.has(next_level):
				unlocked.append(next_level)

	if not unlocked.has(current_level):
		unlocked.append(current_level)

	clean["unlocked_levels"] = _order_levels(unlocked)
	clean["completed_levels"] = _order_levels(completed)
	clean["checkpoint"] = _sanitize_checkpoint(raw.get("checkpoint", {}))

	var completed_value: Variant = raw.get("game_completed", false)
	clean["game_completed"] = completed_value if typeof(completed_value) == TYPE_BOOL else false
	clean["difficulty"] = _sanitize_difficulty(raw.get("difficulty", DEFAULT_DIFFICULTY))

	return clean


func _sanitize_difficulty(raw: Variant) -> String:
	if typeof(raw) == TYPE_INT:
		return "easy" if int(raw) == 0 else "hard"
	return "easy" if str(raw).to_lower() == "easy" else "hard"


func _sanitize_checkpoint(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}

	var checkpoint: Dictionary = raw
	var level_path: String = str(checkpoint.get("level", ""))
	if not _is_known_level(level_path):
		return {}

	var x: Variant = checkpoint.get("x", null)
	var y: Variant = checkpoint.get("y", null)
	if not _is_number(x) or not _is_number(y):
		return {"level": level_path}

	var position := Vector2(float(x), float(y))
	if not position.is_finite():
		return {"level": level_path}

	return {"level": level_path, "x": position.x, "y": position.y}


func _valid_level_array(raw: Variant) -> Array:
	var result: Array = []
	if not raw is Array:
		return result

	for entry: Variant in raw:
		if entry is String and _is_known_level(entry) and not result.has(entry):
			result.append(entry)
	return result


func _order_levels(levels: Array) -> Array:
	var ordered: Array = []
	for level: String in LEVEL_ORDER:
		if levels.has(level):
			ordered.append(level)
	return ordered


func _is_known_level(level_path: String) -> bool:
	return LEVEL_ORDER.has(level_path)


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _unlock_level(level_path: String) -> void:
	if not _is_known_level(level_path):
		return
	var unlocked: Array = _data.get("unlocked_levels", [FIRST_LEVEL_PATH])
	if not unlocked.has(level_path):
		unlocked.append(level_path)
	_data["unlocked_levels"] = _order_levels(unlocked)


func _mark_level_completed(level_path: String) -> void:
	if not _is_known_level(level_path):
		return

	var completed: Array = _data.get("completed_levels", [])
	if not completed.has(level_path):
		completed.append(level_path)
	_data["completed_levels"] = _order_levels(completed)

	_unlock_level(level_path)
	var next_level: String = get_next_level_path(level_path)
	if not next_level.is_empty():
		_unlock_level(next_level)


func _read_valid_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[SaveManager] Could not open save file: %s" % path)
		return null

	var text: String = file.get_as_text()
	file.close()

	if text.strip_edges().is_empty():
		push_warning("[SaveManager] Save file is empty: %s" % path)
		return null

	var json := JSON.new()
	var parse_error: int = json.parse(text)
	if parse_error != OK:
		push_warning(
			"[SaveManager] Invalid JSON in %s at line %d: %s"
			% [path, json.get_error_line(), json.get_error_message()]
		)
		return null

	if not json.data is Dictionary:
		push_warning("[SaveManager] Save file root is not a dictionary: %s" % path)
		return null

	var wrapper: Dictionary = json.data
	var version_value: Variant = wrapper.get("version", -1)
	if not _is_number(version_value):
		push_warning("[SaveManager] Missing save-format version: %s" % path)
		return null

	var version: int = int(version_value)
	if version < 1 or version > SAVE_VERSION:
		push_warning(
			"[SaveManager] Unsupported save version %d in %s (current: %d)"
			% [version, path, SAVE_VERSION]
		)
		return null

	var raw_data: Variant = wrapper.get("data", null)
	if not raw_data is Dictionary:
		push_warning("[SaveManager] Save file has no data dictionary: %s" % path)
		return null

	var data: Dictionary = raw_data
	return _migrate(data, version)


## Future format changes go here. The returned dictionary is always sanitized
## by _sanitize() afterwards, so missing keys fall back to defaults.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# Example for the next version:
	# if from_version == 1:
	#     data["coins"] = 0
	if from_version < SAVE_VERSION:
		pass
	return data


func _write_atomic(json_text: String) -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Could not open temp save file for writing.")
		return false

	file.store_string(json_text)
	file.flush()
	var write_error: int = file.get_error()
	file.close()

	if write_error != OK:
		push_error("[SaveManager] Failed while writing the temp save file.")
		DirAccess.remove_absolute(TEMP_PATH)
		return false

	# Keep one backup of the previous good save before replacing it.
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(BACKUP_PATH)
		if DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH) != OK:
			push_warning("[SaveManager] Could not create the save backup.")

	var rename_error: int = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if rename_error != OK and FileAccess.file_exists(SAVE_PATH):
		# Some platforms refuse to rename over an existing file. The backup
		# above means the old save can still be restored if this fails.
		if DirAccess.remove_absolute(SAVE_PATH) == OK:
			rename_error = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)

	if rename_error != OK:
		push_error("[SaveManager] Could not replace the save file (error %d)." % rename_error)
		if not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(BACKUP_PATH):
			DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
		return false

	return true


func _repair_main_file(source_path: String) -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if DirAccess.copy_absolute(source_path, SAVE_PATH) != OK:
		push_warning("[SaveManager] Could not repair the main save file.")
