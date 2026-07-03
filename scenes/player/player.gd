extends RigidBody2D

signal drag_updated(start_pos: Vector2, current_pos: Vector2, drag_vector: Vector2)
signal drag_ended
signal jumped(impulse: Vector2)

@onready var camera_2d: Camera2D = $Camera2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0
@export var spin_power: float = 10.0
@export var air_control_power: float = 3000.0

@export var base_cam_zoom: float = 1.0       
@export var min_cam_zoom: float = 0.8        
@export var max_cam_offset: float = 80.0     
@export var cam_smooth_speed: float = 8.0    

@onready var jump_audio: AudioStreamPlayer2D = $JumpAudio
@onready var hit_audio: AudioStreamPlayer2D = $HitAudio

# --- VARIABEL TAMBAHAN UNTUK DIALOG ---
@export var little_fall_dist: float = 300.0 # Jarak jatuh kecil
@export var big_fall_dist: float = 800.0    # Jarak jatuh jauh

var can_jump: bool = false
var is_dragging: bool = false
var drag_start_viewport: Vector2 = Vector2.ZERO

var dialog_timer: float = 0.0
var fall_start_y: float = 0.0
var was_can_jump: bool = true

func _ready() -> void:
	fall_start_y = global_position.y
	if big_fall_dist == null: big_fall_dist = 800.0
	if little_fall_dist == null: little_fall_dist = 300.0
	
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
func _physics_process(_delta: float) -> void:
	can_jump = linear_velocity.length() <= stop_threshold
	GameManager.player_position = global_position
	if can_jump:
		if not was_can_jump:
			var fall_dist = global_position.y - fall_start_y
			if fall_dist >= big_fall_dist:
				trigger_random_dialog("big_fall_", 4)
			elif fall_dist >= little_fall_dist:
				trigger_random_dialog("little_fall_", 4)
		fall_start_y = global_position.y # Reset titik tertinggi saat diam
	else:
		if global_position.y < fall_start_y:
			fall_start_y = global_position.y # Update titik tertinggi (Y semakin kecil = semakin tinggi)
	
	was_can_jump = can_jump

	if not can_jump:
		var spin_dir := Input.get_axis("ui_left", "ui_right")
		if spin_dir != 0:
			apply_torque(spin_dir * air_control_power)

func _process(delta: float) -> void:
	# --- TIMER DIALOG 30 DETIK ---
	dialog_timer += delta
	if dialog_timer >= 30.0:
		dialog_timer = 0.0
		trigger_random_dialog("dialog_climbing_", 4)
	# -----------------------------
	if is_dragging and can_jump:
		var current_viewport := get_viewport().get_mouse_position()
		var drag_vector := (drag_start_viewport - current_viewport).limit_length(max_drag)
		
		drag_updated.emit(drag_start_viewport, current_viewport, drag_vector)
		
		var drag_ratio = drag_vector.length() / max_drag
		var target_offset = drag_vector.normalized() * (drag_ratio * max_cam_offset)
		camera_2d.offset = camera_2d.offset.lerp(target_offset, cam_smooth_speed * delta)
		
		var target_zoom = lerp(base_cam_zoom, min_cam_zoom, drag_ratio)
		camera_2d.zoom = camera_2d.zoom.lerp(Vector2(target_zoom, target_zoom), cam_smooth_speed * delta)
	else:
		drag_ended.emit()
		if is_instance_valid(camera_2d):
			camera_2d.offset = camera_2d.offset.lerp(Vector2.ZERO, cam_smooth_speed * delta)
			camera_2d.zoom = camera_2d.zoom.lerp(Vector2(base_cam_zoom, base_cam_zoom), cam_smooth_speed * delta)

func _input(event: InputEvent) -> void:
	if not can_jump:
		is_dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_viewport = get_viewport().get_mouse_position()
		elif is_dragging:
			is_dragging = false
			var current_viewport := get_viewport().get_mouse_position()
			var drag_vector := (drag_start_viewport - current_viewport).limit_length(max_drag)
			apply_jump_impulse(drag_vector * power_multiplier)

func apply_jump_impulse(impulse: Vector2) -> void:
	if can_jump:
		apply_central_impulse(impulse)
		apply_torque_impulse(impulse.x * spin_power)
		jumped.emit(impulse)
		dialog_timer = 0.0
		GameManager.jump_count += 1
		var jump_id = randi_range(1, 4)
		jump_audio.stream = load("res://assets/audios/jump%d.mp3" % jump_id) # Ubah .wav sesuai format audio (misal .ogg/.mp3)
		jump_audio.play()
# --- FUNGSI TRIGGER DIALOG RANDOM ---
func trigger_random_dialog(prefix: String, max_num: int) -> void:
	var random_id = prefix + str(randi_range(1, max_num))
	DialogManager.start_dialog_by_id(random_id)
	
func _on_body_entered(_body: Node) -> void:
	# Cek jika kecepatan saat nabrak cukup keras agar tidak spam suara saat diam
	if linear_velocity.length() > 50.0:
		var hit_id = randi_range(1, 5)
		hit_audio.stream = load("res://assets/audios/hit%d.mp3" % hit_id) # Ubah .wav sesuai format
		hit_audio.play()
