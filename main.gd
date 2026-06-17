extends Node2D

@export var player_scene: PackedScene
@export var ip_edit: LineEdit

var peer := ENetMultiplayerPeer.new()
const PORT := 8910

@onready var ip_label: Label = $IPLabel
@onready var players_container: Node = $Players

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	ip_label.text = "IP Lokal: " + get_local_ip()

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.contains(".") and not ip.begins_with("127."):
			return ip
	return "Tidak ditemukan"

# Berjalan di background thread
func setup_upnp() -> void:
	var upnp := UPNP.new()
	var discover_result := upnp.discover()

	if discover_result != UPNP.UPNP_RESULT_SUCCESS or upnp.get_gateway() == null:
		call_deferred("_update_ui_upnp_failed")
		return

	var map_result := upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		call_deferred("_update_ui_upnp_failed")
		return

	var external_ip := upnp.query_external_address()
	call_deferred("_update_ui_upnp_success", external_ip)

func _update_ui_upnp_failed() -> void:
	ip_label.text = "HOST LAN\nIP: %s\nPORT: %d" % [get_local_ip(), PORT]

func _update_ui_upnp_success(public_ip: String) -> void:
	ip_label.text = "HOST ONLINE\nIP: %s\nPORT: %d" % [public_ip, PORT]

func reset_connection() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _on_host_button_pressed() -> void:
	reset_connection()
	peer = ENetMultiplayerPeer.new()
	
	var err := peer.create_server(PORT)
	if err != OK:
		ip_label.text = "Gagal membuat server"
		return

	multiplayer.multiplayer_peer = peer
	add_player(multiplayer.get_unique_id())

	ip_label.text = "Menyiapkan UPnP..."
	
	# Menjalankan UPnP tanpa memblokir game (Solusi Delay)
	WorkerThreadPool.add_task(setup_upnp)

func _on_join_button_pressed() -> void:
	reset_connection()
	peer = ENetMultiplayerPeer.new()

	var target_ip := ip_edit.text.strip_edges()
	if target_ip.is_empty():
		ip_label.text = "Masukkan IP"
		return

	var err := peer.create_client(target_ip, PORT)
	if err != OK:
		ip_label.text = "Gagal connect"
		return

	multiplayer.multiplayer_peer = peer
	ip_label.text = "Menghubungkan ke %s..." % target_ip

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		add_player(id)

func _on_peer_disconnected(id: int) -> void:
	var node_name := str(id)
	if players_container.has_node(node_name):
		players_container.get_node(node_name).queue_free()

func add_player(id: int) -> void:
	if player_scene == null:
		push_error("Player scene belum diisi")
		return

	var node_name := str(id)
	if players_container.has_node(node_name):
		return

	var player := player_scene.instantiate()
	player.name = node_name
	players_container.add_child(player)
