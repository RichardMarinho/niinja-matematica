extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"

@onready var help_button: Button = $HUD/Root/Center/Card/Content/DifficultyHelpButton
@onready var help_overlay: Control = $HUD/Root/DifficultyHelp
@onready var help_close_button: Button = $HUD/Root/DifficultyHelp/HelpCard/HelpContent/HelpCloseButton
@onready var difficulty_buttons: Control = $HUD/Root/Center/Card/Content/DifficultyButtons
@onready var easy_button: Button = $HUD/Root/Center/Card/Content/DifficultyButtons/EasyButton
@onready var normal_button: Button = $HUD/Root/Center/Card/Content/DifficultyButtons/NormalButton
@onready var hard_button: Button = $HUD/Root/Center/Card/Content/DifficultyButtons/HardButton
@onready var addition_check: CheckButton = $HUD/Root/Center/Card/Content/OperationButtons/AdditionCheck
@onready var subtraction_check: CheckButton = $HUD/Root/Center/Card/Content/OperationButtons/SubtractionCheck
@onready var multiplication_check: CheckButton = $HUD/Root/Center/Card/Content/OperationButtons/MultiplicationCheck
@onready var division_check: CheckButton = $HUD/Root/Center/Card/Content/OperationButtons/DivisionCheck
@onready var status_label: Label = $HUD/Root/Center/Card/Content/Status
@onready var back_button: Button = $HUD/Root/Center/Card/Content/Actions/BackButton
@onready var start_button: Button = $HUD/Root/Center/Card/Content/Actions/StartButton
@onready var start_disabled_overlay: Panel = $HUD/Root/Center/StartDisabledOverlay
@onready var operation_tracks: Array[Panel] = [
	$HUD/Root/Center/OperationToggleArt/AdditionTrack,
	$HUD/Root/Center/OperationToggleArt/SubtractionTrack,
	$HUD/Root/Center/OperationToggleArt/MultiplicationTrack,
	$HUD/Root/Center/OperationToggleArt/DivisionTrack,
]
@onready var operation_knobs: Array[Panel] = [
	$HUD/Root/Center/OperationToggleArt/AdditionTrack/AdditionKnob,
	$HUD/Root/Center/OperationToggleArt/SubtractionTrack/SubtractionKnob,
	$HUD/Root/Center/OperationToggleArt/MultiplicationTrack/MultiplicationKnob,
	$HUD/Root/Center/OperationToggleArt/DivisionTrack/DivisionKnob,
]

var selected_difficulty := ""
var selected_operations: Array[String] = []


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	help_overlay.visible = false
	easy_button.pressed.connect(_select_difficulty.bind("easy"))
	normal_button.pressed.connect(_select_difficulty.bind("normal"))
	hard_button.pressed.connect(_select_difficulty.bind("hard"))
	addition_check.toggled.connect(_operation_toggled.bind("addition"))
	subtraction_check.toggled.connect(_operation_toggled.bind("subtraction"))
	multiplication_check.toggled.connect(_operation_toggled.bind("multiplication"))
	division_check.toggled.connect(_operation_toggled.bind("division"))
	back_button.pressed.connect(_back_to_menu)
	start_button.pressed.connect(_start_game)
	help_button.pressed.connect(_open_difficulty_help)
	help_close_button.pressed.connect(_close_difficulty_help)
	_sync_operation_switch_art()
	_refresh_start_button()


func _open_difficulty_help() -> void:
	help_overlay.visible = true
	AudioManager.play_ui()


func _close_difficulty_help() -> void:
	help_overlay.visible = false
	AudioManager.play_ui()


func _select_difficulty(difficulty: String) -> void:
	selected_difficulty = difficulty
	for child in difficulty_buttons.get_children():
		var button := child as Button
		if button:
			button.button_pressed = _difficulty_id(button.name) == difficulty
			button.modulate = Color(1.0, 0.78, 0.33) if button.button_pressed else Color.WHITE
	AudioManager.play_ui()
	_refresh_start_button()


func _difficulty_id(button_name: String) -> String:
	match button_name:
		"EasyButton": return "easy"
		"NormalButton": return "normal"
		"HardButton": return "hard"
	return ""


func _operation_toggled(checked: bool, operation: String) -> void:
	if checked and not selected_operations.has(operation):
		selected_operations.append(operation)
	elif not checked:
		selected_operations.erase(operation)
	AudioManager.play_ui()
	_sync_operation_switch_art()
	_refresh_start_button()


func _sync_operation_switch_art() -> void:
	var states := [
		addition_check.button_pressed,
		subtraction_check.button_pressed,
		multiplication_check.button_pressed,
		division_check.button_pressed,
	]
	for index in range(states.size()):
		var enabled: bool = states[index]
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#f32678") if enabled else Color("#595455")
		track.set_corner_radius_all(15)
		operation_tracks[index].add_theme_stylebox_override("panel", track)
		operation_knobs[index].position.x = 21.0 if enabled else 3.0


func _refresh_start_button() -> void:
	var can_start := not selected_difficulty.is_empty() and not selected_operations.is_empty()
	start_button.disabled = not can_start
	start_disabled_overlay.visible = start_button.disabled
	if can_start:
		status_label.text = "Pronto! %s · %d operação(ões) selecionada(s)." % [_difficulty_name(selected_difficulty), selected_operations.size()]
	else:
		status_label.text = "Escolha uma dificuldade e pelo menos uma operação."


func _difficulty_name(difficulty: String) -> String:
	match difficulty:
		"easy": return "Fácil"
		"normal": return "Normal"
		"hard": return "Difícil"
	return ""


func _start_game() -> void:
	if start_button.disabled:
		return
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("session", "difficulty", selected_difficulty)
	config.set_value("session", "operations", PackedStringArray(selected_operations))
	config.save(SETTINGS_PATH)
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/game.tscn")


func _back_to_menu() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/menu.tscn")
