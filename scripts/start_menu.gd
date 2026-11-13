extends Control

const NEW_BG: CompressedTexture2D = preload("res://assets/textures/additional_pics/start menu.png")

@onready var bg = $BG
@onready var click_sfx: AudioStreamPlayer2D = $button_click
@onready var continue_button: Button = $Start
@onready var new_game_button: Button = $NewGame
@onready var confirm_dialog: ConfirmationDialog = $NewGameConfirm
@onready var difficulty_overlay: Control = $DifficultyOverlay
@onready var easy_button: Button = $DifficultyOverlay/Easy
@onready var hard_button: Button = $DifficultyOverlay/Hard


func _ready() -> void:
	MusicPlayer.Music_stop()
	_refresh_continue_button()
	difficulty_overlay.visible = false


func _process(_delta: float) -> void:
	bg.Sprite.texture = NEW_BG
	bg.moving = false


func _refresh_continue_button() -> void:
	var save_exists: bool = SaveManager.has_save()
	continue_button.disabled = not save_exists
	continue_button.tooltip_text = "" if save_exists else "No save game found yet."

	if save_exists:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func _show_difficulty_selection() -> void:
	await SceneTransition.run_transition(_reveal_difficulty_selection)


func _reveal_difficulty_selection() -> void:
	difficulty_overlay.visible = true
	if DifficultyManager.is_easy():
		easy_button.grab_focus()
	else:
		hard_button.grab_focus()


func _select_difficulty(difficulty: int) -> void:
	click_sfx.play()
	DifficultyManager.set_difficulty(difficulty)
	_start_new_game()


func _on_easy_pressed() -> void:
	_select_difficulty(DifficultyManager.Difficulty.EASY)


func _on_hard_pressed() -> void:
	_select_difficulty(DifficultyManager.Difficulty.HARD)


func _on_difficulty_mouse_entered() -> void:
	click_sfx.play()


func _on_start_pressed() -> void:
	if not SaveManager.has_save():
		return

	click_sfx.play()
	SaveManager.set_difficulty(DifficultyManager.get_difficulty_name())
	SceneTransition.change_scene_to_file(SaveManager.get_current_level())


func _on_new_game_pressed() -> void:
	click_sfx.play()
	if SaveManager.save_file_exists():
		confirm_dialog.popup_centered()
	else:
		_show_difficulty_selection()


func _on_new_game_confirmed() -> void:
	click_sfx.play()
	_show_difficulty_selection()


func _start_new_game() -> void:
	SaveManager.start_new_game(DifficultyManager.get_difficulty_name())
	SceneTransition.change_scene_to_file(SaveManager.get_first_level_path())


func _on_quit_pressed() -> void:
	click_sfx.play()
	SaveManager.quit_game()


func _on_options_pressed() -> void:
	SceneTransition.change_scene_to_file("res://scenes/options.tscn")


func _on_options_mouse_entered() -> void:
	click_sfx.play()


func _on_quit_mouse_entered() -> void:
	click_sfx.play()


func _on_start_mouse_entered() -> void:
	if not continue_button.disabled:
		click_sfx.play()


func _on_new_game_mouse_entered() -> void:
	click_sfx.play()
