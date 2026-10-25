extends Node2D

@onready var play_button: Button = $HUD/Root/PlayButton
@onready var options_button: Button = $HUD/Root/OptionsButton
@onready var quit_button: Button = $HUD/Root/QuitButton


func _ready() -> void:
	SceneFlow.entered_menu()
	play_button.pressed.connect(_open_preparation)
	play_button.mouse_entered.connect(_speak_accessibility_text.bind("Jogar. Botão para começar o jogo.", play_button))
	play_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(play_button))
	play_button.focus_entered.connect(_speak_accessibility_text.bind("Jogar. Botão para começar o jogo."))
	options_button.pressed.connect(_open_options)
	options_button.mouse_entered.connect(_speak_accessibility_text.bind("Opções.", options_button))
	options_button.mouse_exited.connect(AudioManager.stop_hover_speech.bind(options_button))
	options_button.focus_entered.connect(_speak_accessibility_text.bind("Opções."))
	quit_button.pressed.connect(_quit_game)


func _open_preparation() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/preparation.tscn")


func _open_options() -> void:
	AudioManager.play_ui()
	SceneFlow.change_scene("res://scenes/options.tscn")


func _quit_game() -> void:
	AudioManager.play_ui()
	get_tree().quit()


func _speak_accessibility_text(text: String, hover_source: Object = null) -> void:
	if hover_source != null:
		AudioManager.speak_hover(text, hover_source)
	else:
		AudioManager.speak_accessibility(text)


func _on_background_draw() -> void:
	pass # Replace with function body.
