extends Node

const MENU_SCENE := "res://scenes/menu.tscn"

var _scene_change_authorized := false
var preparation_school_year := 0


func entered_menu() -> void:
	_scene_change_authorized = false
	preparation_school_year = 0


func take_preparation_school_year() -> int:
	var school_year := preparation_school_year
	preparation_school_year = 0
	return school_year


func change_scene(scene_path: String) -> Error:
	_scene_change_authorized = true
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_scene_change_authorized = false
	return error


func enter_scene_from_menu() -> bool:
	if _scene_change_authorized:
		_scene_change_authorized = false
		return true
	get_tree().call_deferred("change_scene_to_file", MENU_SCENE)
	return false
