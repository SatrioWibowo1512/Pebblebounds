extends RigidBody2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0
@export var can_jump: bool = false # Properti baru untuk disinkronisasi
@export var spin_power: float = 10.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

@onready var indicator: Line2D = $Line2D

func _ready() -> void:
	$Camera2D.enabled = name == str(multiplayer.get_unique_id())
	$Polygon2D.color = Color(randf(), randf(), randf(), 1.0)
	if indicator:
		indicator.clear_points()

func _physics_process(_delta: float) -> void:
	# Hanya Host yang punya otoritas fisika untuk menentukan batu sudah diam
	if multiplayer.is_server():
		can_jump = linear_velocity.length() <= stop_threshold

func _process(_delta: float) -> void:
	if name != str(multiplayer.get_unique_id()):
		return
		
	if is_dragging and can_jump:
		update_indicator()
	elif indicator and indicator.get_point_count() > 0:
		indicator.clear_points()

func _input(event: InputEvent) -> void:
	if name != str(multiplayer.get_unique_id()):
		return

	# Cek variabel can_jump dari server, bukan linear_velocity lokal
	if not can_jump:
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
			apply_impulse_server.rpc_id(1, drag_vector * power_multiplier)

func update_indicator() -> void:
	if not indicator: 
		return
	indicator.clear_points()
	
	var target_pos = get_local_mouse_position().limit_length(max_drag)
	
	indicator.add_point(Vector2.ZERO)
	indicator.add_point(target_pos)

@rpc("any_peer", "call_local", "reliable")
func apply_impulse_server(impulse: Vector2) -> void:
	if multiplayer.is_server() and can_jump:
		apply_central_impulse(impulse)
		apply_torque_impulse(impulse.x * spin_power) # Menambahkan rotasi searah lompatan
