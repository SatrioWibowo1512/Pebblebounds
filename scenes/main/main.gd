extends Node2D

@export var player_scene: PackedScene

@onready var players_container: Node = $Players

func _ready() -> void:
	# Langsung spawn player saat game dimulai
	spawn_single_player()

func spawn_single_player() -> void:
	if player_scene == null:
		push_error("Player scene belum diisi di Inspector")
		return

	var player := player_scene.instantiate()
	player.name = "Player" # Nama statis untuk singleplayer
	players_container.add_child(player)
