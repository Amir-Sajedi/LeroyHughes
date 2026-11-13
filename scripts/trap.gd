extends Node2D

signal touched_player

func _on_spike_ball_body_entered(body: Node2D) -> void:
	if body is player:
		touched_player.emit() 


func _on_saw_body_entered(body: Node2D) -> void:
	if body is player:
		touched_player.emit() 
