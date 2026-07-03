extends CanvasLayer

@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")

@onready var music_icon = $MusicIcon # Sesuaikan path jika perlu
@onready var sfx_icon = $SFXIcon     # Sesuaikan path jika perlu

func _ready():
	get_tree().paused = true
	
	music_icon.button_pressed = AudioServer.is_bus_mute(music_bus)
	music_icon.modulate = Color(1, 1, 1, 0.5) if music_icon.button_pressed else Color(1, 1, 1, 1)
	
	sfx_icon.button_pressed = AudioServer.is_bus_mute(sfx_bus)
	sfx_icon.modulate = Color(1, 1, 1, 0.5) if sfx_icon.button_pressed else Color(1, 1, 1, 1)

func resume_game() -> void:
	get_tree().paused = false
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		resume_game()
	elif event is InputEventScreenTouch and event.pressed:
		resume_game()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.player_position
	SceneManager.load_scene("res://main_menu.tscn")
	DialogManager.end_dialog()

func _on_music_icon_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(music_bus, toggled_on)
	music_icon.modulate = Color(1, 1, 1, 0.5) if toggled_on else Color(1, 1, 1, 1)

func _on_sfx_icon_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(sfx_bus, toggled_on)
	sfx_icon.modulate = Color(1, 1, 1, 0.5) if toggled_on else Color(1, 1, 1, 1)
