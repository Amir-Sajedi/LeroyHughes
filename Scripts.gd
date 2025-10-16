
uid://cacpjcwosd3ck

extends Control


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn") # Replace with function body.


func _on_button_mouse_entered() -> void:
	$click.play() # Replace with function body.

uid://dibd400iubn5h

extends ParallaxBackground

@onready var Sprite = $ParallaxLayer/Sprite2D
@export var moving = true 
@export var Bg_speed = 40


func _process(delta: float) -> void:
	if moving == true:
		Sprite.region_rect.position += delta * Vector2(-Bg_speed, -Bg_speed)
		if Sprite.region_rect.position > Vector2(64, 64):
			Sprite.region_rect.position = Vector2(0, 0)
	elif moving == false:
		Sprite.region_rect.position += delta * Vector2(-Bg_speed, -Bg_speed)
		
			

uid://ctgqm3jxdvwiw

extends CharacterBody2D
class_name player

@onready var Animation_player = $AnimatedSprite2D
@export var gravity = 400
@export var speed = 125
@export var jump_force = 230
@export var level_time = 5
@onready var timer_node = null
@onready var active = true 
var time_left 

var direction = 0

func _physics_process(delta: float) -> void:
	if is_on_floor() == false :
		velocity.y += gravity * delta
	if active == true :
		direction = Input.get_axis("left", "right")
		
		if direction != 0:
			Animation_player.flip_h = (direction == -1)
			
		velocity.x = speed * direction 
		
		if Input.is_action_just_pressed("jump") and is_on_floor() :
			jump(jump_force)	
			MusicPlayer.sfx_player("jump")
		move_and_slide()		
	if velocity.y > 500:
		velocity.y = 500	
		
	update_animations(direction)

func update_animations(direction):
	if is_on_floor() == true:
		if direction == 0:
			Animation_player.play("idle")
		else:
			Animation_player.play("run")
	else:
		if velocity.y < 0:
			Animation_player.play("jump")
		else:
			Animation_player.play("fall")	
		
func jump(force):
	velocity.y = -force

uid://bw7ngbh62slhh

extends Control

@onready var new_bg = preload("res://assets/textures/additional_pics/start menu.png")
@onready var bg = $BG
@onready var menu_music = $Start_music
@onready var click_sfx = $button_click

func _ready() -> void:
	MusicPlayer.Music_stop()

func _process(delta: float) -> void:
	bg.Sprite.texture = new_bg
	bg.moving == false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level1.tscn") # Replace with function body.
func _on_quit_pressed() -> void:
	click_sfx.play()
	get_tree().quit() # Replace with function body.
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")
	
func _on_options_mouse_entered() -> void:
	click_sfx.play() 


func _on_quit_mouse_entered() -> void:
	click_sfx.play()  # Replace with function body.


func _on_start_mouse_entered() -> void:
	click_sfx.play()  # Replace with function body.

uid://dxf312jhr3jpl

extends StaticBody2D

@onready var Spawn_position = $Spawn_position

func get_spawn_pos():
	return Spawn_position.global_position

uid://bi0sl6ocjv7rs

extends Node2D

signal touched_player

func _on_spike_ball_body_entered(body: Node2D) -> void:
	if body is player:
		touched_player.emit() 


func _on_saw_body_entered(body: Node2D) -> void:
	if body is player:
		touched_player.emit() 

uid://4vjrcy85aobb

extends CanvasLayer

func _ready() -> void: 
	show_win_screen(false)
	
func show_win_screen(flag: bool):
	$Win_screen.visible = flag  

uid://cc6yfdmatuf7f

extends Control

@export var bg = preload("res://assets/textures/additional_pics/second_level.png")
@onready var par_bg = $ParallaxBackground/ParallaxLayer/Sprite2D
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn") # Replace with function body.
func _ready():
	par_bg.texture = bg


func _on_button_mouse_entered() -> void:
	$click.play() # Replace with function body.

uid://bdc4fyk7wcij3

extends Area2D

signal Death

func _on_body_entered(body):
	emit_signal("Death") # Replace with function body.
	

uid://c1mg4wpjuv4uw

extends Area2D



@onready var Animated_sprite = $AnimatedSprite2D 

func animation():
	Animated_sprite.play("default")

uid://chl0gog80nr35

extends Control

func set_time_lebal(value):
	$Time.text = "Time: " + str(value)

uid://bopq4lyylkuuc

extends Area2D

@onready var Animation_jump_pad = $Jump_pad_animation
@export var jump_force = 300

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		Animation_jump_pad.play("jump")
		MusicPlayer.sfx_player("jump")
		body.jump(jump_force)

