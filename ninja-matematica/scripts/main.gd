extends Node2D

@export var candy_scene: PackedScene
@export_range(5.0, 120.0, 1.0) var round_seconds := 60.0
@export_range(0.5, 5.0, 0.1) var spawn_interval := 1.9
@export_range(24.0, 100.0, 2.0) var hammer_hit_radius := 58.0
@export_range(0.0, 120.0, 5.0) var spawn_point_jitter := 35.0
@export_range(300.0, 1200.0, 25.0) var candy_launch_speed_min := 610.0
@export_range(300.0, 1400.0, 25.0) var candy_launch_speed_max := 710.0
@export_range(0.0, 250.0, 10.0) var candy_horizontal_spread := 90.0
@export var game_id := "ninja-matematica"
@export var api_base_url := "http://127.0.0.1:3001"

const PRACTICE_TIERS := {
	"easy": {
		"addition": ["add_1_3", "add_1_5", "add_over_10"],
		"subtraction": ["sub_0_5", "sub_0_10", "sub_0_20_easy"],
		"multiplication": ["mul_missing_2_3", "mul_missing_4_5", "mul_0_10"],
		"division": ["div_missing_1_10", "div_1_5", "div_1_10"],
	},
	"normal": {
		"addition": ["add_2_digits", "add_over_1000", "add_over_1000"],
		"subtraction": ["sub_0_100", "sub_0_1000", "sub_hard"],
		"multiplication": ["mul_13_15", "mul_hard", "mul_hard"],
		"division": ["div_13_15", "div_hard", "div_hard"],
	},
	"hard": {
		"addition": ["add_2_digits", "add_over_1000", "add_over_1000"],
		"subtraction": ["sub_0_100", "sub_0_1000", "sub_hard"],
		"multiplication": ["mul_13_15", "mul_hard", "mul_hard"],
		"division": ["div_13_15", "div_hard", "div_hard"],
	},
}
const OP_SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}
const ROUND_TIME := 60.0
const DIFFICULTIES := {
	"easy": {"title": "FÁCIL", "seconds": 75.0, "penalty": 1.0, "spawn": 2.4, "speed_min": 500.0, "speed_max": 590.0, "number_min": 1, "number_max": 10, "tier": 0},
	"normal": {"title": "NORMAL", "seconds": 60.0, "penalty": 3.0, "spawn": 1.9, "speed_min": 610.0, "speed_max": 710.0, "number_min": 2, "number_max": 25, "tier": 1},
	"hard": {"title": "DIFÍCIL", "seconds": 45.0, "penalty": 5.0, "spawn": 1.45, "speed_min": 740.0, "speed_max": 860.0, "number_min": 10, "number_max": 99, "tier": 2},
}

@onready var candy_layer: Node2D = $CandyLayer
@onready var crack_layer: Node2D = $CrackLayer
@onready var candy_spawn_points: Node2D = $CandySpawnPoints
@onready var api: HTTPRequest = $API
@onready var score_label: Label = $HUD/Root/TopBar/ScoreCard/Score
@onready var timer_label: Label = $HUD/Root/TopBar/TimerCard/Timer
@onready var equation_label: Label = $HUD/Root/EquationCard/Equation
@onready var hint_label: Label = $HUD/Root/Hint
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
@onready var game_over_details: Label = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/Details
@onready var retry_button: Button = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/RetryButton
@onready var game_over_exit_button: Button = $HUD/Root/GameOverOverlay/Center/GameOverCard/Content/ExitButton

var selected_operation := "multiplication"
var selected_operations: Array[String] = []
var selected_difficulty := "normal"
var difficulty: Dictionary = DIFFICULTIES["normal"]
var settings := {"show_hints": true, "fullscreen": false, "music": true, "sfx": true}
var score := 0
var record := 0
var remaining_time := ROUND_TIME
var elapsed_seconds := 0.0
var spawn_clock := 0.0
var combo := 0
var game_running := false
var request_pending := false
var pointer_down := false
var previous_pointer := Vector2.ZERO
var active_question: Dictionary = {}
var local_mode := true
var api_token := ""
var attempts := 0
var correct_attempts := 0
var pending_attempt: Dictionary = {}
var retry_clock := 0.0
var feedback_tween: Tween


