extends Node2D

@export var player_scene: PackedScene
@export var ip_edit: LineEdit

var peer = ENetMultiplayerPeer.new()
const PORT = 8910

func _on_host_button_pressed() -> void:
	var err = peer.create_server(PORT)
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())
	$CanvasLayer.hide()

func _on_join_button_pressed() -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()
	var target_ip = "127.0.0.1"
	if ip_edit and ip_edit.text != "":
		target_ip = ip_edit.text
	var err = peer.create_client(target_ip, PORT)
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()

func add_player(id: int) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	$Players.add_child(player)
