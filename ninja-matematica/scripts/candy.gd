extends Area2D
class_name GaussCandy

signal smashed(candy: GaussCandy)

@onready var sprite: Sprite2D = $Sprite
@onready var value_label: Label = $Value

const CANDY_FRAME_COUNT := 16

var value: int = 0
var velocity := Vector2.ZERO
@export_range(100.0, 1500.0, 25.0) var fall_gravity := 520.0
var is_smashed := false
var candy_frame := 0
var reduced_motion := false


func setup(number: int, frame_index: int, initial_velocity: Vector2) -> void:
	value = number
	velocity = initial_velocity
	candy_frame = frame_index % CANDY_FRAME_COUNT
	if is_node_ready():
		_apply_setup()


func _ready() -> void:
	if get_tree().current_scene == self and not SceneFlow.enter_scene_from_menu():
		return
	_apply_setup()


func _apply_setup() -> void:
	sprite.frame = candy_frame
	value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", maxi(18, 32 - maxi(0, str(value).length() - 3) * 3))


func _physics_process(delta: float) -> void:
	if is_smashed:
		return
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	if not reduced_motion:
		rotation += velocity.x * delta * 0.0007
	if global_position.y > get_viewport_rect().size.y + 100.0:
		queue_free()


func hit_radius() -> float:
	return 57.0 * global_scale.x


func smash() -> void:
	if is_smashed:
		return
	is_smashed = true
	monitoring = false
	monitorable = false
	smashed.emit(self)
	queue_free()


func fall_away() -> void:
	if is_smashed:
		return
	is_smashed = true
	monitoring = false
	monitorable = false
	var bottom := get_viewport_rect().size.y + 100.0
	var target_y := maxf(position.y + 300.0, bottom)
	var fall := create_tween()
	fall.tween_property(self, "position:y", target_y, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(self, "rotation", rotation + randf_range(-0.55, 0.55), 0.7)
	fall.tween_callback(queue_free)
