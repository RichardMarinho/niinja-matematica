extends Control

signal cancelled


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		get_viewport().set_input_as_handled()
