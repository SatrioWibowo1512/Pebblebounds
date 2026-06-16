extends Node2D

@export var player_scene: PackedScene
@export var ip_edit: LineEdit

var peer = ENetMultiplayerPeer.new()
const PORT = 8910
	
func add_player(id: int) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	add_child(player)
	
func _on_host_button_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed() -> void:
	var target_ip = "127.0.0.1"
	if ip_edit and ip_edit.text != "":
		target_ip = ip_edit.text
	peer.create_client(target_ip,PORT)
	multiplayer.multiplayer_peer = peer
