extends RigidBody2D

@export var power_multiplier: float = 10.0
@export var max_drag: float = 150.0
@export var stop_threshold: float = 5.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
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
			apply_central_impulse(drag_vector * power_multiplier)
