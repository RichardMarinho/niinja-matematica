extends Node2D

@export var candy_scene: PackedScene
@export_range(5.0, 180.0, 1.0) var round_seconds := 60.0
@export_range(0.5, 5.0, 0.1) var spawn_interval := 1.9
@export_range(24.0, 100.0, 2.0) var hammer_hit_radius := 58.0
@export_range(0.0, 120.0, 5.0) var spawn_point_jitter := 35.0
@export_range(300.0, 1200.0, 25.0) var candy_launch_speed_min := 610.0
@export_range(300.0, 1400.0, 25.0) var candy_launch_speed_max := 710.0
@export_range(0.0, 250.0, 10.0) var candy_horizontal_spread := 90.0
@export var game_id := "ninja-matematica"
@export var api_base_url := "http://127.0.0.1:3001"

const PRACTICE_SETS := {
	"addition": [["add_1_3", "add_1_5"], ["add_over_10", "add_over_15", "add_over_20", "add_missing"], ["add_2_digits"], ["add_hard"]],
	"subtraction": [["sub_0_5", "sub_0_10", "sub_0_20_easy"], ["sub_0_20", "sub_missing"], ["sub_0_100"], ["sub_hard"]],
	"multiplication": [["mul_missing_2_3", "mul_2", "mul_3", "mul_4", "mul_5", "mul_0_7"], ["mul_missing_4_5", "mul_6", "mul_7", "mul_8", "mul_9", "mul_10"], ["mul_11_12"], ["mul_hard"]],
	"division": [["div_missing_1_10", "div_1_5", "div_1_10", "div_2", "div_3", "div_4", "div_5"], ["div_6", "div_7", "div_8", "div_9", "div_10"], ["div_11_12"], ["div_hard"]],
}
const OP_SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}
const MULTIPLICATION_UNLOCK_YEAR := 3
const ROUND_TIME := 60.0
const CANDIES_PER_WAVE := 4
const DIFFICULTIES := {
	"easy": {"title": "FÁCIL", "seconds": 75.0, "penalty": 1.0, "spawn": 3.3, "speed_min": 500.0, "speed_max": 590.0, "gravity_scale": 0.68, "tier": 0},
	"normal": {"title": "NORMAL", "seconds": 60.0, "penalty": 3.0, "spawn": 3.0, "speed_min": 610.0, "speed_max": 710.0, "gravity_scale": 1.0, "tier": 1, "max_tier": 3},
	"hard": {"title": "DIFÍCIL", "seconds": 45.0, "penalty": 5.0, "spawn": 1.9, "speed_min": 740.0, "speed_max": 860.0, "gravity_scale": 1.47, "tier": 2, "max_tier": 2},
}

@onready var candy_layer: Node2D = $CandyLayer
@onready var crack_layer: Node2D = $CrackLayer
@onready var candy_spawn_points: Node2D = $CandySpawnPoints
@onready var api: HTTPRequest = $API
@onready var equation_card: Panel = $HUD/Root/EquationCard
@onready var score_label: Label = $HUD/Root/TopBar/ScoreCard/Score
@onready var timer_label: Label = $HUD/Root/TopBar/TimerCard/Timer
@onready var equation_label: Label = $HUD/Root/EquationCard/Equation
@onready var equation_ornaments: TextureRect = $HUD/Root/EquationCard/EquationOrnaments
@onready var answer_feedback_label: Label = $HUD/Root/AnswerFeedback
@onready var hint_label: Label = $HUD/Root/Hint
@onready var static_answer_panel: Panel = $HUD/Root/StaticAnswerPanel
@onready var static_answer_prompt: Label = $HUD/Root/StaticAnswerPanel/Prompt
@onready var static_answer_buttons: Array[Button] = [
	$HUD/Root/StaticAnswerPanel/Answer1,
	$HUD/Root/StaticAnswerPanel/Answer2,
	$HUD/Root/StaticAnswerPanel/Answer3,
	$HUD/Root/StaticAnswerPanel/Answer4,
]
@onready var record_label: Label = $HUD/Root/TopBar/RecordCard/Record
@onready var feedback_flash: ColorRect = $HUD/Root/FeedbackFlash
@onready var pause_button: Button = $HUD/Root/TopBar/PauseButton
@onready var pause_overlay: Control = $HUD/Root/PauseOverlay
@onready var pause_art: TextureRect = $HUD/Root/PauseOverlay/Center/PauseArt
@onready var pause_options_art: TextureRect = $HUD/Root/PauseOverlay/Center/PauseOptionsArt
@onready var pause_menu: Control = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseMenu
@onready var pause_options: Control = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions
@onready var resume_button: Button = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseMenu/ResumeButton
@onready var pause_options_button: Button = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseMenu/OptionsButton
@onready var pause_exit_button: Button = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseMenu/ExitButton
@onready var pause_options_back_button: Button = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/BackButton
@onready var music_check: CheckButton = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/MusicCheck
@onready var sfx_check: CheckButton = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/SfxCheck
@onready var hints_check: CheckButton = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/HintsCheck
@onready var fullscreen_check: CheckButton = $HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/FullscreenCheck
@onready var pause_toggle_tracks: Array[Panel] = [
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/MusicTrack,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/SfxTrack,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/HintsTrack,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/FullscreenTrack,
]
@onready var pause_toggle_knobs: Array[Panel] = [
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/MusicTrack/MusicKnob,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/SfxTrack/SfxKnob,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/HintsTrack/HintsKnob,
	$HUD/Root/PauseOverlay/Center/PauseCard/Content/PauseOptions/FullscreenTrack/FullscreenKnob,
]
@onready var game_over_overlay: Control = $HUD/Root/GameOverOverlay
@onready var game_over_score: Label = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/ScoreValue
@onready var game_over_correct: Label = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/CorrectValue
@onready var game_over_attempts: Label = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/AttemptsValue
@onready var background: Sprite2D = $Background
@onready var focus_background: ColorRect = $HUD/Root/FocusBackground
@onready var retry_button: Button = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/RetryButton
@onready var game_over_exit_button: Button = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/ExitButton

