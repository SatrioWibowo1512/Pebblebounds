extends Node2D

@onready var jump_made: Label = $Group114/JumpMade
@onready var time_label: Label = $Group114/TimeLabel

func update_data() -> void:
	jump_made.text = str(GameManager.jump_count)
	time_label.text = str(GameManager.get_formatted_time())

func change_to_main_menu():
	SceneManager.load_scene("res://main_menu.tscn", 5)
