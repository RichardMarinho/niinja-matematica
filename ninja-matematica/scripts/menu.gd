extends Node2D

@onready var play_button: Button = $HUD/Root/PlayButton
@onready var options_button: Button = $HUD/Root/OptionsButton
@onready var exit_button: Button = $HUD/Root/ExitButton

var loading_preparation := false


func _ready() -> void:
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('practiceMode') === 'lesson'")):
		SceneFlow.call_deferred("change_scene", "res://scenes/game.tscn")
		return
	SceneFlow.entered_menu()
	play_button.pressed.connect(_open_preparation)
	options_button.pressed.connect(_open_options)
	exit_button.disabled = not _has_site_host()
	exit_button.tooltip_text = "Voltar à tela do site onde você abriu o jogo." if not exit_button.disabled else "Abra o jogo pelo site para usar Sair."
	exit_button.accessibility_description = exit_button.tooltip_text
	exit_button.pressed.connect(_exit_to_site)
	play_button.grab_focus()


func _has_site_host() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("(function(){try{return window.parent!==window && window.parent.location.origin===location.origin && new URLSearchParams(location.search).get('embed')==='1';}catch(e){return false;}})()"))


func _exit_to_site() -> void:
	if not _has_site_host():
		return
	JavaScriptBridge.eval("window.parent.postMessage({type:'gauss-ninja-exit',version:1},window.location.origin)")


func _open_preparation() -> void:
	if loading_preparation:
		return
	AudioManager.play_ui()
	loading_preparation = true
	play_button.disabled = true
	play_button.text = "AGUARDE..."
	options_button.disabled = true
	var token := OS.get_environment("GAUSS_API_TOKEN").strip_edges()
	var api_url := OS.get_environment("GAUSS_API_URL").strip_edges()
	if OS.has_feature("web"):
		token = str(JavaScriptBridge.eval("(function(){try{return window.parent.__GAUSS_STUDENT_TOKEN__ || localStorage.getItem('gauss.student.session') || '';}catch(e){return localStorage.getItem('gauss.student.session') || '';}})()")).strip_edges()
		api_url = str(JavaScriptBridge.eval("(window.parent && window.parent.__GAUSS_API_URL__) || ''")).strip_edges()
	if api_url.is_empty():
		api_url = "http://127.0.0.1:3001"
	if token.is_empty():
		_preparation_failed()
		return
	var request := HTTPRequest.new()
	request.timeout = 10.0
	request.accept_gzip = false
	add_child(request)
	var error := request.request(api_url.trim_suffix("/") + "/learning/lessons", ["Authorization: Bearer " + token, "Accept: application/json"])
	if error != OK:
		request.queue_free()
		_preparation_failed()
		return
	var response: Array = await request.request_completed
	request.queue_free()
	var parsed: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300 or not parsed is Dictionary:
		_preparation_failed()
		return
	var year := int(parsed.get("schoolYear", 0))
	if year < 1 or year > 12:
		_preparation_failed()
		return
	SceneFlow.preparation_school_year = year
	if SceneFlow.change_scene("res://scenes/preparation.tscn") != OK:
		SceneFlow.preparation_school_year = 0
		_preparation_failed()


func _preparation_failed() -> void:
	loading_preparation = false
	play_button.disabled = false
	options_button.disabled = false
	play_button.text = "TENTAR NOVAMENTE"
	play_button.tooltip_text = "Não foi possível confirmar sua série. Confira sua conexão e tente novamente pelo site."
	play_button.accessibility_description = play_button.tooltip_text
	play_button.grab_focus()


func _open_options() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/options.tscn")
