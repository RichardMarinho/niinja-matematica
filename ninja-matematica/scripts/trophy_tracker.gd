extends Node
## Only the API can grant trophies. Local score and firstCorrect are unrelated.

@export var count_label: Label
@export var notice_label: Label
var trophy_count := -1
var revision := 0
var summary_revision := 0
var request: HTTPRequest

func _ready() -> void:
	request = HTTPRequest.new()
	request.timeout = 15.0
	add_child(request)
	request.request_completed.connect(_on_summary_completed)

func load_summary(base_url: String, token: String) -> void:
	if token.is_empty():
		count_label.text = "TROFÉUS: --"
		count_label.accessibility_name = "Entre pelo site para consultar seus troféus."
		return
	summary_revision = revision
	count_label.text = "TROFÉUS: consultando..."
	if OS.has_feature("web"):
		request.accept_gzip = false
	if request.request(base_url + "/learning/trophies", ["Authorization: Bearer " + token, "Accept: application/json"]) != OK:
		_show_unavailable()

static func valid_count(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 9007199254740991.0 and float(value) == floor(float(value))

static func valid_attempt(result: Dictionary, pending: Dictionary) -> bool:
	return not pending.is_empty() and result.get("eventId") is String and result.eventId == pending.get("eventId") and result.get("correct") is bool and valid_count(result.get("trophyCount")) and valid_count(result.get("trophiesDelta")) and int(result.trophiesDelta) <= 1 and (int(result.trophiesDelta) == 0 or result.correct == true) and int(result.trophyCount) >= int(result.trophiesDelta)

func confirm_attempt(result: Dictionary) -> void:
	revision += 1
	_set_count(int(result.trophyCount))
	notice_label.text = "Você ganhou um troféu!" if int(result.trophiesDelta) == 1 else ""
	notice_label.accessibility_name = notice_label.text
	notice_label.visible = not notice_label.text.is_empty()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window.parent!==window) window.parent.postMessage({type:'gauss-progress-updated',version:1},window.location.origin)")

func _on_summary_completed(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# A slow initial GET must never overwrite a newer confirmed attempt.
	if revision != summary_revision:
		return
	if result != HTTPRequest.RESULT_SUCCESS or status < 200 or status >= 300:
		_show_unavailable()
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not json.data is Dictionary or not valid_count(json.data.get("trophyCount")):
		_show_unavailable()
		return
	_set_count(int(json.data.trophyCount))

func _set_count(value: int) -> void:
	trophy_count = value
	count_label.text = "TROFÉUS: %d" % value
	count_label.accessibility_name = "Total de troféus: %d" % value

func _show_unavailable() -> void:
	count_label.text = "TROFÉUS: indisponível"
	count_label.accessibility_name = "Não foi possível consultar seus troféus agora."