var selected_operation := "multiplication"
var selected_operations: Array[String] = []
var selected_difficulty := "normal"
var difficulty: Dictionary = DIFFICULTIES["normal"]
var active_school_year := 0
var settings := {"show_hints": true, "fullscreen": false, "music": true, "sfx": true}
var score := 0
var record := 0
var remaining_time := ROUND_TIME
var elapsed_seconds := 0.0
var spawn_clock := 0.0
var combo := 0
var game_running := false
var request_pending := false
var api_request_kind := ""
var static_answer_mode_active := false
var pointer_down := false
var previous_pointer := Vector2.ZERO
var active_question: Dictionary = {}
var active_answer_choices: Array[int] = []
var next_question_voice_prefix := ""
var active_practice_set_candidates: Array[String] = []
var attempted_practice_sets: Array[String] = []
var local_mode := true
var api_token := ""
var attempts := 0
var correct_attempts := 0
var consecutive_wrong_answers := 0
var pending_attempt: Dictionary = {}
var retry_clock := 0.0
var feedback_tween: Tween
var accessibility_profile := {
	"textScale": 1.0, "contrast": "standard", "reducedMotion": false,
	"focusMode": false, "pace": "normal", "soundEffects": "on",
	"audioAssistance": false, "captions": true, "preferredInput": "auto",
	"accessibleActivity": "auto",
}
var accessibility_callback_ref: JavaScriptObject
var waiting_for_accessibility_profile := false
var accessibility_profile_received := false


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	if OS.has_feature("web"):
		waiting_for_accessibility_profile = _install_accessibility_bridge()
		if waiting_for_accessibility_profile:
			AudioManager.set_accessibility_sound_effects(false)
	_apply_gameplay_number_font()
	api.request_completed.connect(_on_api_request_completed)
	equation_card.gui_input.connect(_on_equation_card_gui_input)
	equation_card.mouse_entered.connect(_announce_equation_repeat_hint)
	equation_card.mouse_exited.connect(AudioManager.stop_hover_speech.bind(equation_card))
	equation_card.focus_mode = Control.FOCUS_ALL
	equation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(static_answer_buttons.size()):
		static_answer_buttons[index].mouse_entered.connect(_announce_static_answer_hover.bind(index))
		static_answer_buttons[index].mouse_exited.connect(AudioManager.stop_hover_speech.bind(static_answer_buttons[index]))
		static_answer_buttons[index].focus_entered.connect(_announce_static_answer_focus.bind(index))
	for index in range(static_answer_buttons.size()):
		static_answer_buttons[index].pressed.connect(_on_static_answer_pressed.bind(index))
	pause_button.pressed.connect(_open_pause)
	pause_button.mouse_entered.connect(_speak_game_button.bind("Botão para pausar o jogo.", pause_button))
	pause_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(pause_button))
	pause_button.focus_entered.connect(_speak_game_button.bind("Botão para pausar o jogo."))
	resume_button.pressed.connect(_resume_game)
	resume_button.mouse_entered.connect(_speak_game_button.bind("Continuar.", resume_button))
	resume_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(resume_button))
	resume_button.focus_entered.connect(_speak_game_button.bind("Continuar."))
	pause_options_button.pressed.connect(_show_pause_options)
	pause_options_button.mouse_entered.connect(_speak_game_button.bind("Opções.", pause_options_button))
	pause_options_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(pause_options_button))
	pause_options_button.focus_entered.connect(_speak_game_button.bind("Opções."))
	pause_exit_button.pressed.connect(_exit_to_menu)
	pause_exit_button.mouse_entered.connect(_speak_game_button.bind("Sair para o menu.", pause_exit_button))
	pause_exit_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(pause_exit_button))
	pause_exit_button.focus_entered.connect(_speak_game_button.bind("Sair para o menu."))
	pause_options_back_button.pressed.connect(_show_pause_menu)
	retry_button.pressed.connect(_retry_round)
	retry_button.mouse_entered.connect(_speak_game_button.bind("Tentar novamente.", retry_button))
	retry_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(retry_button))
	retry_button.focus_entered.connect(_speak_game_button.bind("Tentar novamente."))
	game_over_exit_button.pressed.connect(_exit_to_menu)
	game_over_exit_button.mouse_entered.connect(_speak_game_button.bind("Sair para o menu.", game_over_exit_button))
	game_over_exit_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(game_over_exit_button))
	game_over_exit_button.focus_entered.connect(_speak_game_button.bind("Sair para o menu."))
	var configured_url := ""
	if OS.has_feature("web"):
		# In the site iframe, reuse the student's existing session without putting
		# the token in the game URL or asking the student to sign in again.
		api_token = str(JavaScriptBridge.eval("(function(){try{return window.parent.__GAUSS_STUDENT_TOKEN__ || localStorage.getItem('gauss.student.session') || '';}catch(e){return localStorage.getItem('gauss.student.session') || '';}})()")).strip_edges()
		configured_url = str(JavaScriptBridge.eval("(window.parent && window.parent.__GAUSS_API_URL__) || ''")).strip_edges()
	else:
		api_token = OS.get_environment("GAUSS_API_TOKEN").strip_edges()
		configured_url = OS.get_environment("GAUSS_API_URL").strip_edges()
	local_mode = api_token.is_empty()
	# O navegador já entrega a resposta HTTP descompactada ao export Web.
	if OS.has_feature("web"):
		api.accept_gzip = false
	if not configured_url.is_empty():
		api_base_url = configured_url.trim_suffix("/")
	var config := ConfigFile.new()
	if config.load("user://ninja_matematica.cfg") == OK:
		record = int(config.get_value("game", "record", 0))
		settings["show_hints"] = bool(config.get_value("options", "hints", true))
		settings["fullscreen"] = bool(config.get_value("options", "fullscreen", false))
		settings["music"] = bool(config.get_value("options", "music", true))
		settings["sfx"] = bool(config.get_value("options", "sfx", true))
		var difficulty_id := str(config.get_value("session", "difficulty", "normal"))
		if DIFFICULTIES.has(difficulty_id):
			selected_difficulty = difficulty_id
			difficulty = DIFFICULTIES[difficulty_id]
		var saved_operations: Variant = config.get_value("session", "operations", PackedStringArray(["multiplication"]))
		for operation in saved_operations:
			if PRACTICE_SETS.has(str(operation)):
				selected_operations.append(str(operation))
		if not selected_operations.is_empty():
			selected_operation = selected_operations.pick_random()
	if selected_operations.is_empty():
		selected_operations = ["multiplication"]
		selected_operation = "multiplication"
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	music_check.button_pressed = bool(settings.music)
	sfx_check.button_pressed = bool(settings.sfx)
	hints_check.button_pressed = bool(settings.show_hints)
	fullscreen_check.button_pressed = bool(settings.fullscreen)
	_sync_pause_toggle_art()
	music_check.toggled.connect(_pause_option_toggled.bind("music"))
	music_check.mouse_entered.connect(_announce_pause_option_hover.bind("music", music_check))
	music_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(music_check))
	music_check.focus_entered.connect(_announce_pause_option_hover.bind("music"))
	sfx_check.toggled.connect(_pause_option_toggled.bind("sfx"))
	sfx_check.mouse_entered.connect(_announce_pause_option_hover.bind("sfx", sfx_check))
	sfx_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(sfx_check))
	sfx_check.focus_entered.connect(_announce_pause_option_hover.bind("sfx"))
	hints_check.toggled.connect(_pause_option_toggled.bind("hints"))
	hints_check.mouse_entered.connect(_announce_pause_option_hover.bind("hints", hints_check))
	hints_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(hints_check))
	hints_check.focus_entered.connect(_announce_pause_option_hover.bind("hints"))
	fullscreen_check.toggled.connect(_pause_option_toggled.bind("fullscreen"))
	fullscreen_check.mouse_entered.connect(_announce_pause_option_hover.bind("fullscreen", fullscreen_check))
	fullscreen_check.mouse_exited.connect(AudioManager.stop_hover_speech.bind(fullscreen_check))
	fullscreen_check.focus_entered.connect(_announce_pause_option_hover.bind("fullscreen"))
	pause_options_back_button.mouse_entered.connect(_announce_pause_options_back_hover.bind(pause_options_back_button))
	pause_options_back_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(pause_options_back_button))
	pause_options_back_button.focus_entered.connect(_announce_pause_options_back_hover)
	pause_overlay.visible = false
	pause_menu.visible = true
	pause_options.visible = false
	pause_art.visible = true
	pause_options_art.visible = false
	game_over_overlay.visible = false
	static_answer_panel.visible = false
	round_seconds = float(difficulty.seconds)
	spawn_interval = float(difficulty.spawn)
	candy_launch_speed_min = float(difficulty.speed_min)
	candy_launch_speed_max = float(difficulty.speed_max)
	hint_label.visible = bool(settings.show_hints)
	_update_score()
	_update_record()
	if local_mode:
		equation_label.text = "Entre pelo Project Gauss para jogar."
		hint_label.text = "Sem sessão autenticada, as respostas não podem ser corrigidas nem registradas no seu progresso."
		return
	if local_mode:
		hint_label.text = "Modo offline: contas dos mesmos conjuntos de pratica da API."
	if waiting_for_accessibility_profile:
		equation_label.text = "Carregando ajustes de acessibilidade..."
	else:
		start_round()


