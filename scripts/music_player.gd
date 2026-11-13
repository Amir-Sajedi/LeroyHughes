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


	
