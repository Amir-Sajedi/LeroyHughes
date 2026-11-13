extends Area2D

signal Death

func _on_body_entered(body):
	emit_signal("Death") # Replace with function body.
	
