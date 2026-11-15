extends Node
## Focus remains available to keyboard/assistive input; only its paint changes.
## SceneTree metadata carries the input mode across menu scene transitions.
const MODE_KEY := &"gauss_menu_keyboard_navigation"

var focus_styles: Dictionary = {}
var hidden_focus := StyleBoxEmpty.new()
var keyboard_navigation := false


func _ready() -> void:
	keyboard_navigation = bool(get_tree().get_meta(MODE_KEY, false))
	for button in get_parent().find_children("*", "BaseButton", true, false):
		focus_styles[button] = button.get_theme_stylebox("focus")
	_apply_focus_visibility()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Layout/scene changes can synthesize a zero-motion event.
		if not event.relative.is_zero_approx():
			_set_keyboard_navigation(false)
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			_set_keyboard_navigation(false)
	elif event is InputEventScreenDrag:
		_set_keyboard_navigation(false)
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_TAB, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_set_keyboard_navigation(true)
	elif event is InputEventJoypadButton and event.pressed:
		_set_keyboard_navigation(true)


func _set_keyboard_navigation(enabled: bool) -> void:
	if keyboard_navigation == enabled:
		return
	keyboard_navigation = enabled
	get_tree().set_meta(MODE_KEY, enabled)
	_apply_focus_visibility()


func _apply_focus_visibility() -> void:
	for button in focus_styles:
		button.add_theme_stylebox_override("focus", focus_styles[button] if keyboard_navigation else hidden_focus)
