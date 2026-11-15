extends Node2D

const SETTINGS_PATH := "user://ninja_matematica.cfg"
const MULTIPLICATION_UNLOCK_YEAR := 3
const SELECTED_ICON := preload("res://assets/ui_check.svg")

@export var api_base_url := "http://127.0.0.1:3001"
@onready var api: HTTPRequest = $API

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
var api_token := ""
var active_school_year := 0
var school_year_load_failed := false
var suppress_operation_speech := false
var preparation_intro_spoken := false
var help_focus_modes: Dictionary = {}


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	$HUD/Root.resized.connect(_layout_reference_frame)
	_layout_reference_frame()
	AudioManager.accessibility_profile_updated.connect(_on_accessibility_profile_updated)
	api.request_completed.connect(_on_school_year_loaded)
	help_overlay.visible = false
	easy_button.pressed.connect(_select_difficulty.bind("easy"))
	easy_button.mouse_entered.connect(_speak_difficulty_hover.bind("easy", easy_button))
	easy_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(easy_button))
	normal_button.pressed.connect(_select_difficulty.bind("normal"))
	normal_button.mouse_entered.connect(_speak_difficulty_hover.bind("normal", normal_button))
	normal_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(normal_button))
	hard_button.pressed.connect(_select_difficulty.bind("hard"))
	hard_button.mouse_entered.connect(_speak_difficulty_hover.bind("hard", hard_button))
	hard_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(hard_button))
	addition_check.toggled.connect(_operation_toggled.bind("addition"))
	addition_check.mouse_entered.connect(_speak_operation_hover.bind("addition", addition_check))
	addition_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(addition_check))
	subtraction_check.toggled.connect(_operation_toggled.bind("subtraction"))
	subtraction_check.mouse_entered.connect(_speak_operation_hover.bind("subtraction", subtraction_check))
	subtraction_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(subtraction_check))
	multiplication_check.toggled.connect(_operation_toggled.bind("multiplication"))
	multiplication_check.mouse_entered.connect(_speak_operation_hover.bind("multiplication", multiplication_check))
	multiplication_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(multiplication_check))
	division_check.toggled.connect(_operation_toggled.bind("division"))
	division_check.mouse_entered.connect(_speak_operation_hover.bind("division", division_check))
	division_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(division_check))
	back_button.pressed.connect(_back_to_menu)
	back_button.mouse_entered.connect(_speak_accessibility_text.bind("Voltar ao menu.", back_button))
	back_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(back_button))
	start_button.pressed.connect(_start_game)
	start_button.mouse_entered.connect(_on_start_hovered.bind(start_button))
	start_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(start_button))
	help_button.pressed.connect(_open_difficulty_help)
	help_button.mouse_entered.connect(_speak_accessibility_text.bind("Ajuda sobre os níveis de dificuldade.", help_button))
	help_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(help_button))
	help_close_button.pressed.connect(_close_difficulty_help)
	help_close_button.mouse_entered.connect(_speak_accessibility_text.bind("Fechar ajuda.", help_close_button))
	help_close_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(help_close_button))
	_apply_operation_access()
	_request_school_year()
	call_deferred("_speak_preparation_intro")
	for button in [easy_button, normal_button, hard_button]:
		button.focus_entered.connect(_speak_difficulty_hover.bind(_difficulty_id(button.name)))
	for operation in ["addition", "subtraction", "multiplication", "division"]:
		_operation_button(operation).focus_entered.connect(_speak_operation_hover.bind(operation))
	back_button.focus_entered.connect(_speak_accessibility_text.bind("Voltar ao menu."))
	start_button.focus_entered.connect(_on_start_hovered)
	help_button.focus_entered.connect(_speak_accessibility_text.bind("Ajuda sobre os níveis de dificuldade."))
	help_close_button.focus_entered.connect(_speak_accessibility_text.bind("Fechar ajuda."))
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


func _on_accessibility_profile_updated() -> void:
	_speak_preparation_intro()