uid://bq85s01noes2r

extends Node2D
@export var level_time = 60
@export var next_bg: CompressedTexture2D = preload("res://assets/textures/bg/Gray.png")
@export var next_level: PackedScene = null
@export var is_final_level: bool = false



@onready var HUD = $UILayer/HUD
@onready var Death_zone = $DeathZone
@onready var player = $player
@onready var Respawn_position = $StartPoint
@onready var exit = $Exit
@onready var bg = $BG
@onready var death_zone = $DeathZone
@onready var UI = $UILayer


var win = false 
var time_left
var timer_node = null

func _ready():
	player.global_position = Respawn_position.get_spawn_pos()
	var traps = get_tree().get_nodes_in_group("traps")
	MusicPlayer.Music_play()
	for trap in traps:
		trap.connect("touched_player", _on_trap_touched_player)
		
	exit.body_entered.connect(_on_exit_body_entered)
	death_zone.body_entered.connect(_on_death_zone_body_entered)
	bg.Sprite.texture = next_bg
	timer_node = Timer.new()
	timer_node.name = "Timer"
	timer_node.wait_time = 1
	add_child(timer_node)
	timer_node.timeout.connect(_on_level_timer_timeout)
	timer_node.start()
	time_left = level_time
	HUD.set_time_lebal(time_left)
	
func _on_level_timer_timeout():
	if time_left == 4:
		MusicPlayer.timer_play()
	if win != true :
		time_left -= 1
		HUD.set_time_lebal(time_left)
		if time_left == 0:
			player_reset()
			time_left = level_time
		print(time_left)
		
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _on_area_2d_body_entered(body: Node2D) -> void:
	body.global_position = Respawn_position.get_spawn_pos()
	body.velocity = Vector2.ZERO
	MusicPlayer.sfx_player("hurt")

func _on_trap_touched_player() -> void:
	player_reset()
	MusicPlayer.sfx_player("hurt")

func player_reset():
	player.global_position = Respawn_position.get_spawn_pos()
	player.velocity = Vector2.ZERO

func _on_spike_ball_touched_player() -> void:
	player_reset() 
	MusicPlayer.play("hurt")
func _on_exit_body_entered(body):
	if body is player:
		if (next_level != null) or is_final_level:

			exit.animation()
			player.active = false		
			win = true  
			player.Animation_player.play("idle")
			await get_tree().create_timer(1).timeout
	if is_final_level:
			UI.show_win_screen(true)
	else:
		get_tree().change_scene_to_packed(next_level)

func _on_death_zone_body_entered(body):
	player_reset()
	MusicPlayer.sfx_player("hurt")

uid://dybwp5k04ormh

extends Node2D

@onready var next_scene: PackedScene = preload("res://scenes/Level3.tscn")
@onready var BG = $ParallaxBackground/ParallaxLayer/Sprite2D
@onready var new_BG = preload("res://assets/textures/bg/Yellow.png")
@onready var  player = $player
@onready var level_2_sc = preload("res://scenes/level_2.tscn")
@onready var Respawn = $Re_Spawn_pos


func _ready() -> void:
	BG.texture = new_BG
	if player.global_position.y > 1500:
		player.global_position = $Re_Spawn_pos 


func _on_death_zone_death() -> void:
	player_reset() 
	
func player_reset():
	player.global_position = Respawn.global_position




func _on_exit_body_entered(body):
	if body is player:
		$Exit.animation()
		player.active = false
		await get_tree().create_timer(1.5).timeout
		player.Animation_player.play("idle")
		get_tree().change_scene_to_packed(next_scene) # Replace with function body.


func _on_trap_touched_player() -> void:
	player_reset() # Replace with function body.

uid://cit3lu545h1d7


uid://dsamybfrs0as6

extends Node

var hurt = preload("res://assets/audio/hurt.wav")
var jump = preload("res://assets/audio/jump.wav")
@onready var Music = $MusicPlayer_theme
@onready var timer = $timer
@onready var default_music = true

func Music_stop():
	Music.stop()
func Music_play():
	Music.play()
func timer_play():
	timer.play()
func sfx_player(sfx_name: String):
	var stream = null
	if default_music == false:
		MusicPlayer.playing() == false
		
	if sfx_name == "hurt":
		stream = hurt
	elif sfx_name == "jump":
		stream = jump
	else:
		print("Invalid SFX!")
		return
	
	var asp = AudioStreamPlayer.new()
	asp.stream = stream
	asp.name = "sfx_player_node"
	add_child(asp)
	asp.play()
	
	
	await asp.finished
	asp.queue_free()


	

uid://2e8gnt3flms2

extends AudioStreamPlayer2D
