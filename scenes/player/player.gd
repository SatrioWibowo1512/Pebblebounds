extends RigidBody2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0
@export var spin_power: float = 10.0
@export var air_control_power: float = 3000.0

@export var can_jump: bool = false

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var last_velocity: Vector2 = Vector2.ZERO

@onready var jump_indicator: Line2D = $Indicator/JumpIndicator
@onready var drag_indicator: Line2D = $Indicator/DragIndicator
@onready var jump_audio: AudioStreamPlayer2D = $Audio/JumpAudio
@onready var hit_audio: AudioStreamPlayer2D = $Audio/HitAudio

func _ready() -> void:
	# Di singleplayer, kamera dan audio listener selalu aktif untuk player ini
	$Camera2D.enabled = true
	$Camera2D.make_current()
	$Audio/AudioListener2D.make_current()
		
	$StoneShape.color = Color(randf(), randf(), randf(), 1.0)
	clear_indicators()
	
	contact_monitor = true
	max_contacts_reported = 5 
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# Cek kondisi lompat berdasarkan kecepatan saat ini
	can_jump = linear_velocity.length() <= stop_threshold
	last_velocity = linear_velocity
		
	# Kontrol di udara saat tidak bisa lompat
	if not can_jump:
		var spin_dir := Input.get_axis("ui_left", "ui_right")
		if spin_dir != 0:
			apply_torque(spin_dir * air_control_power)

func _process(_delta: float) -> void:
	if is_dragging and can_jump:
		update_indicators()
	else:
		clear_indicators()

func _input(event: InputEvent) -> void:
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
			
			# Langsung panggil fungsi eksekusi tanpa RPC
			apply_jump_impulse(drag_vector * power_multiplier)

func update_indicators() -> void:
	var current_mouse := get_global_mouse_position()
	var drag_vector := (drag_start - current_mouse).limit_length(max_drag)

	jump_indicator.points = PackedVector2Array([Vector2.ZERO, drag_vector.rotated(-global_rotation)])
	drag_indicator.points = PackedVector2Array([to_local(drag_start), to_local(current_mouse)])
	
func clear_indicators() -> void:
	if jump_indicator: jump_indicator.clear_points()
	if drag_indicator: drag_indicator.clear_points()

# Menggantikan fungsi apply_impulse_server
func apply_jump_impulse(impulse: Vector2) -> void:
	if can_jump:
		apply_central_impulse(impulse)
		apply_torque_impulse(impulse.x * spin_power)
		
		var power_ratio := impulse.length() / (max_drag * power_multiplier)
		play_jump_audio(power_ratio)

func play_jump_audio(power_ratio: float) -> void:
	jump_audio.pitch_scale = 1.0 + randf_range(-0.1, 0.1) + (power_ratio * 0.3)
	jump_audio.play()

func _on_body_entered(_body: Node) -> void:
	var impact_speed := last_velocity.length()
	if impact_speed > 30.0:
		var speed_ratio := clampf(impact_speed / 500.0, 0.0, 1.0)
		play_hit_audio(speed_ratio)

func play_hit_audio(speed_ratio: float) -> void:
	hit_audio.pitch_scale = 0.8 + randf_range(-0.1, 0.1) + (speed_ratio * 0.4)
	hit_audio.play()
