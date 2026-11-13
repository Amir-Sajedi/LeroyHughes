extends Node
## Central source of truth for the selected difficulty and its adjustments.
##
## The active difficulty lives here for the whole session, so it survives
## level transitions and scene reloads. SaveManager stores the value on disk
## between runs.

signal difficulty_changed(difficulty: int)

enum Difficulty { EASY, HARD }

const DEFAULT_DIFFICULTY: int = Difficulty.HARD
const LEVEL_3_PATH: String = "res://scenes/Level3.tscn"

## Easy mode keeps about half of the traps in regular levels and only a
## quarter in the final level, making Level 3 noticeably more forgiving.
const EASY_TRAP_KEEP_RATIO: float = 0.5
const EASY_FINAL_LEVEL_TRAP_KEEP_RATIO: float = 0.25

var _difficulty: int = DEFAULT_DIFFICULTY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if SaveManager.has_save():
		_difficulty = difficulty_from_name(SaveManager.get_difficulty())


func set_difficulty(difficulty: int) -> void:
	var next_difficulty: int = clampi(difficulty, Difficulty.EASY, Difficulty.HARD)
	if next_difficulty == _difficulty:
		return

	_difficulty = next_difficulty
	difficulty_changed.emit(_difficulty)


func get_difficulty() -> int:
	return _difficulty


func is_easy() -> bool:
	return _difficulty == Difficulty.EASY


func is_hard() -> bool:
	return _difficulty == Difficulty.HARD


func is_timer_enabled() -> bool:
	return not is_easy()


func get_difficulty_name() -> String:
	return "easy" if is_easy() else "hard"


func difficulty_from_name(value: String) -> int:
	return Difficulty.EASY if value.to_lower() == "easy" else Difficulty.HARD


## Number of traps to keep. Hard mode always keeps every trap.
func get_trap_keep_count(total: int, level_path: String = "", is_final_level: bool = false) -> int:
	if total <= 0 or is_hard():
		return total

	var keep_ratio: float = EASY_TRAP_KEEP_RATIO
	if is_final_level or level_path == LEVEL_3_PATH:
		keep_ratio = EASY_FINAL_LEVEL_TRAP_KEEP_RATIO
	return maxi(1, roundi(float(total) * keep_ratio))


## Keeps traps spread across the level instead of deleting a contiguous block,
## which could leave one section with no hazards at all.
func should_keep_trap(index: int, total: int, keep_count: int) -> bool:
	if keep_count >= total:
		return true
	if keep_count <= 0 or total <= 0:
		return false
	return (index * keep_count) % total < keep_count
