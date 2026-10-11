extends Node2D

@export var fruit_scene: PackedScene
@export_range(5.0, 120.0, 1.0) var round_seconds := 40.0
@export_range(0.5, 5.0, 0.1) var spawn_interval := 1.7
@export_range(0.2, 2.0, 0.05) var swipe_width := 50.0
@export_range(0.0, 120.0, 5.0) var spawn_point_jitter := 35.0
@export_range(300.0, 1200.0, 25.0) var fruit_launch_speed_min := 670.0
@export_range(300.0, 1400.0, 25.0) var fruit_launch_speed_max := 790.0
@export_range(0.0, 250.0, 10.0) var fruit_horizontal_spread := 90.0
@export var game_id := "ninja-matematica"
@export var api_base_url := "http://127.0.0.1:3001"

const PRACTICE_TIERS := {
	"addition": ["add_missing", "add_2_digits", "add_over_1000"],
	"subtraction": ["sub_missing", "sub_0_100", "sub_hard"],
	"multiplication": ["mul_missing_0_10", "mul_13_15", "mul_hard"],
	"division": ["div_missing_1_10", "div_13_15", "div_hard"],
}
const OP_SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}
const ROUND_TIME := 40.0

@onready var fruit_layer: Node2D = $FruitLayer
@onready var fruit_spawn_points: Node2D = $FruitSpawnPoints
@onready var slash_trail: Line2D = $SlashTrail
@onready var api: HTTPRequest = $API
@onready var score_label: Label = $HUD/Root/TopBar/ScoreCard/Score
@onready var timer_label: Label = $HUD/Root/TopBar/TimerCard/Timer
@onready var equation_label: Label = $HUD/Root/EquationCard/Equation
@onready var hint_label: Label = $HUD/Root/Hint
@onready var status_label: Label = $HUD/Root/BottomBar/Status
@onready var record_label: Label = $HUD/Root/BottomBar/Record
@onready var mode_buttons: HBoxContainer = $HUD/Root/TopBar/ModeButtons
@onready var restart_button: Button = $HUD/Root/BottomBar/RestartButton

var selected_operation := "multiplication"
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
var trail_points: Array[Vector2] = []
var active_question: Dictionary = {}
var local_mode := true
var api_token := ""
var attempts := 0
var correct_attempts := 0
var pending_attempt: Dictionary = {}
var retry_clock := 0.0


func _ready() -> void:
	api.request_completed.connect(_on_api_request_completed)
	restart_button.pressed.connect(start_round)
	api_token = OS.get_environment("GAUSS_API_TOKEN").strip_edges()
	var configured_url := OS.get_environment("GAUSS_API_URL").strip_edges()
	if not configured_url.is_empty():
		api_base_url = configured_url.trim_suffix("/")
	for child in mode_buttons.get_children():
		var button := child as Button
		if button:
			button.pressed.connect(_select_operation.bind(_operation_id_for_button(button.name)))
	var saved_record := ConfigFile.new()
	if saved_record.load("user://ninja_matematica.cfg") == OK:
		record = int(saved_record.get_value("game", "record", 0))
	_update_score()
	_update_record()
	if api_token.is_empty():
		status_label.text = "Modo local · defina GAUSS_API_TOKEN para registrar na API"
	else:
		local_mode = false
		status_label.text = "Conectando ao Project Gauss…"
	start_round()


func _select_operation(operation_id: String) -> void:
	selected_operation = operation_id
	_refresh_mode_styles()
	start_round()


func _refresh_mode_styles() -> void:
	for child in mode_buttons.get_children():
		var button := child as Button
		if not button:
			continue
		var selected := button.text == _operation_title(selected_operation)
		button.modulate = Color(1.0, 0.83, 0.47) if selected else Color(1.0, 1.0, 1.0, 0.82)


func _operation_id_for_button(button_name: String) -> String:
	match button_name:
		"AdditionButton": return "addition"
		"SubtractionButton": return "subtraction"
		"MultiplicationButton": return "multiplication"
		"DivisionButton": return "division"
	return "multiplication"


