extends StaticBody2D
class_name StartPoint

@onready var spawn_position: Marker2D = $Spawn_position


func get_spawn_pos() -> Vector2:
	return spawn_position.global_position
