extends SceneTree

const Tracker := preload("res://scripts/trophy_tracker.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/menu.tscn")
	await process_frame
	root.get_node("SceneFlow").change_scene("res://scenes/game.tscn")
	for frame in range(5):
		await process_frame
	var game := current_scene
	game.set_process(false)
	check(game.local_mode and game.trophies.trophy_count == -1, "Standalone never grants trophies")
	var tracker: Node = game.trophies
	tracker._on_summary_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
	check(tracker.trophy_count == -1, "Summary failure is unknown, not fabricated zero")
	tracker._on_summary_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"trophyCount": 40, "classroomRank": null}).to_utf8_buffer())
	check(tracker.trophy_count == 40, "Initial absolute balance")
	var pending := {"eventId": "test-event", "choice": 5, "occurredAt": "2026-11-14T00:00:00Z"}
	var response := {"eventId": "test-event", "correct": true, "trophiesDelta": 1, "trophyCount": 41}
	check(Tracker.valid_attempt(response, pending), "Valid confirmed response")
	for invalid in [{"eventId": "other"}, {"correct": "true"}, {"trophiesDelta": 2}, {"trophiesDelta": -1}, {"trophyCount": -1}, {"trophyCount": 1.5}, {"trophyCount": "41"}, {"correct": false}]:
		var candidate := response.duplicate()
		candidate.merge(invalid, true)
		check(not Tracker.valid_attempt(candidate, pending), "Reject invalid response: " + str(invalid))
	var missing := response.duplicate()
	missing.erase("trophiesDelta")
	check(not Tracker.valid_attempt(missing, pending), "firstCorrect/missing delta cannot grant a trophy")
	check(not Tracker.valid_attempt(response, {}), "No confirmation without a pending attempt")
	game.pending_attempt = pending.duplicate(true)
	game.api_request_kind = "generated_attempt"
	game._on_api_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
	check(game.pending_attempt == pending and tracker.trophy_count == 40, "Network failure preserves exact retry payload and balance")
	game.game_running = true
	game.api_request_kind = "generated_attempt"
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], "[]".to_utf8_buffer())
	check(game.pending_attempt == pending and game.game_running and tracker.trophy_count == 40, "Malformed attempt response keeps round recoverable with exact retry")
	game.game_running = false
	game.api_request_kind = "generated_attempt"
	var wrong_event := response.duplicate()
	wrong_event.eventId = "other"
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(wrong_event).to_utf8_buffer())
	check(game.pending_attempt == pending and tracker.trophy_count == 40, "Mismatched event cannot consume pending attempt")
	game.api_request_kind = "generated_attempt"
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(response).to_utf8_buffer())
	check(game.pending_attempt.is_empty() and tracker.trophy_count == 41 and tracker.notice_label.visible, "Generated confirmation updates balance and celebrates delta1")
	tracker._on_summary_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify({"trophyCount": 40}).to_utf8_buffer())
	check(tracker.trophy_count == 41, "Late initial summary cannot roll back confirmed balance")
	game.pending_attempt = pending.duplicate(true)
	game.api_request_kind = "attempt"
	response.trophiesDelta = 0
	response.firstCorrect = true
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(response).to_utf8_buffer())
	check(tracker.trophy_count == 41 and not tracker.notice_label.visible, "Official replay delta0 does not celebrate even with firstCorrect")
	game.pending_attempt = pending.duplicate(true)
	game.api_request_kind = "attempt"
	response.correct = false
	game._on_api_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(response).to_utf8_buffer())
	check(tracker.trophy_count == 41 and not tracker.notice_label.visible, "Wrong answer preserves authoritative balance")
	check(not tracker.count_label.is_visible_in_tree() and not tracker.notice_label.is_visible_in_tree(), "Trophy HUD remains hidden after API confirmations")
	game.accessibility_profile.pace = "untimed"
	game._update_timer()
	check(game.timer_label.text == "TEMPO: ∞" and game.timer_label.accessibility_name == "Tempo sem limite", "Untimed timer uses infinity and accessible text")
	check(game.timer_label.get_theme_font("font").has_char(0x221E), "Timer font includes infinity glyph")
	game.accessibility_profile.pace = "normal"
	game._update_timer()
	check(not game.timer_label.accessibility_name.contains("sem limite"), "Timed mode restores countdown accessible label")
	print("TROPHIES_TEST: " + ("PASS" if failures.is_empty() else str(failures)))
	quit(0 if failures.is_empty() else 1)
