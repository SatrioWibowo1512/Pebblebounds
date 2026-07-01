extends RigidBody2D

signal drag_updated(start_pos: Vector2, current_pos: Vector2, drag_vector: Vector2)
signal drag_ended
signal jumped(impulse: Vector2)

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0
@export var spin_power: float = 10.0
@export var air_control_power: float = 3000.0

var can_jump: bool = false
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	can_jump = linear_velocity.length() <= stop_threshold
	
	if not can_jump:
		var spin_dir := Input.get_axis("ui_left", "ui_right")
		if spin_dir != 0:
			apply_torque(spin_dir * air_control_power)

func _process(_delta: float) -> void:
	if is_dragging and can_jump:
		var current_mouse := get_global_mouse_position()
		var drag_vector := (drag_start - current_mouse).limit_length(max_drag)
		drag_updated.emit(drag_start, current_mouse, drag_vector)
	else:
		drag_ended.emit()

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
			apply_jump_impulse(drag_vector * power_multiplier)

func apply_jump_impulse(impulse: Vector2) -> void:
	if can_jump:
		apply_central_impulse(impulse)
		apply_torque_impulse(impulse.x * spin_power)
		jumped.emit(impulse)
