extends TextureButton # Ubah ke 'extends Button' jika bukan textured button

@export var pause_menu_scene: PackedScene

func _on_pressed() -> void:
	if pause_menu_scene:
		var pause_menu = pause_menu_scene.instantiate()
		get_tree().current_scene.add_child(pause_menu)
