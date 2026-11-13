extends CanvasLayer
class_name GameUI

@onready var touch_controls = $TouchControls


func _ready() -> void:
	show_win_screen(false)


func show_win_screen(flag: bool) -> void:
	$Win_screen.visible = flag
	touch_controls.set_controls_visible(not flag)