func _install_accessibility_bridge() -> bool:
	var window := JavaScriptBridge.get_interface("window")
	accessibility_callback_ref = JavaScriptBridge.create_callback(_on_accessibility_profile_message)
	window.__gaussNinjaAccessibilityCallback = accessibility_callback_ref
	JavaScriptBridge.eval("""
		(function() {
			if (!window.__gaussNinjaAccessibilityListener) {
				window.__gaussNinjaAccessibilityListener = function(event) {
					if (event.origin !== window.location.origin || event.source !== window.parent) return;
					if (!event.data || event.data.type !== 'gauss-accessibility-profile') return;
					if (typeof window.__gaussNinjaAccessibilityCallback === 'function')
						window.__gaussNinjaAccessibilityCallback(JSON.stringify(event.data));
				};
				window.addEventListener('message', window.__gaussNinjaAccessibilityListener);
			}
			if (window.parent !== window)
				window.parent.postMessage({type: 'gauss-accessibility-ready'}, window.location.origin);
		})()
	""")
	return bool(JavaScriptBridge.eval("window.parent !== window"))


func _on_accessibility_profile_message(args: Array) -> void:
	if args.is_empty() or not args[0] is String:
		return
	var envelope: Variant = JSON.parse_string(str(args[0]))
	if not envelope is Dictionary or int(envelope.get("version", 0)) != 1 or not envelope.get("profile") is Dictionary:
		return
	var profile: Dictionary = envelope.profile
	if int(profile.get("version", 0)) != 1:
		return
	if not [1.0, 1.25, 1.5, 2.0].has(float(profile.get("textScale", -1.0))):
		return
	if not ["standard", "high"].has(profile.get("contrast")):
		return
	if not ["normal", "extended", "untimed"].has(profile.get("pace")):
		return
	if not ["on", "off"].has(profile.get("soundEffects")):
		return
	if not ["auto", "keyboard", "touch"].has(profile.get("preferredInput")):
		return
	if not ["auto", "game", "react"].has(profile.get("accessibleActivity")):
		return
	for field in ["reducedMotion", "focusMode", "audioAssistance", "captions"]:
		if typeof(profile.get(field)) != TYPE_BOOL:
			return
	accessibility_profile = profile.duplicate(true)
	AudioManager.set_accessibility_profile(accessibility_profile)
	accessibility_profile_received = true
	_apply_accessibility_profile()
	if accessibility_profile.accessibleActivity == "react":
		waiting_for_accessibility_profile = false
		game_running = false
		equation_label.text = "Este perfil pede a atividade React acessivel."
		hint_label.text = "O host ainda nao oferece a alternativa React do MathNinja; volte ao menu para escolher outra atividade."
		return
	if waiting_for_accessibility_profile and not game_running:
		waiting_for_accessibility_profile = false
		start_round()


func _apply_accessibility_profile() -> void:
	AudioManager.set_accessibility_sound_effects(accessibility_profile.soundEffects == "on")
	AudioManager.set_sfx_enabled(bool(settings.sfx))
	background.visible = not accessibility_profile.focusMode
	focus_background.visible = accessibility_profile.focusMode
	equation_ornaments.visible = not accessibility_profile.focusMode
	if not accessibility_profile.audioAssistance:
		_stop_current_reading()
	if accessibility_profile.reducedMotion or accessibility_profile.focusMode:
		if feedback_tween != null and feedback_tween.is_running():
			feedback_tween.kill()
		var material := feedback_flash.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("strength", 0.0)
	_apply_accessibility_text_scale($HUD/Root, float(accessibility_profile.textScale))
	if accessibility_profile.contrast == "high":
		_set_label_contrast($HUD/Root)
	else:
		_clear_label_contrast($HUD/Root)
	round_seconds = 160.0 if accessibility_profile.pace == "extended" else float(difficulty.seconds)
	if not game_running:
		remaining_time = round_seconds
	var use_static_answers := bool(accessibility_profile.reducedMotion)
	if use_static_answers != static_answer_mode_active:
		static_answer_mode_active = use_static_answers
		static_answer_panel.visible = false
		candy_layer.visible = not use_static_answers
		if use_static_answers:
			for child in candy_layer.get_children():
				child.queue_free()
		if game_running and not active_question.is_empty():
			if use_static_answers:
				_spawn_static_answers()
			else:
				spawn_clock = 0.0
	timer_label.visible = true
	if accessibility_profile.reducedMotion:
		var static_hint := "Toque ou clique no número certo."
		if accessibility_profile.pace == "untimed":
			static_hint = "Sem pressa! Toque ou clique no número certo."
		hint_label.text = static_hint
	elif accessibility_profile.pace == "untimed":
		hint_label.text = "Sem pressa! Toque ou clique no doce com a resposta."
	if not active_question.is_empty():
		_update_answer_instructions()
		if accessibility_profile.audioAssistance:
			_read_current_question()


func _apply_accessibility_text_scale(node: Node, scale: float) -> void:
	if node is Control:
		var control := node as Control
		if control.has_theme_font_size("font_size"):
			if not control.has_meta("gauss_base_font_size"):
				control.set_meta("gauss_base_font_size", control.get_theme_font_size("font_size"))
			var base_size := int(control.get_meta("gauss_base_font_size"))
			control.add_theme_font_size_override("font_size", maxi(12, roundi(float(base_size) * scale)))
	for child in node.get_children():
		_apply_accessibility_text_scale(child, scale)


func _set_label_contrast(node: Node) -> void:
	if node is BaseButton and _is_pause_art_button(node):
		_set_pause_art_button_text_transparent(node as BaseButton)
	elif node is Label or node is BaseButton:
		(node as Control).add_theme_color_override("font_color", Color.BLACK)
		(node as Control).add_theme_color_override("font_shadow_color", Color.WHITE)
	for child in node.get_children():
		_set_label_contrast(child)


func _clear_label_contrast(node: Node) -> void:
	if node is BaseButton and _is_pause_art_button(node):
		_set_pause_art_button_text_transparent(node as BaseButton)
	elif node is Label or node is BaseButton:
		(node as Control).remove_theme_color_override("font_color")
		(node as Control).remove_theme_color_override("font_shadow_color")
	for child in node.get_children():
		_clear_label_contrast(child)


func _is_pause_art_button(node: Node) -> bool:
	return node == resume_button or node == pause_options_button or node == pause_exit_button or node == pause_options_back_button


func _set_pause_art_button_text_transparent(button: BaseButton) -> void:
	button.remove_theme_color_override("font_shadow_color")
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color(1.0, 1.0, 1.0, 0.0))

