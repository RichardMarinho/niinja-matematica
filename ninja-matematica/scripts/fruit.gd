extends Area2D
class_name GaussFruit

signal sliced(fruit: GaussFruit)

@onready var sprite: Sprite2D = $Sprite
@onready var value_label: Label = $Value
@onready var juice: CPUParticles2D = $Juice

var value: int = 0
var velocity: Vector2 = Vector2.ZERO
@export_range(100.0, 1500.0, 25.0) var fall_gravity: float = 520.0
var is_sliced := false
var fruit_frame := 0


func setup(number: int, frame_index: int, initial_velocity: Vector2) -> void:
	value = number
	velocity = initial_velocity
	self.fruit_frame = frame_index % 4
	if is_node_ready():
		_apply_setup()


func _ready() -> void:
	if get_tree().current_scene == self and not SceneFlow.enter_scene_from_menu():
		return
	if value_label:
		_apply_setup()


func _apply_setup() -> void:
	sprite.frame = fruit_frame % sprite.hframes
	value_label.text = str(value)
	juice.color = [Color(1.0, 0.16, 0.12), Color(1.0, 0.48, 0.08), Color(1.0, 0.83, 0.12), Color(0.47, 0.81, 0.22)][fruit_frame]
	value_label.add_theme_font_size_override("font_size", maxi(18, 32 - maxi(0, str(value).length() - 3) * 3))


func _physics_process(delta: float) -> void:
	if is_sliced:
		return
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	rotation += velocity.x * delta * 0.0007
	if global_position.y > get_viewport_rect().size.y + 100.0:
		queue_free()


func slash_radius() -> float:
	return 48.0 * global_scale.x


func slice() -> void:
	if is_sliced:
		return
	is_sliced = true
	monitoring = false
	monitorable = false
	sliced.emit(self)
	juice.emitting = true
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(value_label, "modulate:a", 0.0, 0.13)
	get_tree().create_timer(0.6).timeout.connect(queue_free)
