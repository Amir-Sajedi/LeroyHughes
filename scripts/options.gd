extends Control


func _on_button_pressed() -> void:
	SceneTransition.change_scene_to_file("res://scenes/start_menu.tscn")


func _on_button_mouse_entered() -> void:
	$click.play() # Replace with function body.
