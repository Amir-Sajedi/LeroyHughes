extends Area2D
## Touch this area to make it the current respawn point and autosave.

@onready var _sign: Sprite2D = $Sign
@onready var _spawn_point: Marker2D = $SpawnPoint

const ACTIVE_COLOR: Color = Color(0.55, 1.0, 0.55, 1.0)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_visual()


func _on_body_entered(body: Node2D) -> void:
	if not body is player:
		return

	var level_path: String = _get_level_path()
	if level_path.is_empty():
		return

	var spawn_position: Vector2 = _spawn_point.global_position
	var saved_position: Vector2 = SaveManager.get_checkpoint_position(level_path)
	if saved_position.is_finite() and saved_position.is_equal_approx(spawn_position):
		return

	SaveManager.checkpoint_reached(level_path, spawn_position)
	_refresh_visual()


func _refresh_visual() -> void:
	var level_path: String = _get_level_path()
	if level_path.is_empty():
		_sign.modulate = Color.WHITE
		return

	var saved_position: Vector2 = SaveManager.get_checkpoint_position(level_path)
	var is_active: bool = (
		saved_position.is_finite()
		and saved_position.is_equal_approx(_spawn_point.global_position)
	)
	_sign.modulate = ACTIVE_COLOR if is_active else Color.WHITE


func _get_level_path() -> String:
	# Walk up to the level scene root. The checkpoint's owner can be unset when
	# scenes are instantiated at runtime, so do not rely on it alone.
	var node: Node = get_parent()
	while node != null:
		if not node.scene_file_path.is_empty():
			return node.scene_file_path
		node = node.get_parent()

	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		return current_scene.scene_file_path
	return ""
