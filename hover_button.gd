extends TextureButton

@onready var audio_player = $"../../Button"

func _ready():
	pivot_offset = size / 2.0 
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

func _on_hover():
	create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	if audio_player and audio_player.stream:
		audio_player.play()

func _on_exit():
	create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_pressed() -> void:
	SceneManager.load_scene("res://scenes/levels/game_arena.tscn", 1.0) # Replace with function body.
