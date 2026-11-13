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
		
			
