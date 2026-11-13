extends Control

@export var bg = preload("res://assets/textures/additional_pics/second_level.png")
@onready var background: TextureRect = $Background
func _on_button_pressed() -> void:
	SceneTransition.change_scene_to_file("res://scenes/start_menu.tscn")
func _ready():
	background.texture = bg


func _on_button_mouse_entered() -> void:
	$click.play() # Replace with function body.
