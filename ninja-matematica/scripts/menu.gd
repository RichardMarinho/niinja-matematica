extends Node2D

@onready var play_button: Button = $HUD/Root/PlayButton
@onready var options_button: Button = $HUD/Root/OptionsButton
@onready var exit_button: Button = $HUD/Root/ExitButton


func _ready() -> void:
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('practiceMode') === 'lesson'")):
		SceneFlow.call_deferred("change_scene", "res://scenes/game.tscn")
		return
	SceneFlow.entered_menu()
	play_button.pressed.connect(_open_preparation)
	play_button.mouse_entered.connect(_speak_accessibility_text.bind("Jogar. Botão para começar o jogo.", play_button))
	play_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(play_button))
	play_button.focus_entered.connect(_speak_accessibility_text.bind("Jogar. Botão para começar o jogo."))
	options_button.pressed.connect(_open_options)
	options_button.mouse_entered.connect(_speak_accessibility_text.bind("Opções.", options_button))
	options_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(options_button))
	options_button.focus_entered.connect(_speak_accessibility_text.bind("Opções."))
	exit_button.disabled = not _has_site_host()
	exit_button.tooltip_text = "Voltar à tela do site onde você abriu o jogo." if not exit_button.disabled else "Abra o jogo pelo site para usar Sair."
	exit_button.accessibility_description = exit_button.tooltip_text
	exit_button.pressed.connect(_exit_to_site)
	exit_button.mouse_entered.connect(_speak_accessibility_text.bind("Sair. Voltar ao site.", exit_button))
	exit_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(exit_button))
	exit_button.focus_entered.connect(_speak_accessibility_text.bind("Sair. Voltar ao site."))
	play_button.grab_focus()


func _has_site_host() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("(function(){try{return window.parent!==window && window.parent.location.origin===location.origin && new URLSearchParams(location.search).get('embed')==='1';}catch(e){return false;}})()"))


func _exit_to_site() -> void:
	if not _has_site_host():
		return
	AudioManager.stop_accessibility_speech()
	JavaScriptBridge.eval("window.parent.postMessage({type:'gauss-ninja-exit',version:1},window.location.origin)")


func _open_preparation() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/preparation.tscn")


func _open_options() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/options.tscn")


func _speak_accessibility_text(text: String, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover(text, hover_source)
	else:
		AudioManager.speak_accessibility(text)
