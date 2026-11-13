extends Area2D
class_name LevelExit

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func animation() -> void:
	animated_sprite.play("default")
