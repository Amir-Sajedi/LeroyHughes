extends Node2D

@onready var plane = $Plane

var speed = 200
func _process(delta: float) -> void:
	plane.global_position.x -= delta * speed
