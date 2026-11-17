extends SceneTree

var failures: Array[String] = []
var spoken: Array[String] = []
var stop_requests := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for _frame in range(4):
		await process_frame


func run() -> void:
	var audio: Node = root.get_node("AudioManager")
	audio.connect("public_text_requested", _on_public_text_requested)
	audio.connect("public_text_stop_requested", _on_public_text_stop_requested)
	change_scene_to_file("res://scenes/menu.tscn")
	await settle()
	var old := current_scene
	var game: Node = load("res://scenes/game.tscn").instantiate()
	game.set_script(load("res://tests/keyboard_game_stub.gd"))
	root.get_node("SceneFlow").set("_scene_change_authorized", true)
	root.add_child(game)
	current_scene = game
	old.queue_free()
	await settle()
	game.set_process(false)
	game.local_mode = false
	game.game_running = true
	game.round_started = true
	game.selected_operation = "addition"
	game.accessibility_profile.audioAssistance = true
	game.accessibility_profile.preferredInput = "keyboard"
	game.accessibility_profile.pace = "untimed"
	game.active_question = {
		"operation": {"kind": "addition", "operands": [2, 3]},
		"correctAnswer": 5,
		"privateFeedback": "não ler",
	}
	game.active_answer_choices.assign([5, 4, 6, 7])
	game._equation_for(game.active_question)
	game._update_timer()
	game._spawn_static_answers()
	check(game.read_screen_button.is_visible_in_tree() and game.stop_reading_button.is_visible_in_tree(), "Visible reading and stop controls are available during the question")
	check(game.read_screen_button.accessibility_name.contains("pergunta") and game.stop_reading_button.accessibility_name == "Parar leitura", "Reading controls have explicit accessible names")
	var initial_reading: String = game._reading_text()
	check(initial_reading.contains("Pergunta: 2 + 3 = ?") and initial_reading.contains("Alternativa A: 5") and initial_reading.contains("Orientação:"), "Screen reading contains visible question, choices and next action")
	check(not initial_reading.contains("correctAnswer") and not initial_reading.contains("não ler"), "Screen reading never includes hidden answer or private feedback")
	game.read_screen_button.pressed.emit()
	await process_frame
	check(spoken.size() == 1 and spoken.back() == initial_reading, "The explicit read button requests exactly the public screen text")
	game._resolve_attempt(false, 4)
	var feedback_reading: String = game._reading_text()
	check(game.answer_feedback_label.visible and feedback_reading.contains("Retorno: ERROU. Tente outra resposta."), "Wrong-answer feedback remains available to manual reading")
	game.stop_reading_button.pressed.emit()
	await process_frame
	check(stop_requests == 1, "The visible stop button requests narration interruption")
	game._read_current_screen()
	game._open_pause()
	await process_frame
	check(stop_requests == 2, "Pausing interrupts an active narration request")
	check(game.pause_overlay.visible and paused, "Pause keeps the accessible activity in a modal state")
	paused = false
	game._resume_game()
	game.accessibility_profile.focusMode = true
	game.accessibility_profile.reducedMotion = true
	game.accessibility_profile.textScale = 2.0
	game.accessibility_profile.contrast = "high"
	game._apply_accessibility_profile()
	check(game.focus_background.visible and not game.background.visible and game.equation_label.get_theme_font_size("font_size") >= 70, "Focus mode, high contrast and 200 percent text apply to the actual game controls")
	audio.disconnect("public_text_requested", _on_public_text_requested)
	audio.disconnect("public_text_stop_requested", _on_public_text_stop_requested)
	print("ACCESSIBILITY_FLOW: " + ("PASS" if failures.is_empty() else str(failures)))
	quit(0 if failures.is_empty() else 1)


func _on_public_text_requested(content: String) -> void:
	spoken.append(content)


func _on_public_text_stop_requested() -> void:
	stop_requests += 1