func start_round() -> void:
	if not pending_attempt.is_empty():
		status_label.text = "Aguarde a confirmação da tentativa pela API antes de reiniciar."
		return
	if request_pending:
		api.cancel_request()
		request_pending = false
	for fruit in fruit_layer.get_children():
		fruit.queue_free()
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
	_refresh_mode_styles()
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
		if int(remaining_time) != int(remaining_time + delta):
			_update_timer()
		if remaining_time <= 0.0:
			_end_round()
	_update_trail(delta)
	if not pending_attempt.is_empty() and not request_pending:
		retry_clock -= delta
		if retry_clock <= 0.0:
			_send_pending_attempt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		if pointer_down:
			previous_pointer = get_global_mouse_position()
			trail_points.clear()
		if not pointer_down:
			slash_trail.clear_points()
	elif event is InputEventMouseMotion and pointer_down:
		_handle_swipe(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		pointer_down = event.pressed
		if pointer_down:
			previous_pointer = event.position
			trail_points.clear()
		if not pointer_down:
			slash_trail.clear_points()
	elif event is InputEventScreenDrag and pointer_down:
		_handle_swipe(event.position)


func _handle_swipe(position: Vector2) -> void:
	if not game_running or request_pending:
		previous_pointer = position
		return
	trail_points.append(position)
	if trail_points.size() > 10:
		trail_points.pop_front()
	slash_trail.clear_points()
	for point in trail_points:
		slash_trail.add_point(point)
	for node in fruit_layer.get_children():
		var fruit := node as GaussFruit
		if fruit and not fruit.is_sliced and _distance_to_segment(fruit.global_position, previous_pointer, position) <= minf(swipe_width, fruit.slash_radius()):
			fruit.slice()
			break
	previous_pointer = position


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	if segment.length_squared() < 0.001:
		return point.distance_to(start)
	var projection := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * projection)


func _update_trail(delta: float) -> void:
	if not pointer_down and slash_trail.points.size() > 0:
		slash_trail.modulate.a = maxf(0.0, slash_trail.modulate.a - delta * 5.0)
		if slash_trail.modulate.a <= 0.0:
			slash_trail.clear_points()
			slash_trail.modulate.a = 1.0


func _spawn_wave() -> void:
	if active_question.is_empty():
		return
	var answers: Array[int] = _make_choices(_question_target(active_question))
	var points := fruit_spawn_points.get_children()
	for index in range(answers.size()):
		var spawn_point := points[index % points.size()] as Marker2D
		var launch := Vector2(randf_range(-fruit_horizontal_spread, fruit_horizontal_spread), -randf_range(fruit_launch_speed_min, fruit_launch_speed_max))
		var fruit := fruit_scene.instantiate() as GaussFruit
		fruit.setup(answers[index], randi_range(0, 3), launch)
		fruit.position = spawn_point.position + Vector2(randf_range(-spawn_point_jitter, spawn_point_jitter), randf_range(50.0, 100.0))
		fruit.scale = Vector2.ONE * randf_range(0.91, 1.05)
		fruit.sliced.connect(_on_fruit_sliced)
		fruit_layer.add_child(fruit)


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
	if local_mode:
		active_question = _build_local_question()
		_equation_for(active_question)
		return
	request_pending = true
	var tier_index := mini(int(score / 120), 2)
	var practice_set: String = PRACTICE_TIERS[selected_operation][tier_index]
	var query := "gameId=%s&operation=%s&practiceMode=free_practice&practiceSet=%s" % [game_id.uri_encode(), selected_operation, practice_set]
	var headers := ["Authorization: Bearer %s" % api_token, "Accept: application/json"]
	var error := api.request("%s/learning/games/next-question?%s" % [api_base_url, query], headers, HTTPClient.METHOD_GET)
	if error != OK:
		request_pending = false
		status_label.text = "Falha ao conectar à API (código %d). Confira URL e sessão." % error


func _build_local_question() -> Dictionary:
	var tier_index := mini(int(score / 120), 2)
	var low: int = [2, 10, 100][tier_index]
	var high: int = [12, 99, 999][tier_index]
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
			"division": operation["result"] = int(a / b)
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
		"division": return int(int(operands[0]) / int(operands[1]))
	return 0


