@tool
extends Control
## Top-aligned cover keeps the supplied title visible without stretching the art.
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	var image_size := texture.get_size()
	var factor := maxf(size.x / image_size.x, size.y / image_size.y)
	var drawn_size := image_size * factor
	draw_texture_rect(texture, Rect2(Vector2((size.x - drawn_size.x) * 0.5, 0), drawn_size), false)
