extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"

@onready var music_check: CheckButton = $HUD/Root/OptionsPanel/Content/MusicCheck
@onready var sfx_check: CheckButton = $HUD/Root/OptionsPanel/Content/SfxCheck
@onready var hints_check: CheckButton = $HUD/Root/OptionsPanel/Content/HintsCheck
@onready var fullscreen_check: CheckButton = $HUD/Root/OptionsPanel/Content/FullscreenCheck
@onready var back_button: Button = $HUD/Root/OptionsPanel/Content/BackButton
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
	music_check.mouse_entered.connect(_announce_option_hover.bind("music", music_check))
	music_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(music_check))
	music_check.focus_entered.connect(_announce_option_hover.bind("music"))
	sfx_check.toggled.connect(_sfx_toggled)
	sfx_check.mouse_entered.connect(_announce_option_hover.bind("sfx", sfx_check))
	sfx_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(sfx_check))
	sfx_check.focus_entered.connect(_announce_option_hover.bind("sfx"))
	hints_check.toggled.connect(_option_toggled.bind("hints"))
	hints_check.mouse_entered.connect(_announce_option_hover.bind("hints", hints_check))
	hints_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(hints_check))
	hints_check.focus_entered.connect(_announce_option_hover.bind("hints"))
	fullscreen_check.toggled.connect(_fullscreen_toggled)
	fullscreen_check.mouse_entered.connect(_announce_option_hover.bind("fullscreen", fullscreen_check))
	fullscreen_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(fullscreen_check))
	fullscreen_check.focus_entered.connect(_announce_option_hover.bind("fullscreen"))
	back_button.pressed.connect(_back_to_menu)
	back_button.mouse_entered.connect(_announce_back_hover.bind(back_button))
	back_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(back_button))
	back_button.focus_entered.connect(_announce_back_hover)
	AudioManager.set_music_enabled(music_check.button_pressed)
	AudioManager.set_sfx_enabled(sfx_check.button_pressed)
	AudioManager.set_fullscreen(fullscreen_check.button_pressed)
	music_check.grab_focus()


func _music_toggled(enabled: bool) -> void:
	AudioManager.set_music_enabled(enabled)
	_save_option("music", enabled)
	AudioManager.play_ui()
	AudioManager.speak_option_state("music", enabled)


func _sfx_toggled(enabled: bool) -> void:
	AudioManager.set_sfx_enabled(enabled)
	_save_option("sfx", enabled)
	AudioManager.play_ui()
	AudioManager.speak_option_state("sfx", enabled)


func _option_toggled(enabled: bool, option_name: String) -> void:
	_save_option(option_name, enabled)
	AudioManager.play_ui()
	AudioManager.speak_option_state(option_name, enabled)


func _fullscreen_toggled(enabled: bool) -> void:
	AudioManager.set_fullscreen(enabled)
	_save_option("fullscreen", enabled)
	AudioManager.play_ui()
	AudioManager.speak_option_state("fullscreen", enabled)


func _announce_option_hover(option_name: String, hover_source: Object = null) -> void:
	var enabled := false
	match option_name:
		"music": enabled = music_check.button_pressed
		"sfx": enabled = sfx_check.button_pressed
		"hints": enabled = hints_check.button_pressed
		"fullscreen": enabled = fullscreen_check.button_pressed
	AudioManager.speak_option_state(option_name, enabled, hover_source)


func _announce_back_hover(hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover("Voltar ao menu principal.", hover_source)
	else:
		AudioManager.speak_accessibility("Voltar ao menu principal.")


func _save_option(option_name: String, enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("options", option_name, enabled)
	config.save(SETTINGS_PATH)


func _back_to_menu() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/menu.tscn")