func _ready() -> void:
	if not SceneFlow.enter_scene_from_menu():
		return
	api.request_completed.connect(_on_api_request_completed)
	pause_button.pressed.connect(_open_pause)
	resume_button.pressed.connect(_resume_game)
	pause_options_button.pressed.connect(_show_pause_options)
	pause_exit_button.pressed.connect(_exit_to_menu)
	pause_options_back_button.pressed.connect(_show_pause_menu)
	retry_button.pressed.connect(_retry_round)
	game_over_exit_button.pressed.connect(_exit_to_menu)
	api_token = OS.get_environment("GAUSS_API_TOKEN").strip_edges()
	var configured_url := OS.get_environment("GAUSS_API_URL").strip_edges()
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
			if PRACTICE_TIERS[selected_difficulty].has(str(operation)):
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
	sfx_check.toggled.connect(_pause_option_toggled.bind("sfx"))
	hints_check.toggled.connect(_pause_option_toggled.bind("hints"))
	fullscreen_check.toggled.connect(_pause_option_toggled.bind("fullscreen"))
	pause_overlay.visible = false
	game_over_overlay.visible = false
	round_seconds = float(difficulty.seconds)
	spawn_interval = float(difficulty.spawn)
	candy_launch_speed_min = float(difficulty.speed_min)
	candy_launch_speed_max = float(difficulty.speed_max)
	hint_label.visible = bool(settings.show_hints)
	_update_score()
	_update_record()
	if not api_token.is_empty():
		local_mode = false
	start_round()

func start_round() -> void:
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
	attempts = 0
	correct_attempts = 0
	game_running = true
	request_pending = false
	_update_score()
	_update_timer()
	_request_next_question()


func _process(delta: float) -> void:
	if game_running:
		elapsed_seconds += delta
		remaining_time = maxf(0.0, remaining_time - delta)
		spawn_clock -= delta
		if spawn_clock <= 0.0 and not request_pending and pending_attempt.is_empty() and not active_question.is_empty():
			_spawn_wave()
			var speed_factor := 1.0 + (float(score) / 100.0) * 0.06
			spawn_clock = maxf(0.52, spawn_interval / speed_factor)
		_update_timer()
		if remaining_time <= 0.0:
			_end_round()
	if not pending_attempt.is_empty() and not request_pending:
		retry_clock -= delta
		if retry_clock <= 0.0:
			_send_pending_attempt()


func _unhandled_input(event: InputEvent) -> void:
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
	var answers: Array[int] = _make_choices(_question_target(active_question))
	var points := candy_spawn_points.get_children()
	for index in range(answers.size()):
		var spawn_point := points[index % points.size()] as Marker2D
		var launch := Vector2(randf_range(-candy_horizontal_spread, candy_horizontal_spread), -randf_range(candy_launch_speed_min, candy_launch_speed_max))
		var candy := candy_scene.instantiate() as GaussCandy
		candy.setup(answers[index], randi_range(0, 15), launch)
		candy.position = spawn_point.position + Vector2(randf_range(-spawn_point_jitter, spawn_point_jitter), randf_range(50.0, 100.0))
		candy.scale = Vector2.ONE * randf_range(0.91, 1.05)
		candy.smashed.connect(_on_candy_smashed)
		candy_layer.add_child(candy)


func _make_choices(answer: int) -> Array[int]:
	var values: Array[int] = [answer]
	var offset := 1
	while values.size() < 4:
		var candidate := answer + (offset if randf() < 0.5 else -offset)
		if candidate >= 0 and not values.has(candidate):
			values.append(candidate)
		offset += randi_range(1, 3)
	values.shuffle()
	return values


