extends RigidBody2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0
@export var spin_power: float = 10.0
@export var air_control_power: float = 3000.0 # Kekuatan rotasi di udara

@export var can_jump: bool = false

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

@onready var jump_indicator: Line2D = $JumpIndicator
@onready var drag_indicator: Line2D = $DragIndicator
@onready var jump_audio: AudioStreamPlayer2D = $JumpAudio
@onready var hit_audio: AudioStreamPlayer2D = $HitAudio

func _ready() -> void:
	if name == str(multiplayer.get_unique_id()):
		$Camera2D.enabled = true
		$Camera2D.make_current() # Paksa fokus ke kamera ini
		$AudioListener2D.make_current()
	else:
		$Camera2D.enabled = false # Matikan kamera milik player lain
		
	$Polygon2D.color = Color(randf(), randf(), randf(), 1.0)
	clear_indicators()
	
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		can_jump = linear_velocity.length() <= stop_threshold

	# Kontrol udara (diproses lokal, dikirim ke server)
	if name == str(multiplayer.get_unique_id()) and not can_jump:
		var spin_dir := Input.get_axis("ui_left", "ui_right")
		if spin_dir != 0:
			apply_air_spin_server.rpc_id(1, spin_dir)

func _process(_delta: float) -> void:
	if name != str(multiplayer.get_unique_id()):
		return
		
	if is_dragging and can_jump:
		update_indicators()
	else:
		clear_indicators()

func _input(event: InputEvent) -> void:
	if name != str(multiplayer.get_unique_id()):
		return

	if not can_jump:
		is_dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start = get_global_mouse_position()
		elif is_dragging:
			is_dragging = false
			var drag_end := get_global_mouse_position()
			var drag_vector := (drag_start - drag_end).limit_length(max_drag)
			apply_impulse_server.rpc_id(1, drag_vector * power_multiplier)

func update_indicators() -> void:
	var current_mouse := get_global_mouse_position()
	var drag_vector := (drag_start - current_mouse).limit_length(max_drag)
	var corrected_jump_vector := drag_vector.rotated(-global_rotation)
	
	jump_indicator.clear_points()
	jump_indicator.add_point(Vector2.ZERO)
	jump_indicator.add_point(corrected_jump_vector)
	
	drag_indicator.clear_points()
	drag_indicator.add_point(to_local(drag_start))
	drag_indicator.add_point(to_local(current_mouse))
	
func clear_indicators() -> void:
	if jump_indicator: jump_indicator.clear_points()
	if drag_indicator: drag_indicator.clear_points()

@rpc("any_peer", "call_local", "reliable")
func apply_impulse_server(impulse: Vector2) -> void:
	if multiplayer.is_server() and can_jump:
		apply_central_impulse(impulse)
		apply_torque_impulse(impulse.x * spin_power)
		
		var power_ratio := impulse.length() / (max_drag * power_multiplier)
		play_jump_audio.rpc(power_ratio)

@rpc("any_peer", "call_local", "unreliable")
func apply_air_spin_server(dir: float) -> void:
	if multiplayer.is_server() and not can_jump:
		apply_torque(dir * air_control_power)

@rpc("call_local", "reliable")
func play_jump_audio(power_ratio: float) -> void:
	jump_audio.pitch_scale = 1.0 + randf_range(-0.1, 0.1) + (power_ratio * 0.3)
	jump_audio.play()

func _on_body_entered(_body: Node) -> void:
	if multiplayer.is_server():
		var impact_speed := linear_velocity.length()
		if impact_speed > 30.0:
			var speed_ratio := clampf(impact_speed / 500.0, 0.0, 1.0)
			play_hit_audio.rpc(speed_ratio)

@rpc("call_local", "reliable")
func play_hit_audio(speed_ratio: float) -> void:
	hit_audio.pitch_scale = 0.8 + randf_range(-0.1, 0.1) + (speed_ratio * 0.4)
	hit_audio.play()
