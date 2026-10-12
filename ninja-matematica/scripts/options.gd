extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"

@onready var music_check: CheckButton = $HUD/Root/Center/Card/Content/MusicCheck
@onready var sfx_check: CheckButton = $HUD/Root/Center/Card/Content/SfxCheck
@onready var hints_check: CheckButton = $HUD/Root/Center/Card/Content/HintsCheck
@onready var fullscreen_check: CheckButton = $HUD/Root/Center/Card/Content/FullscreenCheck
@onready var back_button: Button = $HUD/Root/Center/Card/Content/BackButton


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	music_check.button_pressed = bool(config.get_value("options", "music", true))
	sfx_check.button_pressed = bool(config.get_value("options", "sfx", true))
	hints_check.button_pressed = bool(config.get_value("options", "hints", true))
	fullscreen_check.button_pressed = bool(config.get_value("options", "fullscreen", false))
	music_check.toggled.connect(_music_toggled)
	sfx_check.toggled.connect(_sfx_toggled)
	hints_check.toggled.connect(_option_toggled.bind("hints"))
	fullscreen_check.toggled.connect(_fullscreen_toggled)
	back_button.pressed.connect(_back_to_menu)
	AudioManager.set_music_enabled(music_check.button_pressed)
	AudioManager.set_sfx_enabled(sfx_check.button_pressed)
	AudioManager.set_fullscreen(fullscreen_check.button_pressed)


func _music_toggled(enabled: bool) -> void:
	AudioManager.set_music_enabled(enabled)
	_save_option("music", enabled)


func _sfx_toggled(enabled: bool) -> void:
	AudioManager.set_sfx_enabled(enabled)
	_save_option("sfx", enabled)
	AudioManager.play_ui()


func _option_toggled(enabled: bool, option_name: String) -> void:
	_save_option(option_name, enabled)
	AudioManager.play_ui()


func _fullscreen_toggled(enabled: bool) -> void:
	AudioManager.set_fullscreen(enabled)
	_save_option("fullscreen", enabled)
	AudioManager.play_ui()


func _save_option(option_name: String, enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("options", option_name, enabled)
	config.save(SETTINGS_PATH)


func _back_to_menu() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/menu.tscn")
