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

var can_jump: bool = false
var is_dragging: bool = false
var drag_start_viewport: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	can_jump = linear_velocity.length() <= stop_threshold
	
	if not can_jump:
		var spin_dir := Input.get_axis("ui_left", "ui_right")
		if spin_dir != 0:
			apply_torque(spin_dir * air_control_power)

func _process(delta: float) -> void:
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
