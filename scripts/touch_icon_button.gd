@tool
extends TouchScreenButton

## Touch button that draws its icon centered on the node.
##
## TouchScreenButton draws textures from the top-left corner. Drawing the icon
## ourselves keeps the visual, the touch shape and the node position aligned,
## which makes the mobile layout much easier to reason about.

@export var icon: Texture2D:
	set(value):
		icon = value
		queue_redraw()

@export var flip_vertical: bool = false:
	set(value):
		flip_vertical = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if icon == null:
		return

	var icon_offset := -icon.get_size() * 0.5
	if flip_vertical:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, -1.0))
		draw_texture(icon, icon_offset)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture(icon, icon_offset)