func start_round() -> void:
	if local_mode:
		return
	if not pending_attempt.is_empty():
		return
	if request_pending:
		api.cancel_request()
		request_pending = false
	get_tree().paused = false
	pause_overlay.visible = false
	game_over_overlay.visible = false
	pause_button.visible = true
	for candy in candy_layer.get_children():
		candy.queue_free()
	score = 0
	combo = 0
	remaining_time = round_seconds
	elapsed_seconds = 0.0
	spawn_clock = 0.0
	retry_clock = 0.0
	attempts = 0
	correct_attempts = 0
	consecutive_wrong_answers = 0
	game_running = true
	request_pending = false
	api_request_kind = ""
	active_school_year = 0
	active_question.clear()
	active_answer_choices.clear()
	next_question_voice_prefix = ""
	_update_score()
	_update_timer()
	_request_next_question()


func _apply_gameplay_number_font() -> void:
	var gameplay_number_font: Font = ThemeDB.fallback_font
	for value_label in [game_over_score, game_over_correct, game_over_attempts]:
		value_label.add_theme_font_override("font", gameplay_number_font)


func _process(delta: float) -> void:
	if game_running:
		elapsed_seconds += delta
		if accessibility_profile.pace != "untimed":
			remaining_time = maxf(0.0, remaining_time - delta)
		spawn_clock -= delta
		if spawn_clock <= 0.0 and not request_pending and pending_attempt.is_empty() and not active_question.is_empty():
			_spawn_wave()
			var speed_factor := 1.0 + (float(score) / 100.0) * 0.06
			spawn_clock = maxf(0.52, spawn_interval / speed_factor)
		if active_question.is_empty() and not request_pending and pending_attempt.is_empty():
			retry_clock -= delta
			if retry_clock <= 0.0:
				_request_next_question()
		_update_timer()
		if accessibility_profile.pace != "untimed" and remaining_time <= 0.0:
			_end_round()
	if not pending_attempt.is_empty() and not request_pending:
		retry_clock -= delta
		if retry_clock <= 0.0:
			_send_pending_attempt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and accessibility_profile.audioAssistance:
			_read_current_question()
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_smash_answer_index(event.keycode - KEY_1)
			return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not game_running:
		SceneFlow.change_scene("res://scenes/menu.tscn")
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		if pointer_down:
			previous_pointer = get_global_mouse_position()
			_handle_hammer_swing(previous_pointer)
	elif event is InputEventMouseMotion and pointer_down:
		_handle_hammer_swing(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		pointer_down = event.pressed
		if pointer_down:
			previous_pointer = event.position
			_handle_hammer_swing(previous_pointer)
	elif event is InputEventScreenDrag and pointer_down:
		_handle_hammer_swing(event.position)


func _handle_hammer_swing(pointer_position: Vector2) -> void:
	if not game_running or request_pending:
		previous_pointer = pointer_position
		return
	for node in candy_layer.get_children():
		var candy := node as GaussCandy
		if candy and not candy.is_smashed and _distance_to_segment(candy.global_position, previous_pointer, pointer_position) <= minf(hammer_hit_radius, candy.hit_radius()):
			candy.smash()
			AudioManager.play_smash()
			break
	previous_pointer = pointer_position


func _spawn_background_crack(hit_position: Vector2) -> void:
	var crack := Node2D.new()
	crack.set_script(preload("res://scripts/background_crack.gd"))
	crack.position = hit_position
	crack_layer.add_child(crack)
	crack.play()


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	if segment.length_squared() < 0.001:
		return point.distance_to(start)
	var projection := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * projection)


func _spawn_wave() -> void:
	if active_question.is_empty():
		return
	if accessibility_profile.reducedMotion:
		_spawn_static_answers()
		return
	if active_answer_choices.is_empty():
		active_answer_choices = _make_choices(_question_target(active_question))
	var points := candy_spawn_points.get_children()
	for index in range(active_answer_choices.size()):
		var spawn_point := points[index % points.size()] as Marker2D
		var launch := Vector2(randf_range(-candy_horizontal_spread, candy_horizontal_spread), -randf_range(candy_launch_speed_min, candy_launch_speed_max))
		var candy := candy_scene.instantiate() as GaussCandy
		candy.setup(active_answer_choices[index], 0 if accessibility_profile.reducedMotion else randi_range(0, 15), launch)
		candy.reduced_motion = bool(accessibility_profile.reducedMotion)
		candy.fall_gravity *= float(difficulty.get("gravity_scale", 1.0))
		candy.position = spawn_point.position + Vector2(randf_range(-spawn_point_jitter, spawn_point_jitter), randf_range(50.0, 100.0))
		candy.scale = Vector2.ONE * randf_range(0.91, 1.05)
		candy.smashed.connect(_on_candy_smashed)
		candy.mouse_entered.connect(_announce_answer_value.bind(active_answer_choices[index], candy))
		candy.mouse_exited.connect(AudioManager.stop_hover_speech.bind(candy))
		candy_layer.add_child(candy)


func _smash_answer_index(index: int) -> void:
	if not game_running or request_pending:
		return
	if accessibility_profile.reducedMotion:
		_on_static_answer_pressed(index)
		return
	var candies := candy_layer.get_children()
	if index < 0 or index >= candies.size():
		return
	var candy := candies[index] as GaussCandy
	if candy and not candy.is_smashed:
		candy.smash()


func _spawn_static_answers() -> void:
	if active_question.is_empty() or not accessibility_profile.reducedMotion or static_answer_panel.visible:
		return
	for child in candy_layer.get_children():
		child.queue_free()
	if active_answer_choices.is_empty():
		active_answer_choices = _make_choices(_question_target(active_question))
	for index in range(static_answer_buttons.size()):
		var answer_button := static_answer_buttons[index]
		answer_button.text = str(active_answer_choices[index])
		answer_button.set_meta("answer_value", active_answer_choices[index])
		answer_button.disabled = false
	static_answer_prompt.text = "Toque ou clique em uma resposta"
	static_answer_panel.visible = true
	spawn_clock = 3600.0


func _on_static_answer_pressed(index: int) -> void:
	if not accessibility_profile.reducedMotion or not static_answer_panel.visible:
		return
	if index < 0 or index >= static_answer_buttons.size():
		return
	var answer_button := static_answer_buttons[index]
	if answer_button.disabled:
		return
	_submit_answer(int(answer_button.get_meta("answer_value", 0)), Vector2.ZERO)


func _read_current_question(prefix := "") -> void:
	if not accessibility_profile.audioAssistance or active_question.is_empty():
		return
	var spoken_question := _build_question_speech_text(prefix if not prefix.is_empty() else next_question_voice_prefix)
	next_question_voice_prefix = ""
	AudioManager.speak_accessibility(spoken_question, true)


func _stop_current_reading() -> void:
	AudioManager.stop_accessibility_speech()


func _build_question_speech_text(prefix := "") -> String:
	var pieces := PackedStringArray()
	if not prefix.strip_edges().is_empty():
		pieces.append(prefix.strip_edges())
	pieces.append("Conta: %s." % _equation_for_speech())
	if not active_answer_choices.is_empty():
		var choices := PackedStringArray()
		for answer in active_answer_choices:
			choices.append(str(answer))
		pieces.append("Opções: %s." % ", ".join(choices))
	return " ".join(pieces)


func _on_equation_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		equation_card.accept_event()
		_read_current_question()
	elif event is InputEventScreenTouch and event.pressed:
		equation_card.accept_event()
		_read_current_question()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		equation_card.accept_event()
		_read_current_question()


