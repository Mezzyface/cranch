extends Control

const GAME_SCENE = preload("res://scenes/view/game_scene.tscn")
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton

func _ready():
	# Check if save exists and enable/disable continue button
	if continue_button:
		continue_button.disabled = not SaveManager.has_save_file()

func _on_continue_button_pressed():
	if SaveManager.load_game():
		get_tree().change_scene_to_packed(GAME_SCENE)

func _on_new_game_button_pressed():
	# Your existing start game logic
	get_tree().change_scene_to_packed(GAME_SCENE)
