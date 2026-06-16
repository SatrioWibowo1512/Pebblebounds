extends Node2D

@export var player_scene: PackedScene
@export var ip_edit: LineEdit

var peer := ENetMultiplayerPeer.new()

const PORT := 8910

@onready var ip_label: Label = $IPLabel

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	ip_label.text = "IP Lokal: " + get_local_ip()

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.contains(".") and not ip.begins_with("127."):
			return ip
	return "Tidak ditemukan"

func setup_upnp() -> String:
	var upnp := UPNP.new()

	print("Mencari router UPnP...")

	var discover_result := upnp.discover()

	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP discover gagal: ", discover_result)
		return ""

	var gateway = upnp.get_gateway()

	if gateway == null:
		print("Gateway UPnP tidak ditemukan")
		return ""

	print("Gateway ditemukan")

	var map_result := upnp.add_port_mapping(PORT)

	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("Port mapping gagal: ", map_result)
		return ""

	var external_ip := upnp.query_external_address()

	print("IP Publik: ", external_ip)

	return external_ip

func _on_host_button_pressed() -> void:
	print("HOST BUTTON PRESSED")

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()

	peer = ENetMultiplayerPeer.new()

	var err := peer.create_server(PORT)

	print("create_server result: ", err)

	if err != OK:
		ip_label.text = "Gagal membuat server"
		return

	multiplayer.multiplayer_peer = peer

	add_player(multiplayer.get_unique_id())

	var public_ip := setup_upnp()

	if public_ip != "":
		ip_label.text = "HOST ONLINE\nIP: %s\nPORT: %d" % [public_ip, PORT]
	else:
		ip_label.text = "HOST LAN\nIP: %s\nPORT: %d" % [get_local_ip(), PORT]

	print("SERVER STARTED")

func _on_join_button_pressed() -> void:
	print("JOIN BUTTON PRESSED")

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()

	peer = ENetMultiplayerPeer.new()

	var target_ip := ip_edit.text.strip_edges()

	if target_ip == "":
		ip_label.text = "Masukkan IP"
		return

	var err := peer.create_client(target_ip, PORT)

	print("create_client result: ", err)

	if err != OK:
		ip_label.text = "Gagal connect"
		return

	multiplayer.multiplayer_peer = peer

	ip_label.text = "Menghubungkan ke %s..." % target_ip

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)

	if multiplayer.is_server():
		add_player(id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)

	if $Players.has_node(str(id)):
		$Players.get_node(str(id)).queue_free()

func add_player(id: int) -> void:
	if player_scene == null:
		push_error("Player scene belum diisi")
		return

	if $Players.has_node(str(id)):
		return

	var player = player_scene.instantiate()
	player.name = str(id)

	$Players.add_child(player)

	print("Player added: ", id)