func _announce_equation_repeat_hint() -> void:
	if active_question.is_empty():
		return
	AudioManager.speak_hover("Aperte mais uma vez para repetir a conta.", equation_card)


func _announce_static_answer_hover(index: int) -> void:
	if index >= 0 and index < static_answer_buttons.size():
		_announce_answer_value(int(static_answer_buttons[index].get_meta("answer_value", 0)), static_answer_buttons[index])


func _announce_static_answer_focus(index: int) -> void:
	if index >= 0 and index < static_answer_buttons.size():
		_announce_answer_value(int(static_answer_buttons[index].get_meta("answer_value", 0)))


func _announce_answer_value(value: int, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover("Opção, %d, clique para confirmar." % value, hover_source)
	else:
		AudioManager.speak_accessibility("Opção, %d, clique para confirmar." % value)


func _speak_game_button(text: String, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover(text, hover_source)
	else:
		AudioManager.speak_accessibility(text)


func _equation_for_speech() -> String:
	var operation: Dictionary = active_question.get("operation", {})
	var operands: Array = operation.get("operands", [])
	if operands.is_empty():
		return equation_label.text
	var operators: Array = operation.get("operators", [])
	if operators.is_empty():
		for _index in range(operands.size() - 1):
			operators.append(operation.get("kind", selected_operation))
	var spoken_operators := {"addition": "mais", "subtraction": "menos", "multiplication": "vezes", "division": "dividido por"}
	var missing_index := int(operation.get("missingIndex", -1))
	var parts := PackedStringArray()
	for index in range(operands.size()):
		if index == missing_index:
			parts.append("qual número")
		else:
			parts.append(_speech_number(operands[index]))
		if index < operators.size():
			parts.append(str(spoken_operators.get(str(operators[index]), "")))
	if missing_index >= 0:
		return "%s é igual a %s." % [" ".join(parts), _speech_number(operation.get("result", ""))]
	return "%s igual a qual número?" % " ".join(parts)


func _speech_number(value: Variant) -> String:
	if value is float and is_equal_approx(float(value), roundf(float(value))):
		return str(roundi(float(value)))
	return str(value)


func _make_choices(answer: int) -> Array[int]:
	var values: Array[int] = [answer]
	var offset := 1
	while values.size() < CANDIES_PER_WAVE:
		var candidate := answer + (offset if randf() < 0.5 else -offset)
		if candidate >= 0 and not values.has(candidate):
			values.append(candidate)
		offset += randi_range(1, 3)
	values.shuffle()
	return values


func _request_next_question() -> void:
	_stop_current_reading()
	active_question.clear()
	active_answer_choices.clear()
	static_answer_panel.visible = false
	for child in candy_layer.get_children():
		child.queue_free()
	if not selected_operations.is_empty():
		selected_operation = selected_operations.pick_random()
	if local_mode:
		game_running = false
		equation_label.text = "Entre pelo Project Gauss para jogar."
		hint_label.text = "A sessao autenticada e necessaria para buscar questoes e registrar seu progresso."
		return
	if active_school_year <= 0:
		request_pending = true
		api_request_kind = "school_year"
		var headers := ["Authorization: Bearer %s" % api_token, "Accept: application/json"]
		var year_error := api.request("%s/learning/lessons" % api_base_url, headers, HTTPClient.METHOD_GET)
		if year_error != OK:
			api_request_kind = ""
			request_pending = false
			retry_clock = 2.5
		return
	active_question = _build_generated_question()
	_equation_for(active_question)
	if accessibility_profile.reducedMotion:
		_spawn_static_answers()
	else:
		_spawn_wave()
	spawn_clock = spawn_interval
	_read_current_question()
	return
	if not _request_question_for_next_practice_set():
		game_running = false
		equation_label.text = "Sem contas agora"
		hint_label.text = "Ainda não há contas dessa operação para sua série."


func _build_generated_question() -> Dictionary:
	var base_min := 1
	var base_max := 10
	match selected_difficulty:
		"normal":
			base_min = 2
			base_max = 25 + floori(float(score) / 240.0) * 10
		"hard":
			base_min = 10
			base_max = 99 + floori(float(score) / 240.0) * 10
	base_max = mini(base_max, 999)
	var first := randi_range(base_min, base_max)
	var second := randi_range(base_min, base_max)
	if selected_operation == "subtraction" and first < second:
		var swap := first
		first = second
		second = swap
	elif selected_operation == "division":
		# Forme o dividendo a partir do divisor e do quociente para nunca gerar resto.
		second = randi_range(base_min, base_max)
		var quotient := randi_range(base_min, base_max)
		first = second * quotient
	var operands: Array[int] = [first, second]
	return {
		"gameId": game_id,
		"generated": true,
		"operation": {
			"kind": selected_operation,
			"symbol": OP_SYMBOLS[selected_operation],
			"operands": operands,
			"operators": [selected_operation],
		},
	}


func _request_question_for_next_practice_set() -> bool:
	var next_practice_set := ""
	for candidate in active_practice_set_candidates:
		if not attempted_practice_sets.has(candidate):
			next_practice_set = candidate
			break
	if next_practice_set.is_empty():
		return false
	attempted_practice_sets.append(next_practice_set)
	var query := "gameId=%s&operation=%s&practiceMode=free_practice&practiceSet=%s" % [game_id.uri_encode(), selected_operation, next_practice_set.uri_encode()]
	api_request_kind = "question"
	request_pending = true
	var headers := ["Authorization: Bearer %s" % api_token, "Accept: application/json"]
	var error := api.request("%s/learning/games/next-question?%s" % [api_base_url, query], headers, HTTPClient.METHOD_GET)
	if error != OK:
		api_request_kind = ""
		request_pending = false
		retry_clock = 2.5
	return true


func _build_local_question(practice_set: String) -> Dictionary:
	var operands: Array[int] = []
	var operators: Array[String] = []
	var missing_index := -1
	var result := 0
	match practice_set:
		"add_1_3":
			operands = [randi_range(1, 3), randi_range(1, 3)]
		"add_1_5":
			operands = [randi_range(1, 5), randi_range(1, 5)]
		"add_over_10":
			operands = [randi_range(6, 20), randi_range(6, 20)]
		"add_over_15":
			operands = [randi_range(8, 25), randi_range(8, 25)]
		"add_over_20":
			operands = [randi_range(11, 30), randi_range(11, 30)]
		"add_missing":
			operands = [randi_range(0, 20), randi_range(0, 20)]
			missing_index = randi_range(0, 1)
			result = operands[0] + operands[1]
		"add_2_digits":
			operands = [randi_range(10, 99), randi_range(10, 99)]
		"add_hard":
			operands = [randi_range(100, 999), randi_range(100, 999), randi_range(10, 99)]
		"sub_0_5":
			var first := randi_range(0, 5)
			operands = [first, randi_range(0, first)]
		"sub_0_10":
			var first := randi_range(0, 10)
			operands = [first, randi_range(0, first)]
		"sub_0_20_easy":
			var first := randi_range(0, 20)
			operands = [first, randi_range(0, first)]
		"sub_0_20":
			var first := randi_range(0, 20)
			operands = [first, randi_range(0, first)]
		"sub_missing":
			operands = [randi_range(0, 20), randi_range(0, 20)]
			missing_index = randi_range(0, 1)
			result = operands[0] - operands[1]
		"sub_0_100":
			var first := randi_range(0, 100)
			operands = [first, randi_range(0, first)]
		"sub_hard":
			operands = [randi_range(100, 9999), randi_range(100, 9999)]
		"mul_missing_2_3":
			var known := randi_range(2, 3)
			var answer := randi_range(1, 12)
			if randf() < 0.5:
				operands.append_array([answer, known])
			else:
				operands.append_array([known, answer])
			missing_index = randi_range(0, 1)
			result = operands[0] * operands[1]
		"mul_missing_4_5":
			var known := randi_range(4, 5)
			var answer := randi_range(1, 12)
			if randf() < 0.5:
				operands.append_array([answer, known])
			else:
				operands.append_array([known, answer])
			missing_index = randi_range(0, 1)
			result = operands[0] * operands[1]
		"mul_2", "mul_3", "mul_4", "mul_5", "mul_6", "mul_7", "mul_8", "mul_9", "mul_10":
			var table_factor := int(practice_set.trim_prefix("mul_"))
			var other_factor := randi_range(0, 12)
			if randf() < 0.5:
				operands.append_array([table_factor, other_factor])
			else:
				operands.append_array([other_factor, table_factor])
		"mul_0_7":
			operands = [randi_range(0, 7), randi_range(0, 7)]
		"mul_11_12":
			var fixed_factor := randi_range(11, 12)
			var factor := randi_range(0, 12)
			if randf() < 0.5:
				operands.append_array([fixed_factor, factor])
			else:
				operands.append_array([factor, fixed_factor])
		"mul_hard":
			operands = [randi_range(10, 99), randi_range(10, 99)]
		"div_missing_1_10":
			var divisor := randi_range(1, 10)
			var quotient := randi_range(1, 12)
			operands = [divisor * quotient, divisor]
			missing_index = randi_range(0, 1)
			result = quotient
		"div_1_5", "div_1_10":
			var max_divisor := 5 if practice_set == "div_1_5" else 10
			var divisor := randi_range(1, max_divisor)
			operands = [divisor * randi_range(0, 20), divisor]
		"div_2", "div_3", "div_4", "div_5", "div_6", "div_7", "div_8", "div_9", "div_10":
			var divisor := int(practice_set.trim_prefix("div_"))
			operands = [divisor * randi_range(0, 20), divisor]
		"div_11_12":
			var divisor := randi_range(11, 12)
			operands = [divisor * randi_range(0, 20), divisor]
		"div_hard":
			var divisor := randi_range(11, 100)
			operands = [divisor * randi_range(0, 20), divisor]
	operators.resize(maxi(0, operands.size() - 1))
	operators.fill(selected_operation)
	var operation := {"kind": selected_operation, "symbol": OP_SYMBOLS[selected_operation], "operands": operands, "operators": operators}
	if missing_index >= 0:
		operation["missingIndex"] = missing_index
		operation["result"] = result
	return {"operation": operation}


func _equation_for(question: Dictionary) -> void:
	var operation: Dictionary = question.get("operation", {})
	var operands: Array = operation.get("operands", [])
	var operators: Array = operation.get("operators", [])
	if operands.is_empty():
		equation_label.text = str(question.get("equation", "Conta numérica indisponível"))
		call_deferred("_update_answer_instructions")
		return
	var symbol: String = operation.get("symbol", OP_SYMBOLS.get(selected_operation, "?"))
	if int(operation.get("missingIndex", -1)) >= 0:
		var missing_index := int(operation.missingIndex)
		var expression := " %s " % symbol
		var left := "?" if missing_index == 0 else str(operands[0])
		var right := "?" if missing_index == 1 else str(operands[1])
		var result := int(operation.get("result", 0))
		equation_label.text = "%s%s%s = %d" % [left, expression, right, result]
	else:
		if operators.is_empty():
			operators = [selected_operation]
		var parts: PackedStringArray = []
		for index in range(operands.size()):
			parts.append(str(operands[index]))
			if index < operators.size():
				parts.append(" %s " % OP_SYMBOLS.get(operators[index], symbol))
		equation_label.text = "%s = ?" % "".join(parts)
	call_deferred("_update_answer_instructions")


func _update_answer_instructions() -> void:
	var input_text := "Toque ou clique no número certo."
	if accessibility_profile.reducedMotion:
		input_text = "Toque ou clique no número certo."
	elif accessibility_profile.preferredInput == "touch":
		input_text = "Toque no doce que tem a resposta."
	else:
		input_text = "Toque ou clique no doce com a resposta."
	if accessibility_profile.pace == "untimed":
		input_text = "Sem pressa! " + input_text
	if accessibility_profile.audioAssistance:
		input_text += " Clique uma vez na conta para ouvi-la de novo."
	hint_label.text = input_text


func _question_target(question: Dictionary) -> int:
	var operation: Dictionary = question.get("operation", {})
	var operands: Array = operation.get("operands", [])
	var missing_index := int(operation.get("missingIndex", -1))
	if missing_index >= 0 and missing_index < operands.size():
		return int(operands[missing_index])
	if operands.is_empty():
		return int(question.get("answer", 0))
	var kind: String = operation.get("kind", selected_operation)
	var operators: Array = operation.get("operators", [])
	if operators.is_empty():
		for _index in range(operands.size() - 1):
			operators.append(kind)
	if operators.size() != operands.size() - 1:
		return int(question.get("answer", 0))
	var values: Array[float] = [float(operands[0])]
	var low_operators: Array[String] = []
	for index in range(operators.size()):
		var next_value := float(operands[index + 1])
		var operator_name := str(operators[index])
		if operator_name == "multiplication":
			values[values.size() - 1] *= next_value
		elif operator_name == "division":
			if is_zero_approx(next_value):
				return int(question.get("answer", 0))
			values[values.size() - 1] /= next_value
		else:
			low_operators.append(operator_name)
			values.append(next_value)
	var result := values[0]
	for index in range(low_operators.size()):
		if low_operators[index] == "addition":
			result += values[index + 1]
		else:
			result -= values[index + 1]
	return roundi(result)


func _on_candy_smashed(candy: GaussCandy) -> void:
	_submit_answer(candy.value, candy.global_position, candy)


func _submit_answer(answer_value: int, hit_position: Vector2, selected_candy: GaussCandy = null) -> void:
	if not game_running or request_pending:
		return
	answer_feedback_label.visible = false
	if not accessibility_profile.reducedMotion:
		_spawn_background_crack(hit_position)
	request_pending = true
	attempts += 1
	for node in candy_layer.get_children():
		var remaining_candy := node as GaussCandy
		if remaining_candy and remaining_candy != selected_candy:
			if accessibility_profile.pace == "untimed":
				remaining_candy.queue_free()
			else:
				remaining_candy.fall_away()
	spawn_clock = maxf(spawn_clock, 0.85)
	if accessibility_profile.reducedMotion:
		_set_static_answer_buttons_disabled(true)
	if local_mode:
		_resolve_attempt(answer_value == _question_target(active_question), answer_value)
		return
	pending_attempt = {
		"eventId": _event_id(),
		"gameId": game_id,
		"operation": str(active_question.operation.kind),
		"operands": active_question.operation.operands,
		"choice": answer_value,
		"difficulty": selected_difficulty,
		"score": score,
		"occurredAt": Time.get_datetime_string_from_system(true),
	}
	_send_pending_attempt()


func _set_static_answer_buttons_disabled(disabled: bool) -> void:
	for answer_button in static_answer_buttons:
		answer_button.disabled = disabled


func _send_pending_attempt() -> void:
	if pending_attempt.is_empty():
		return
	request_pending = true
	api_request_kind = "generated_attempt"
	var headers := ["Authorization: Bearer %s" % api_token, "Content-Type: application/json", "Accept: application/json"]
	var error := api.request("%s/learning/games/generated-attempt" % api_base_url, headers, HTTPClient.METHOD_POST, JSON.stringify(pending_attempt))
	if error != OK:
		api_request_kind = ""
		request_pending = false
		retry_clock = 2.5


func _event_id() -> String:
	var crypto := Crypto.new()
	return "evt-%s-%s" % [str(Time.get_unix_time_from_system()), crypto.generate_random_bytes(12).hex_encode()]


func _on_api_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_pending = false
	var completed_request_kind := api_request_kind
	api_request_kind = ""
	var parsed: Variant = JSON.parse_string(_decode_response_body(body))
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 500 or response_code == 0:
		if not pending_attempt.is_empty():
			retry_clock = 2.5
			return
		if game_running and active_question.is_empty():
			hint_label.text = "A conta não carregou. Tentando conectar de novo…"
			retry_clock = 2.5
			return
	if response_code < 200 or response_code >= 300:
		if not pending_attempt.is_empty():
			pending_attempt.clear()
		if response_code == 404 and completed_request_kind == "question" and _request_question_for_next_practice_set():
			return
		game_running = false
		if response_code == 404:
			equation_label.text = "Sem contas agora"
			hint_label.text = "Ainda não há contas dessa operação para sua série."
		else:
			equation_label.text = "Não foi possível carregar as contas da API."
			hint_label.text = "Confira sua sessão Project Gauss e tente novamente."
		return
	if not parsed is Dictionary:
		game_running = false
		equation_label.text = "A API enviou uma conta em formato inesperado."
		return
	if completed_request_kind == "school_year":
		var received_year := int(parsed.get("schoolYear", 0))
		if received_year < 1 or received_year > 12:
			game_running = false
			equation_label.text = "A API enviou uma série inválida."
			hint_label.text = "A questão não foi iniciada sem uma série escolar válida."
			return
		active_school_year = received_year
		if active_school_year < MULTIPLICATION_UNLOCK_YEAR:
			selected_operations.erase("multiplication")
			selected_operations.erase("division")
			if selected_operations.is_empty():
				selected_operations = ["addition"]
			selected_operation = selected_operations.pick_random()
		_request_next_question()
		return
	if parsed.has("correct"):
		pending_attempt.clear()
		_resolve_attempt(bool(parsed.correct), int(parsed.get("pointsDelta", 0)), true)
		if not bool(parsed.correct) and accessibility_profile.reducedMotion:
			_set_static_answer_buttons_disabled(false)
		var feedback: Variant = parsed.get("feedback", {})
		if not bool(parsed.correct) and feedback is Dictionary and not str(feedback.get("reason", "")).is_empty():
			hint_label.text = str(feedback.reason)
	else:
		var required_question_fields := ["lessonId", "lessonVersion", "phaseId", "exerciseId", "gameId", "operation"]
		for field in required_question_fields:
			if not parsed.has(field):
				game_running = false
				equation_label.text = "A API enviou uma questão incompleta."
				hint_label.text = "A questão não foi iniciada porque faltam dados oficiais para registrar sua resposta."
				return
		var received_operation: Variant = parsed.get("operation")
		var received_lesson_version := int(parsed.get("lessonVersion", 0))
		var received_ids := ["lessonId", "phaseId", "exerciseId", "gameId"]
		for field in received_ids:
			if str(parsed.get(field, "")).strip_edges().is_empty():
				game_running = false
				equation_label.text = "A API enviou uma questão incompleta."
				hint_label.text = "Faltam identificadores oficiais para registrar esta resposta."
				return
		if received_lesson_version < 1 or not received_operation is Dictionary or not received_operation.get("operands", []) is Array or received_operation.operands.size() < 2:
			game_running = false
			equation_label.text = "A API enviou uma questão em formato inesperado."
			hint_label.text = "A rodada não começou para evitar registrar uma resposta inválida."
			return
		answer_feedback_label.visible = false
		active_question = parsed
		active_answer_choices.clear()
		selected_operation = str(received_operation.get("kind", selected_operation))
		_equation_for(active_question)
		hint_label.text = "Acerte um doce com o número!"
		request_pending = false
		if accessibility_profile.reducedMotion:
			_spawn_static_answers()
		else:
			_spawn_wave()
		spawn_clock = spawn_interval
		_read_current_question()


func _decode_response_body(body: PackedByteArray) -> String:
	if _is_valid_utf8(body):
		return body.get_string_from_utf8()
	var decoded := PackedStringArray()
	for byte in body:
		decoded.append(String.chr(_windows_1252_codepoint(byte)))
	return "".join(decoded)


func _is_valid_utf8(bytes: PackedByteArray) -> bool:
	var index := 0
	while index < bytes.size():
		var first := int(bytes[index])
		if first <= 0x7f:
			index += 1
			continue
		var continuation_count := 0
		if first >= 0xc2 and first <= 0xdf:
			continuation_count = 1
		elif first >= 0xe0 and first <= 0xef:
			continuation_count = 2
		elif first >= 0xf0 and first <= 0xf4:
			continuation_count = 3
		else:
			return false
		if index + continuation_count >= bytes.size():
			return false
		for continuation_offset in range(1, continuation_count + 1):
			var continuation := int(bytes[index + continuation_offset])
			if continuation < 0x80 or continuation > 0xbf:
				return false
		var second := int(bytes[index + 1])
		if first == 0xe0 and second < 0xa0:
			return false
		if first == 0xed and second > 0x9f:
			return false
		if first == 0xf0 and second < 0x90:
			return false
		if first == 0xf4 and second > 0x8f:
			return false
		index += continuation_count + 1
	return true


func _windows_1252_codepoint(byte: int) -> int:
	if byte < 0x80 or byte >= 0xa0:
		return byte
	var windows_1252_controls := [
		0x20ac, 0x0081, 0x201a, 0x0192, 0x201e, 0x2026, 0x2020, 0x2021,
		0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008d, 0x017d, 0x008f,
		0x0090, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
		0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, 0x009d, 0x017e, 0x0178,
	]
	return windows_1252_controls[byte - 0x80]


func _resolve_attempt(is_correct: bool, _answer_value: int, _from_api := false) -> void:
	request_pending = false
	if is_correct:
		answer_feedback_label.text = "ACERTOU!"
		answer_feedback_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.62, 1.0))
		consecutive_wrong_answers = 0
		_flash_feedback(Color(0.12, 1.0, 0.24, 1.0))
		AudioManager.play_correct()
		combo += 1
		correct_attempts += 1
		var streak_bonus := mini(combo, 10)
		var time_reward := 0.0
		if accessibility_profile.pace != "untimed":
			time_reward = 15.0
			match combo:
				1: time_reward = 5.0
				2: time_reward = 7.0
				3: time_reward = 10.0
				4: time_reward = 12.0
			remaining_time = minf(round_seconds, remaining_time + time_reward)
		score += 10 + streak_bonus * 3
		hint_label.text = "ACERTO! Sequencia %d!" % combo if accessibility_profile.pace == "untimed" else "ACERTO! Sequencia %d! +%ds de tempo!" % [combo, roundi(time_reward)]
	else:
		answer_feedback_label.text = "ERROU. Tente outra resposta."
		answer_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.58, 1.0))
		consecutive_wrong_answers += 1
		_flash_feedback(Color(1.0, 0.12, 0.1, 1.0))
		combo = 0
		AudioManager.play_mistake()
		if accessibility_profile.pace != "untimed":
			var penalty := float(difficulty.get("penalty", 3.0))
			remaining_time = maxf(0.0, remaining_time - penalty)
		hint_label.text = "Ainda não. Tente outra resposta!"
	answer_feedback_label.visible = true
	_update_score()
	_update_timer()
	if game_running and is_correct:
		next_question_voice_prefix = "Você acertou. Próxima conta."
		_request_next_question()
	elif game_running and consecutive_wrong_answers >= 3:
		consecutive_wrong_answers = 0
		hint_label.text = "Vamos trocar de conta!"
		next_question_voice_prefix = "Você errou. Vamos trocar de conta."
		_request_next_question()
	elif game_running:
		_read_current_question("Você errou.")


