extends Area2D

@onready var Animation_jump_pad = $Jump_pad_animation
@export var jump_force = 300

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		Animation_jump_pad.play("jump")
		MusicPlayer.sfx_player("jump")
		body.jump(jump_force)
