extends "res://scripts/main.gd"
## Isolated input test: capture attempts in memory, never contact the API.
var sent_attempts := 0

func _send_pending_attempt() -> void:
	sent_attempts += 1
	request_pending = true
	api_request_kind = "generated_attempt"