func _on_fruit_sliced(fruit: GaussFruit) -> void:
	if not game_running or request_pending:
		return
	request_pending = true
	attempts += 1
	for node in fruit_layer.get_children():
		if node != fruit:
			node.queue_free()
	if local_mode:
		_resolve_attempt(fruit.value == _question_target(active_question), fruit.value)
		return
	pending_attempt = {
		"eventId": _event_id(),
		"type": "attempt_submitted",
		"gameId": active_question.get("gameId", game_id),
		"lessonId": active_question.get("lessonId", ""),
		"lessonVersion": active_question.get("lessonVersion", 1),
		"phaseId": active_question.get("phaseId", "practice"),
		"exerciseId": active_question.get("exerciseId", ""),
		"choice": fruit.value,
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
		status_label.text = "Sem resposta da API · tentando reenviar a mesma tentativa…"


func _event_id() -> String:
	var crypto := Crypto.new()
	return "evt-%s-%s" % [str(Time.get_unix_time_from_system()), crypto.generate_random_bytes(12).hex_encode()]


func _on_api_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_pending = false
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 500 or response_code == 0:
		if not pending_attempt.is_empty():
			retry_clock = 2.5
			status_label.text = "Sem conexão · tentando reenviar a mesma tentativa…"
			return
	if response_code < 200 or response_code >= 300:
		var message := "API retornou HTTP %d" % response_code
		if parsed is Dictionary:
			var api_message: Variant = parsed.get("message", message)
			message = ", ".join(api_message) if api_message is Array else str(api_message)
		status_label.text = "%s · confira a sessão e tente novamente" % message
		if not pending_attempt.is_empty():
			pending_attempt.clear()
			game_running = false
		return
	if not parsed is Dictionary:
		status_label.text = "A API respondeu em um formato inesperado."
		return
	if parsed.has("correct"):
		pending_attempt.clear()
		_resolve_attempt(bool(parsed.correct), int(parsed.get("pointsDelta", 0)), true)
	else:
		active_question = parsed
		_equation_for(active_question)
		request_pending = false
		status_label.text = "Partida conectada ao Project Gauss · %s" % _operation_title(selected_operation)


func _resolve_attempt(is_correct: bool, _answer_value: int, from_api := false) -> void:
	request_pending = false
	if is_correct:
		combo += 1
		correct_attempts += 1
		score += 10 + mini(combo, 10) * 2
		if from_api:
			status_label.text = "Correto! A API registrou sua tentativa. Sequência: %d" % combo
		else:
			status_label.text = "Muito bem! Sequência de %d" % combo
		hint_label.text = "ACERTO! Próxima conta chegando…"
	else:
		combo = 0
		remaining_time = maxf(0.0, remaining_time - 3.0)
		hint_label.text = "Essa fruta não completa a conta. Tente a próxima!"
		status_label.text = "-3 segundos · use a conta para encontrar a fruta"
	_update_score()
	_update_timer()
	if game_running:
		_request_next_question()


func _update_score() -> void:
	score_label.text = "PONTOS  %d" % score


func _update_record() -> void:
	record_label.text = "RECORDE  %d" % record


func _update_timer() -> void:
	timer_label.text = "%02d:%02d" % [int(remaining_time) / 60, int(remaining_time) % 60]
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
		config.set_value("game", "record", record)
		config.save("user://ninja_matematica.cfg")
	_update_record()
	hint_label.text = "FIM DE JOGO · %d pontos em %d tentativas" % [score, attempts]
	status_label.text = "Acertos: %d · Tempo: %d s · Escolha JOGAR DE NOVO para outra partida" % [correct_attempts, int(elapsed_seconds)]


func _operation_title(operation_id: String) -> String:
	var titles := {"addition": "ADIÇÃO", "subtraction": "SUBTRAÇÃO", "multiplication": "MULTIPLICAÇÃO", "division": "DIVISÃO"}
	return titles.get(operation_id, "")
