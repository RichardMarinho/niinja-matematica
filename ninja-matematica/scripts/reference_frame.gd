@tool
extends Control

@export var design_size := Vector2(1280, 720)


func _ready() -> void:
	resized.connect(_fit_layers)
	_fit_layers()


func _fit_layers() -> void:
	var fit := minf(size.x / design_size.x, size.y / design_size.y)
	for child in get_children():
		if child is Control:
			child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			child.size = design_size
			child.scale = Vector2(fit, fit)
			child.position = (size - design_size * fit) * 0.5
