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
