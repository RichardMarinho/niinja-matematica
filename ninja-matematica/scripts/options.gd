extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"

@onready var music_check: CheckButton = $HUD/Root/Center/Card/Content/MusicCheck
@onready var sfx_check: CheckButton = $HUD/Root/Center/Card/Content/SfxCheck
@onready var hints_check: CheckButton = $HUD/Root/Center/Card/Content/HintsCheck
@onready var fullscreen_check: CheckButton = $HUD/Root/Center/Card/Content/FullscreenCheck
@onready var back_button: Button = $HUD/Root/Center/Card/Content/BackButton
@onready var toggle_art: Control = $HUD/Root/ToggleArt
@onready var toggle_tracks: Array[Panel] = [
	$HUD/Root/ToggleArt/MusicTrack,
	$HUD/Root/ToggleArt/SfxTrack,
	$HUD/Root/ToggleArt/HintsTrack,
	$HUD/Root/ToggleArt/FullscreenTrack,
]
@onready var toggle_knobs: Array[Panel] = [
	$HUD/Root/ToggleArt/MusicTrack/MusicKnob,
	$HUD/Root/ToggleArt/SfxTrack/SfxKnob,
	$HUD/Root/ToggleArt/HintsTrack/HintsKnob,
	$HUD/Root/ToggleArt/FullscreenTrack/FullscreenKnob,
]


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
	_sync_toggle_art()


func _music_toggled(enabled: bool) -> void:
	AudioManager.set_music_enabled(enabled)
	_save_option("music", enabled)
	AudioManager.play_ui()


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
	_sync_toggle_art()


func _save_option(option_name: String, enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("options", option_name, enabled)
	config.save(SETTINGS_PATH)
	_sync_toggle_art()


func _sync_toggle_art() -> void:
	if not is_node_ready():
		return
	var states := [music_check.button_pressed, sfx_check.button_pressed, hints_check.button_pressed, fullscreen_check.button_pressed]
	for index in range(states.size()):
		var enabled: bool = states[index]
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#f32678") if enabled else Color("#555255")
		track.set_corner_radius_all(18)
		toggle_tracks[index].add_theme_stylebox_override("panel", track)
		toggle_knobs[index].position.x = 36.0 if enabled else 3.0


func _back_to_menu() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/menu.tscn")
