extends Node2D

const CRACK_TEXTURE: Texture2D = preload("res://assets/chocolate_wall_crack.png")

var _random := RandomNumberGenerator.new()


func play() -> void:
	_random.randomize()
	var fracture := Sprite2D.new()
	fracture.texture = CRACK_TEXTURE
	fracture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fracture.scale = Vector2.ONE * _random.randf_range(0.19, 0.25)
	fracture.flip_h = _random.randf() < 0.5
	fracture.modulate = Color(1.0, 1.0, 1.0, 0.92)
	add_child(fracture)
	rotation = _random.randf_range(0.0, TAU)
	modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.08)
	fade.tween_interval(2.2)
	fade.tween_property(self, "modulate:a", 0.0, 1.15)
	fade.tween_callback(queue_free)