func _request_next_question() -> void:
	active_question.clear()
	if not selected_operations.is_empty():
		selected_operation = selected_operations.pick_random()
	if local_mode:
		active_question = _build_local_question()
		_equation_for(active_question)
		return
	request_pending = true
	var tier_index := mini(floori(float(score) / 240.0), 2)
	var practice_set: String = PRACTICE_TIERS[selected_difficulty][selected_operation][tier_index]
	var query := "gameId=%s&operation=%s&practiceMode=free_practice&practiceSet=%s" % [game_id.uri_encode(), selected_operation, practice_set]
	var headers := ["Authorization: Bearer %s" % api_token, "Accept: application/json"]
	var error := api.request("%s/learning/games/next-question?%s" % [api_base_url, query], headers, HTTPClient.METHOD_GET)
	if error != OK:
		request_pending = false


func _build_local_question() -> Dictionary:
	var low := int(difficulty.get("number_min", 2))
	var high := int(difficulty.get("number_max", 25))
	if score >= 240 and selected_difficulty != "easy":
		high = mini(high + floori(float(score) / 240.0) * 10, 999)
	var a := randi_range(low, high)
	var b := randi_range(low, high)
	var symbol: String = OP_SYMBOLS[selected_operation]
	var answer := 0
	if selected_operation == "addition":
		answer = a + b
	elif selected_operation == "subtraction":
		if b > a:
			var swap := a
			a = b
			b = swap
		answer = a - b
	elif selected_operation == "multiplication":
		answer = a * b
	else:
		answer = b
		a = a * b
	var missing_index := randi_range(0, 2)
	var operation := {"kind": selected_operation, "symbol": symbol, "operands": [a, b], "operators": [selected_operation]}
	if missing_index < 2:
		operation["missingIndex"] = missing_index
		match selected_operation:
			"addition": operation["result"] = a + b
			"subtraction": operation["result"] = a - b
			"multiplication": operation["result"] = a * b
			"division": operation["result"] = floori(float(a) / float(b))
	return {"answer": answer, "operation": operation}


func _equation_for(question: Dictionary) -> void:
	var operation: Dictionary = question.get("operation", {})
	var operands: Array = operation.get("operands", [])
	var operators: Array = operation.get("operators", [])
	if operands.is_empty():
		equation_label.text = question.get("equation", "Resolva a conta!")
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


func _question_target(question: Dictionary) -> int:
	var operation: Dictionary = question.get("operation", {})
	var operands: Array = operation.get("operands", [])
	var missing_index := int(operation.get("missingIndex", -1))
	if missing_index >= 0 and missing_index < operands.size():
		return int(operands[missing_index])
	if operands.size() < 2:
		return int(question.get("answer", 0))
	var kind: String = operation.get("kind", selected_operation)
	match kind:
		"addition": return int(operands[0]) + int(operands[1])
		"subtraction": return int(operands[0]) - int(operands[1])
		"multiplication": return int(operands[0]) * int(operands[1])
		"division": return floori(float(operands[0]) / float(operands[1]))
	return 0


func _on_candy_smashed(candy: GaussCandy) -> void:
	if not game_running or request_pending:
		return
	_spawn_background_crack(candy.global_position)
	request_pending = true
	attempts += 1
	for node in candy_layer.get_children():
		var remaining_candy := node as GaussCandy
		if remaining_candy and remaining_candy != candy:
			remaining_candy.fall_away()
	spawn_clock = maxf(spawn_clock, 0.85)
	if local_mode:
		_resolve_attempt(candy.value == _question_target(active_question), candy.value)
		return
	pending_attempt = {
		"eventId": _event_id(),
		"type": "attempt_submitted",
		"gameId": active_question.get("gameId", game_id),
		"lessonId": active_question.get("lessonId", ""),
		"lessonVersion": active_question.get("lessonVersion", 1),
		"phaseId": active_question.get("phaseId", "practice"),
		"exerciseId": active_question.get("exerciseId", ""),
		"choice": candy.value,
		"practiceMode": "free_practice",
		"occurredAt": Time.get_datetime_string_from_system(true),
	}
	_send_pending_attempt()


