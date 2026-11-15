extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"
const MULTIPLICATION_UNLOCK_YEAR := 3
const SELECTED_ICON := preload("res://assets/ui_check.svg")




@onready var help_button: Button = $HUD/Root/Center/Card/Content/DifficultyHeading/DifficultyHelpButton
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

var selected_difficulty := ""
var selected_operations: Array[String] = []

var active_school_year := 0
var school_year_load_failed := false
var suppress_operation_effects := false
var help_focus_modes: Dictionary = {}


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	active_school_year = SceneFlow.take_preparation_school_year()
	if active_school_year <= 0:
		SceneFlow.call_deferred("change_scene", "res://scenes/menu.tscn")
		return
	$HUD/Root.resized.connect(_layout_reference_frame)
	_layout_reference_frame()
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
	_apply_operation_access()
	easy_button.grab_focus()


func _layout_reference_frame() -> void:
	# Keep opaque controls aligned with the reference art at every window ratio.
	var available: Vector2 = $HUD/Root.size
	var reference := Vector2(1280, 720)
	var fit := minf(available.x / reference.x, available.y / reference.y)
	for frame in [$HUD/Root/Background, $HUD/Root/Center]:
		frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		frame.size = reference
		frame.scale = Vector2(fit, fit)
		frame.position = (available - reference * fit) * 0.5


func _apply_operation_access() -> void:
	suppress_operation_effects = true
	var operations_unlocked := active_school_year >= MULTIPLICATION_UNLOCK_YEAR
	multiplication_check.disabled = not operations_unlocked
	division_check.disabled = not operations_unlocked
	var eligibility_text := "Entre pelo Project Gauss para confirmar sua série." if active_school_year <= 0 else "Multiplicação e divisão: a partir do 3º ano."
	for button in [multiplication_check, division_check]:
		button.tooltip_text = eligibility_text if (school_year_load_failed or active_school_year > 0) and not operations_unlocked else ""
		button.accessibility_description = button.tooltip_text
	if not operations_unlocked:
		multiplication_check.button_pressed = false
		division_check.button_pressed = false
		selected_operations.erase("multiplication")
		selected_operations.erase("division")
	_refresh_start_button()
	suppress_operation_effects = false


func _open_difficulty_help() -> void:
	# Keep keyboard navigation inside the modal, then restore the form.
	for button in $HUD/Root/Center.find_children("*", "BaseButton"):
		help_focus_modes[button] = button.focus_mode
		button.focus_mode = Control.FOCUS_NONE
	help_overlay.visible = true
	help_close_button.grab_focus()
	AudioManager.play_ui()


func _close_difficulty_help() -> void:
	help_overlay.visible = false
	for button in help_focus_modes:
		button.focus_mode = help_focus_modes[button]
	help_focus_modes.clear()
	help_button.grab_focus()
	AudioManager.play_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	if help_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_difficulty_help()
		get_viewport().set_input_as_handled()


func _select_difficulty(difficulty: String) -> void:
	selected_difficulty = difficulty
	for child in difficulty_buttons.get_children():
		var button := child as Button
		if button:
			button.button_pressed = _difficulty_id(button.name) == difficulty
			button.text = _difficulty_name(_difficulty_id(button.name)).to_upper()
			button.icon = SELECTED_ICON if button.button_pressed else null
			button.add_theme_constant_override("icon_max_width", 26)
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
	if not suppress_operation_effects:
		AudioManager.play_ui()
	_refresh_start_button()


func _operation_name(operation: String) -> String:
	match operation:
		"addition": return "adição"
		"subtraction": return "subtração"
		"multiplication": return "multiplicação"
		"division": return "divisão"
	return "operação"


func _operation_button(operation: String) -> CheckButton:
	match operation:
		"addition": return addition_check
		"subtraction": return subtraction_check
		"multiplication": return multiplication_check
		"division": return division_check
	return null


func _refresh_start_button() -> void:
	var can_start := active_school_year > 0 and not selected_difficulty.is_empty() and not selected_operations.is_empty()
	start_button.disabled = not can_start
	if active_school_year <= 0 and school_year_load_failed:
		status_label.text = "Entre pelo Project Gauss para confirmar sua série."
	elif active_school_year <= 0:
		status_label.text = "Confirmando sua série..."
	elif can_start:
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
	if active_school_year < MULTIPLICATION_UNLOCK_YEAR:
		selected_operations.erase("multiplication")
		selected_operations.erase("division")
		if multiplication_check.button_pressed:
			multiplication_check.button_pressed = false
		if division_check.button_pressed:
			division_check.button_pressed = false
		if selected_operations.is_empty():
			status_label.text = "Escolha adição ou subtração para começar."
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
