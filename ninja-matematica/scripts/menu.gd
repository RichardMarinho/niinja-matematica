extends Node2D

@onready var play_button: Button = $HUD/Root/PlayButton
@onready var options_button: Button = $HUD/Root/OptionsButton
@onready var quit_button: Button = $HUD/Root/QuitButton


func _ready() -> void:
	SceneFlow.entered_menu()
	play_button.pressed.connect(_open_preparation)
	options_button.pressed.connect(_open_options)
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