func _flash_feedback(flash_color: Color) -> void:
	if accessibility_profile.reducedMotion or accessibility_profile.focusMode:
		return
	var material := feedback_flash.material as ShaderMaterial
	if material == null:
		return
	if feedback_tween != null and feedback_tween.is_running():
		feedback_tween.kill()
	material.set_shader_parameter("flash_color", flash_color)
	material.set_shader_parameter("strength", 0.72)
	feedback_tween = create_tween()
	feedback_tween.tween_method(
		func(value: float) -> void:
			material.set_shader_parameter("strength", value),
		0.72,
		0.0,
		0.34
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _update_score() -> void:
	score_label.text = "PONTOS: %d" % score
	if score > record:
		record = score
		_update_record()
		var config := ConfigFile.new()
		config.load("user://ninja_matematica.cfg")
		config.set_value("game", "record", record)
		config.save("user://ninja_matematica.cfg")


func _update_record() -> void:
	record_label.text = "RECORDE: %d" % record


func _update_timer() -> void:
	var base_font_size := int(timer_label.get_meta("gauss_base_font_size", 18))
	var accessibility_scale := float(accessibility_profile.textScale)
	if accessibility_profile.pace == "untimed":
		timer_label.text = "TEMPO: ∞"
		timer_label.add_theme_font_size_override("font_size", maxi(12, roundi(float(base_font_size) * 1.35 * accessibility_scale)))
		timer_label.modulate = Color.WHITE
		return
	timer_label.add_theme_font_size_override("font_size", maxi(12, roundi(float(base_font_size) * accessibility_scale)))
	var seconds_to_display := int(ceil(remaining_time))
	if round_seconds <= 60.0:
		seconds_to_display -= 1
	timer_label.text = "TEMPO: %d" % maxi(seconds_to_display, 0)
	if remaining_time <= 10.0:
		timer_label.modulate = Color(1.0, 0.35, 0.23)
	else:
		timer_label.modulate = Color.WHITE


func _end_round() -> void:
	_stop_current_reading()
	game_running = false
	remaining_time = 0.0
	_update_timer()
	if score > record:
		record = score
		var config := ConfigFile.new()
		config.load("user://ninja_matematica.cfg")
		config.set_value("game", "record", record)
		config.save("user://ninja_matematica.cfg")
	_update_record()
	pause_button.visible = false
	game_over_score.text = str(score)
	game_over_correct.text = str(correct_attempts)
	game_over_attempts.text = str(attempts)
	game_over_overlay.visible = true
	hint_label.text = "FIM DE JOGO"
	AudioManager.speak_accessibility(
		"O tempo acabou. Você marcou %d pontos e acertou %d contas." % [score, correct_attempts],
		true
	)


func _open_pause() -> void:
	if not game_running:
		return
	_stop_current_reading()
	pause_menu.visible = true
	pause_options.visible = false
	pause_art.visible = true
	pause_options_art.visible = false
	pause_overlay.visible = true
	pointer_down = false
	get_tree().paused = true
	AudioManager.play_ui()


func _resume_game() -> void:
	pause_overlay.visible = false
	get_tree().paused = false
	AudioManager.play_ui()
	AudioManager.speak_accessibility("Continuando o jogo.", true)


func _show_pause_options() -> void:
	pause_menu.visible = false
	pause_options.visible = true
	pause_art.visible = false
	pause_options_art.visible = true
	AudioManager.play_ui()
	AudioManager.speak_accessibility("Opções abertas.", true)


func _show_pause_menu() -> void:
	pause_options.visible = false
	pause_menu.visible = true
	pause_art.visible = true
	pause_options_art.visible = false
	AudioManager.play_ui()


func _pause_option_toggled(enabled: bool, option_name: String) -> void:
	if option_name == "hints":
		settings["show_hints"] = enabled
		hint_label.visible = enabled
	else:
		settings[option_name] = enabled
	match option_name:
		"music": AudioManager.set_music_enabled(enabled)
		"sfx": AudioManager.set_sfx_enabled(enabled)
		"fullscreen": AudioManager.set_fullscreen(enabled)
	var config := ConfigFile.new()
	config.load("user://ninja_matematica.cfg")
	config.set_value("options", option_name, enabled)
	config.save("user://ninja_matematica.cfg")
	_sync_pause_toggle_art()
	AudioManager.play_ui()
	AudioManager.speak_option_state(option_name, enabled)


func _announce_pause_option_hover(option_name: String, hover_source: Object = null) -> void:
	var enabled := false
	match option_name:
		"music": enabled = music_check.button_pressed
		"sfx": enabled = sfx_check.button_pressed
		"hints": enabled = hints_check.button_pressed
		"fullscreen": enabled = fullscreen_check.button_pressed
	if hover_source != null:
		AudioManager.speak_option_state(option_name, enabled, hover_source)
	else:
		AudioManager.speak_option_state(option_name, enabled)


func _announce_pause_options_back_hover(hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover("Voltar ao menu da pausa.", hover_source)
	else:
		AudioManager.speak_accessibility("Voltar ao menu da pausa.")


func _sync_pause_toggle_art() -> void:
	if not is_node_ready():
		return
	var states := [music_check.button_pressed, sfx_check.button_pressed, hints_check.button_pressed, fullscreen_check.button_pressed]
	for index in range(states.size()):
		var enabled: bool = states[index]
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#f32678") if enabled else Color("#555255")
		track.set_corner_radius_all(18)
		pause_toggle_tracks[index].add_theme_stylebox_override("panel", track)
		pause_toggle_knobs[index].position.x = 36.0 if enabled else 3.0


func _retry_round() -> void:
	if not pending_attempt.is_empty():
		return
	start_round()
	AudioManager.play_ui()


func _exit_to_menu() -> void:
	get_tree().paused = false
	AudioManager.play_ui()
	AudioManager.speak_accessibility("Indo para o menu.", true)
	SceneFlow.change_scene("res://scenes/menu.tscn")


func _operation_title(operation_id: String) -> String:
	var titles := {"addition": "ADIÇÃO", "subtraction": "SUBTRAÇÃO", "multiplication": "MULTIPLICAÇÃO", "division": "DIVISÃO"}
	return titles.get(operation_id, "")
