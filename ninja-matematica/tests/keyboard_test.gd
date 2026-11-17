extends SceneTree
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in range(4):
		await process_frame

func key(code: Key, shift := false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.shift_pressed = shift
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func run() -> void:
	change_scene_to_file("res://scenes/menu.tscn")
	await settle()
	check(current_scene.exit_button.disabled, "Exit is unavailable without site host")
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
	game.accessibility_profile.reducedMotion = true
	game.accessibility_profile.pace = "untimed"
	game.active_question = {"operation": {"kind": "addition", "operands": [2, 3]}, "gameId": "ninja-matematica"}
	game.active_answer_choices.assign([5, 4, 6, 7])
	game._equation_for(game.active_question)
	game._update_timer()
	game._spawn_static_answers()
	if root.gui_get_focus_owner() != null:
		root.gui_get_focus_owner().release_focus()
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.equation_card, "First Tab focuses equation")
	await key(KEY_ENTER)
	check(game.sent_attempts == 0, "Equation Enter never submits an answer")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.read_screen_button, "Tab reaches the explicit read control")
	await key(KEY_TAB, true)
	check(root.gui_get_focus_owner() == game.equation_card, "ShiftTab reverses to equation")
	await key(KEY_TAB)
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.stop_reading_button, "Tab reaches the explicit stop-reading control")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.static_answer_buttons[0], "Tab reaches first answer after reading controls")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.static_answer_buttons[1], "Tab reaches second answer")
	await key(KEY_ENTER)
	check(game.sent_attempts == 1 and game.pending_attempt.choice == 4, "Enter sends exactly one selected answer")
	var pending: Dictionary = game.pending_attempt.duplicate(true)
	await key(KEY_ENTER)
	check(game.sent_attempts == 1, "Pending answer cannot be submitted twice")
	game._exit_to_menu()
	check(current_scene == game and game.pending_attempt == pending, "Cannot leave while attempt is pending")
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"eventId": pending.eventId, "correct": false, "trophiesDelta": 0, "trophyCount": 2}).to_utf8_buffer())
	check(root.gui_get_focus_owner() == game.static_answer_buttons[1] and not game.static_answer_buttons[1].disabled, "Wrong answer restores focus on selected answer")
	check(game.active_answer_choices == [5, 4, 6, 7], "Wrong answer preserves choices")
	await key(KEY_SPACE)
	check(game.sent_attempts == 2 and game.pending_attempt.choice == 4, "Space sends exactly one selected answer")
	game.pending_attempt.clear()
	game.request_pending = false
	game._set_static_answer_buttons_disabled(false)
	await key(KEY_TAB)
	await key(KEY_TAB)
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.pause_button, "Tab reaches pause")
	await key(KEY_ENTER)
	check(paused and game.pause_overlay.visible, "Enter opens pause")
	await key(KEY_TAB)
	check(game.pause_overlay.is_ancestor_of(root.gui_get_focus_owner()), "Pause keeps focus within modal")
	await key(KEY_ESCAPE)
	check(not paused and root.gui_get_focus_owner() == game.pause_button, "Resume restores gameplay focus")
	game.accessibility_profile.reducedMotion = false
	game.keyboard_answers = false
	game.static_answer_panel.visible = false
	game.candy_layer.visible = true
	var attempts_before: int = game.sent_attempts
	await key(KEY_TAB)
	check(game.static_answer_panel.visible and not game.candy_layer.visible and game.active_answer_choices == [5, 4, 6, 7], "Tab in candy mode activates same-question static alternative")
	check(game.sent_attempts == attempts_before, "Switching keyboard input never submits an answer")
	check(not game.trophies.count_label.is_visible_in_tree() and game.timer_label.text == "TEMPO: ∞", "Hidden trophy HUD and untimed timer preserved")
	game._end_round()
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.game_over_exit_button, "Game over Tab stays on modal actions")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.retry_button, "Game over cycle excludes hidden gameplay")
	print("KEYBOARD_TEST: " + ("PASS" if failures.is_empty() else str(failures)))
	quit(0 if failures.is_empty() else 1)
