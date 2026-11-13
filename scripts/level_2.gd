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
		SceneTransition.change_scene_to_packed(next_scene)


func _on_trap_touched_player() -> void:
	player_reset() # Replace with function body.
