extends RigidBody2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	
	$Camera2D.enabled = name == str(multiplayer.get_unique_id())
	$Polygon2D.color = Color(
	randf(),
	randf(),
	randf(),
	1.0
)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		linear_velocity = Vector2(0,0)
	# Hanya izinkan input jika ini adalah batu kita sendiri
	if name != str(multiplayer.get_unique_id()):
		return

	if linear_velocity.length() > stop_threshold:
		is_dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start = get_global_mouse_position()
		elif is_dragging:
			is_dragging = false
			var drag_end = get_global_mouse_position()
			var drag_vector = (drag_start - drag_end).limit_length(max_drag)
			
			# Minta Host (Server dengan ID 1) untuk memberikan dorongan fisika
			apply_impulse_server.rpc_id(1, drag_vector * power_multiplier)

# Fungsi ini hanya akan dijalankan di komputer Host
@rpc("any_peer", "call_local", "reliable")
func apply_impulse_server(impulse: Vector2) -> void:
	if multiplayer.is_server():
		apply_central_impulse(impulse)
