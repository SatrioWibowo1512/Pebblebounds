extends Node

const SAVE_PATH = "user://save.json"

var player_position: Vector2 = Vector2.ZERO
var animation_triggered: bool = false
var boss1_defeated: bool = false
var boss2_defeated: bool = false
var dialog_states: Dictionary = {}

var jump_count: int = 0
var play_time: float = 0.0

func _ready():
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)
	get_tree().set_auto_accept_quit(false)
	
func _process(delta: float) -> void:
	play_time += delta # Menambah waktu otomatis setiap frame

func get_formatted_time() -> String:
	var total_seconds: int = int(play_time)
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
		
func set_dialog_triggered(dialog_id: String):
	dialog_states[dialog_id] = true

func is_dialog_triggered(dialog_id: String) -> bool:
	return dialog_states.get(dialog_id, false)

func save_game():
	var data = {
		"pos_x": player_position.x, "pos_y": player_position.y,
		"anim": animation_triggered, "b1": boss1_defeated, 
		"b2": boss2_defeated, "dialog": dialog_states,
		"jump": jump_count, "time": play_time
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	if data:
		player_position = Vector2(data["pos_x"], data["pos_y"])
		animation_triggered = data["anim"]
		boss1_defeated = data["b1"]
		boss2_defeated = data["b2"]
		dialog_states = data["dialog"]
		jump_count = data.get("jump", 0)
		play_time = data.get("time", 0.0)
		return true
	return false

func reset_data():
	player_position = Vector2.ZERO
	animation_triggered = false
	boss1_defeated = false
	boss2_defeated = false
	dialog_states.clear()
	jump_count = 0
	play_time = 0.0