func _speak_preparation_intro() -> void:
	if preparation_intro_spoken or not AudioManager.is_audio_assistance_enabled():
		return
	preparation_intro_spoken = true
	AudioManager.speak_accessibility("Você precisa selecionar uma dificuldade e pelo menos uma operação.", true)


func _speak_accessibility_text(text: String, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover(text, hover_source)
	else:
		AudioManager.speak_accessibility(text)


func _speak_difficulty_hover(difficulty: String, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover("Dificuldade %s." % _difficulty_name(difficulty), hover_source)
	else:
		AudioManager.speak_accessibility("Dificuldade %s." % _difficulty_name(difficulty))


func _speak_operation_hover(operation: String, hover_source: Object = null) -> void:
	var button := _operation_button(operation)
	if button == null or button.disabled:
		return
	if hover_source != null:
		AudioManager.speak_hover(_operation_name(operation) + ".", hover_source)
	else:
		AudioManager.speak_accessibility(_operation_name(operation) + ".")


func _on_start_hovered(hover_source: Object = null) -> void:
	if start_button.disabled:
		if hover_source != null:
			AudioManager.speak_hover("Você precisa selecionar uma dificuldade e pelo menos uma operação.", hover_source)
		else:
			AudioManager.speak_accessibility("Você precisa selecionar uma dificuldade e pelo menos uma operação.")
	else:
		if hover_source != null:
			AudioManager.speak_hover("Começar.", hover_source)
		else:
			AudioManager.speak_accessibility("Começar.")


func _request_school_year() -> void:
	var configured_url := ""
	if OS.has_feature("web"):
		api_token = str(JavaScriptBridge.eval("(function(){try{return window.parent.__GAUSS_STUDENT_TOKEN__ || localStorage.getItem('gauss.student.session') || '';}catch(e){return localStorage.getItem('gauss.student.session') || '';}})()")).strip_edges()
		configured_url = str(JavaScriptBridge.eval("(window.parent && window.parent.__GAUSS_API_URL__) || ''")).strip_edges()
		api.accept_gzip = false
	else:
		api_token = OS.get_environment("GAUSS_API_TOKEN").strip_edges()
		configured_url = OS.get_environment("GAUSS_API_URL").strip_edges()
	if not configured_url.is_empty():
		api_base_url = configured_url.trim_suffix("/")
	if api_token.is_empty():
		school_year_load_failed = true
		_apply_operation_access()
		return
	var headers := ["Authorization: Bearer %s" % api_token, "Accept: application/json"]
	var error := api.request("%s/learning/lessons" % api_base_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		school_year_load_failed = true
		_apply_operation_access()


func _on_school_year_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or not parsed is Dictionary:
		school_year_load_failed = true
		_apply_operation_access()
		return
	var received_year := int(parsed.get("schoolYear", 0))
	if received_year < 1 or received_year > 12:
		school_year_load_failed = true
		_apply_operation_access()
		return
	active_school_year = received_year
	_apply_operation_access()


func _apply_operation_access() -> void:
	suppress_operation_speech = true
	var operations_unlocked := active_school_year >= MULTIPLICATION_UNLOCK_YEAR
	multiplication_check.disabled = not operations_unlocked
	division_check.disabled = not operations_unlocked
	var eligibility_text := "Entre pelo Project Gauss para confirmar sua série." if active_school_year <= 0 else "Multiplicação e divisão: a partir do 3º ano."
	for button in [multiplication_check, division_check]:
		button.tooltip_text = eligibility_text if not operations_unlocked else ""
		button.accessibility_description = button.tooltip_text
	if not operations_unlocked:
		multiplication_check.button_pressed = false
		division_check.button_pressed = false
		selected_operations.erase("multiplication")
		selected_operations.erase("division")
	_refresh_start_button()
	suppress_operation_speech = false


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
	AudioManager.speak_accessibility("Dificuldade %s selecionada." % _difficulty_name(difficulty))
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
	if not suppress_operation_speech:
		AudioManager.play_ui()
		var state := "ativadas" if checked else "desativadas"
		AudioManager.speak_accessibility("As contas de %s foram %s." % [_operation_name(operation), state])
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
