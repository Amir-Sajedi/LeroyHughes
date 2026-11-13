extends CanvasLayer
## Centralized fade-to-black transition for every scene change.
##
## Gameplay and UI code call the methods below instead of touching
## SceneTree.change_scene_* directly. The overlay lives on its own high
## canvas layer, so it covers the HUD and menus and survives scene swaps.

const FADE_OUT_DURATION: float = 0.25
const FADE_IN_DURATION: float = 0.3
const TRANSITION_LAYER: int = 128

var _overlay: ColorRect
var _tween: Tween
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = TRANSITION_LAYER

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	# Start fully black so the first frame of the game fades in smoothly.
	_overlay.modulate.a = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_busy = true
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, FADE_IN_DURATION)
	_finish_transition()


func is_transitioning() -> bool:
	return _busy


## Fades to black, switches to the given scene file, then fades back in.
func change_scene_to_file(path: String) -> void:
	if _busy:
		return

	var tree: SceneTree = get_tree()
	await _start_transition()
	var error: Error = tree.change_scene_to_file(path)
	if error != OK:
		push_error("[SceneTransition] Failed to open scene %s (error %d)." % [path, error])
		await _end_transition()
		return

	await tree.scene_changed
	await tree.process_frame
	await _end_transition()


## Fades to black, switches to the given packed scene, then fades back in.
func change_scene_to_packed(scene: PackedScene) -> void:
	if _busy:
		return

	var tree: SceneTree = get_tree()
	await _start_transition()
	var error: Error = tree.change_scene_to_packed(scene)
	if error != OK:
		push_error("[SceneTransition] Failed to open packed scene (error %d)." % error)
		await _end_transition()
		return

	await tree.scene_changed
	await tree.process_frame
	await _end_transition()


## Fades to black, reloads the current scene, then fades back in.
func reload_current_scene() -> void:
	if _busy:
		return

	var tree: SceneTree = get_tree()
	await _start_transition()
	var error: Error = tree.reload_current_scene()
	if error != OK:
		push_error("[SceneTransition] Failed to reload the scene (error %d)." % error)
		await _end_transition()
		return

	await tree.scene_changed
	await tree.process_frame
	await _end_transition()


## Fades to black, runs an in-scene full-screen swap (for example showing the
## victory screen), then fades back in.
func run_transition(action: Callable) -> void:
	if _busy:
		return

	await _start_transition()
	action.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _end_transition()


func _start_transition() -> void:
	_busy = true
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, FADE_OUT_DURATION)


func _end_transition() -> void:
	await _fade_to(0.0, FADE_IN_DURATION)
	_finish_transition()


func _finish_transition() -> void:
	_busy = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false


func _fade_to(alpha: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_overlay.visible = true
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_overlay, "modulate:a", alpha, duration)
	await _tween.finished
