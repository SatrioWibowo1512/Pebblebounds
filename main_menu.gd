extends Control

@onready var btn_continue = $HBoxContainer/ContinueButton
@onready var music_icon: TextureButton = $MusicIcon
@onready var sfx_icon: TextureButton = $SFXIcon

@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")

func _ready():
	btn_continue.disabled = not FileAccess.file_exists(GameManager.SAVE_PATH)
	btn_continue.modulate = Color(1, 1, 1, 0.5) if btn_continue.disabled else Color(1, 1, 1, 1)
	
	# Set status tombol sesuai kondisi audio saat ini
	music_icon.button_pressed = AudioServer.is_bus_mute(music_bus)
	sfx_icon.button_pressed = AudioServer.is_bus_mute(sfx_bus)

func _on_continue_button_pressed() -> void:
	if GameManager.load_game():
		SceneManager.load_scene("res://scenes/levels/game_arena.tscn") 

func _on_new_game_button_pressed() -> void:
	GameManager.reset_data() 
	SceneManager.load_scene("res://scenes/levels/game_arena.tscn")

func _on_music_icon_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(music_bus, toggled_on)
	music_icon.modulate = Color(1, 1, 1, 0.5) if toggled_on else Color(1, 1, 1, 1)

func _on_sfx_icon_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(sfx_bus, toggled_on)
	sfx_icon.modulate = Color(1, 1, 1, 0.5) if toggled_on else Color(1, 1, 1, 1)
