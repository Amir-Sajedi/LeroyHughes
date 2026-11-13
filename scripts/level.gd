extends Node2D

@export var level_time: int = 60
@export var next_bg: CompressedTexture2D = preload("res://assets/textures/bg/Gray.png")
@export var next_level: PackedScene = null
@export var is_final_level: bool = false

@onready var hud: GameHUD = $UILayer/HUD
@onready var death_zone: Area2D = $DeathZone
@onready var player_node: player = $player
@onready var respawn_point: StartPoint = $StartPoint
@onready var exit: LevelExit = $Exit
@onready var bg: ParallaxBackground = $BG
@onready var ui: GameUI = $UILayer

var win: bool = false
var time_left: int = 0
var timer_node: Timer
var level_path: String = ""
var _is_transitioning: bool = false


func _ready() -> void:
	level_path = scene_file_path
	var default_spawn: Vector2 = respawn_point.get_spawn_pos()
	SaveManager.begin_level(level_path, default_spawn)

	player_node.global_position = get_respawn_position()
	player_node.velocity = Vector2.ZERO

	MusicPlayer.Music_play()

	_apply_difficulty_traps()

	if not exit.body_entered.is_connected(_on_exit_body_entered):
		exit.body_entered.connect(_on_exit_body_entered)
	if not death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		death_zone.body_entered.connect(_on_death_zone_body_entered)

	var bg_sprite := bg.get_node("ParallaxLayer/Sprite2D") as Sprite2D
	if bg_sprite != null:
		bg_sprite.texture = next_bg

	time_left = level_time
	var timer_enabled: bool = DifficultyManager.is_timer_enabled()
	hud.set_timer_visible(timer_enabled)

	if timer_enabled:
		timer_node = Timer.new()
		timer_node.name = "Timer"
		timer_node.wait_time = 1.0
		add_child(timer_node)
		timer_node.timeout.connect(_on_level_timer_timeout)
		timer_node.start()
		hud.set_time_lebal(time_left)


func _apply_difficulty_traps() -> void:
	var traps: Array = get_tree().get_nodes_in_group("traps")
	var total: int = traps.size()
	var keep_count: int = DifficultyManager.get_trap_keep_count(total, level_path, is_final_level)

	for index in total:
		var trap: Node = traps[index]
		if not DifficultyManager.should_keep_trap(index, total, keep_count):
			trap.queue_free()
			continue

		if trap.has_signal("touched_player") and not trap.touched_player.is_connected(_on_trap_touched_player):
			trap.touched_player.connect(_on_trap_touched_player)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		SaveManager.quit_game()
	elif Input.is_action_just_pressed("reset") and not _is_transitioning:
		_is_transitioning = true
		SceneTransition.reload_current_scene()


func get_respawn_position() -> Vector2:
	var checkpoint: Vector2 = SaveManager.get_checkpoint_position(level_path)
	if checkpoint.is_finite():
		return checkpoint
	return respawn_point.get_spawn_pos()


func player_reset() -> void:
	if _is_transitioning:
		return

	player_node.global_position = get_respawn_position()
	player_node.velocity = Vector2.ZERO
	player_node.active = true

	if DifficultyManager.is_timer_enabled():
		time_left = level_time
		hud.set_time_lebal(time_left)


func _on_level_timer_timeout() -> void:
	if not DifficultyManager.is_timer_enabled():
		return

	if time_left == 4:
		MusicPlayer.timer_play()

	if win or _is_transitioning:
		return

	time_left -= 1
	hud.set_time_lebal(max(time_left, 0))

	if time_left <= 0:
		player_reset()


func _on_trap_touched_player() -> void:
	if _is_transitioning:
		return
	player_reset()
	MusicPlayer.sfx_player("hurt")


func _on_death_zone_body_entered(body: Node2D) -> void:
	if _is_transitioning:
		return
	if body is player:
		player_reset()
		MusicPlayer.sfx_player("hurt")


func _on_exit_body_entered(body: Node2D) -> void:
	if _is_transitioning or win:
		return
	if not body is player:
		return

	var next_scene: PackedScene = next_level
	if next_scene == null and not is_final_level:
		return

	_is_transitioning = true
	win = true
	exit.animation()
	player_node.active = false
	player_node.Animation_player.play("idle")

	var next_path: String = ""
	if is_final_level:
		SaveManager.complete_game(level_path)
	else:
		next_path = next_scene.resource_path
		if next_path.is_empty():
			next_path = SaveManager.get_next_level_path(level_path)
		SaveManager.complete_level(level_path, next_path)

	await get_tree().create_timer(1.0).timeout

	if is_final_level:
		await SceneTransition.run_transition(_show_victory_screen)
		return

	SceneTransition.change_scene_to_packed(next_scene)


func _show_victory_screen() -> void:
	ui.show_win_screen(true)