func _send_pending_attempt() -> void:
	if pending_attempt.is_empty():
		return
	request_pending = true
	var headers := ["Authorization: Bearer %s" % api_token, "Content-Type: application/json", "Accept: application/json"]
	var error := api.request("%s/learning/attempts" % api_base_url, headers, HTTPClient.METHOD_POST, JSON.stringify(pending_attempt))
	if error != OK:
		request_pending = false
		retry_clock = 2.5


func _event_id() -> String:
	var crypto := Crypto.new()
	return "evt-%s-%s" % [str(Time.get_unix_time_from_system()), crypto.generate_random_bytes(12).hex_encode()]


func _on_api_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_pending = false
	var parsed: Variant = JSON.parse_string(_decode_response_body(body))
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 500 or response_code == 0:
		if not pending_attempt.is_empty():
			retry_clock = 2.5
			return
	if response_code < 200 or response_code >= 300:
		if not pending_attempt.is_empty():
			pending_attempt.clear()
			game_running = false
		return
	if not parsed is Dictionary:
		return
	if parsed.has("correct"):
		pending_attempt.clear()
		_resolve_attempt(bool(parsed.correct), int(parsed.get("pointsDelta", 0)), true)
	else:
		active_question = parsed
		var operation: Dictionary = active_question.get("operation", {})
		selected_operation = str(operation.get("kind", selected_operation))
		_equation_for(active_question)
		request_pending = false


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
		_flash_feedback(Color(0.12, 1.0, 0.24, 1.0))
		combo += 1
		correct_attempts += 1
		score += 10 + mini(combo, 10) * 2
		hint_label.text = "ACERTO! Próxima conta chegando…"
	else:
		_flash_feedback(Color(1.0, 0.12, 0.1, 1.0))
		combo = 0
		AudioManager.play_mistake()
		var penalty := float(difficulty.get("penalty", 3.0))
		remaining_time = maxf(0.0, remaining_time - penalty)
		hint_label.text = "Ops! Esse não era o doce certo. Tente outro!"
	_update_score()
	_update_timer()
	if game_running and is_correct:
		_request_next_question()


func _flash_feedback(flash_color: Color) -> void:
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
	var seconds_to_display := int(ceil(remaining_time))
	if round_seconds <= 60.0:
		seconds_to_display -= 1
	timer_label.text = "TEMPO: %02d" % clampi(seconds_to_display, 0, 99)
	if remaining_time <= 10.0:
		timer_label.modulate = Color(1.0, 0.35, 0.23)
	else:
		timer_label.modulate = Color.WHITE


func _end_round() -> void:
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
	game_over_details.text = "PONTOS: %d   ·   ACERTOS: %d   ·   TENTATIVAS: %d" % [score, correct_attempts, attempts]
	game_over_overlay.visible = true
	hint_label.text = "FIM DE JOGO"


func _open_pause() -> void:
	if not game_running:
		return
	pause_menu.visible = true
	pause_options.visible = false
	pause_overlay.visible = true
	pointer_down = false
	get_tree().paused = true
	AudioManager.play_ui()


func _resume_game() -> void:
	pause_overlay.visible = false
	get_tree().paused = false
	AudioManager.play_ui()


func _show_pause_options() -> void:
	pause_menu.visible = false
	pause_options.visible = true
	pause_art.visible = false
	pause_options_art.visible = true
	AudioManager.play_ui()


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
	SceneFlow.change_scene("res://scenes/menu.tscn")


func _operation_title(operation_id: String) -> String:
	var titles := {"addition": "ADIÇÃO", "subtraction": "SUBTRAÇÃO", "multiplication": "MULTIPLICAÇÃO", "division": "DIVISÃO"}
	return titles.get(operation_id, "")
