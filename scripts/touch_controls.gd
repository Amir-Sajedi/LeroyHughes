extends Node2D
class_name TouchControls

## On-screen controls for touch devices.
##
## The buttons drive the same input actions as the keyboard (left, right and
## jump), so the player script does not need a mobile-specific code path.

const NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 0.85)
const PRESSED_MODULATE := Color(0.72, 0.94, 1.0, 1.0)
const PRESSED_SCALE := 0.92
const TOUCH_EMULATION_SETTING := "input_devices/pointing/emulate_touch_from_mouse"

@onready var left_button: TouchScreenButton = $Left
@onready var right_button: TouchScreenButton = $Right
@onready var jump_button: TouchScreenButton = $Jump
@onready var menu_button: TouchScreenButton = $Menu

var _touch_enabled: bool = false
var _preview_enabled: bool = false
var _controls_allowed: bool = true
var _held_actions: Dictionary = {}
var _base_scales: Dictionary = {}
var _tweens: Dictionary = {}


func _ready() -> void:
	var emulate_touch: bool = bool(ProjectSettings.get_setting(TOUCH_EMULATION_SETTING, false))
	_touch_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or emulate_touch
	set_controls_visible(true)

	_setup_button(left_button, _on_left_pressed, _on_left_released)
	_setup_button(right_button, _on_right_pressed, _on_right_released)
	_setup_button(jump_button, _on_jump_pressed, _on_jump_released)
	_setup_button(menu_button)
	menu_button.pressed.connect(_on_menu_pressed)

	if not _touch_enabled and OS.is_debug_build():
		print("[TouchControls] No touchscreen detected. Press F10 to preview the touch controls.")


func set_controls_visible(is_visible: bool) -> void:
	_controls_allowed = is_visible
	_update_visibility()


func _update_visibility() -> void:
	visible = _controls_allowed and (_touch_enabled or _preview_enabled)
	if not visible:
		_release_held_actions()


func _setup_button(
	button: TouchScreenButton,
	on_pressed: Callable = Callable(),
	on_released: Callable = Callable()
) -> void:
	_base_scales[button] = button.scale
	button.modulate = NORMAL_MODULATE
	button.pressed.connect(_animate_button.bind(button, true))
	button.released.connect(_animate_button.bind(button, false))
	if on_pressed.is_valid():
		button.pressed.connect(on_pressed)
	if on_released.is_valid():
		button.released.connect(on_released)


func _on_left_pressed() -> void:
	_press_action("left")


func _on_left_released() -> void:
	_release_action("left")


func _on_right_pressed() -> void:
	_press_action("right")


func _on_right_released() -> void:
	_release_action("right")


func _on_jump_pressed() -> void:
	_press_action("jump")


func _on_jump_released() -> void:
	_release_action("jump")


func _press_action(action: StringName) -> void:
	if _held_actions.has(action):
		return
	_held_actions[action] = true
	Input.action_press(action)


func _release_action(action: StringName) -> void:
	if not _held_actions.has(action):
		return
	_held_actions.erase(action)
	Input.action_release(action)


## Releases every action the controls are currently holding. This also runs when
## the controls are hidden, the window loses focus, or the scene changes while a
## finger is still down, preventing a stuck movement/jump input.
func _release_held_actions() -> void:
	for action: StringName in _held_actions:
		Input.action_release(action)
	_held_actions.clear()

	if not is_inside_tree():
		return

	for button: TouchScreenButton in _base_scales:
		_stop_tween(button)
		button.scale = _base_scales[button]
		button.modulate = NORMAL_MODULATE


func _on_menu_pressed() -> void:
	_release_held_actions()
	SaveManager.save_game("touch_menu")
	SceneTransition.change_scene_to_file("res://scenes/start_menu.tscn")


func _animate_button(button: TouchScreenButton, is_pressed: bool) -> void:
	var base_scale: Vector2 = _base_scales[button]
	var target_scale := base_scale * (PRESSED_SCALE if is_pressed else 1.0)
	var target_modulate := PRESSED_MODULATE if is_pressed else NORMAL_MODULATE

	_stop_tween(button)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale", target_scale, 0.06)
	tween.tween_property(button, "modulate", target_modulate, 0.06)
	_tweens[button] = tween


func _stop_tween(button: TouchScreenButton) -> void:
	if not _tweens.has(button):
		return

	var running_tween: Tween = _tweens[button]
	if running_tween.is_valid():
		running_tween.kill()
	_tweens.erase(button)


## Desktop-only preview. Export builds never take this path, and touch devices
## already show the controls automatically.
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() or _touch_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_preview_enabled = not _preview_enabled
		_update_visibility()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_held_actions()


func _exit_tree() -> void:
	_release_held_actions()
