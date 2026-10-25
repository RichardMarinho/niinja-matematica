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
	_sync_toggle_art()


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
	_sync_toggle_art()


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
