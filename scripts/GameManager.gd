extends Node

var player_position: Vector3 = Vector3.ZERO 
var animation_triggered: bool = false
var boss1_defeated: bool = false
var boss2_defeated: bool = false

var dialog_states: Dictionary = {}

func set_dialog_triggered(dialog_id: String):
	dialog_states[dialog_id] = true

func is_dialog_triggered(dialog_id: String) -> bool:
	return dialog_states.has(dialog_id) and dialog_states[dialog_id] == true
