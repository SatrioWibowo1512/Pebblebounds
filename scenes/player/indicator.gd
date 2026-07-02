extends Node2D

@export var player: RigidBody2D
@export var max_drag_distance: float = 150.0
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 6.0

@onready var jump_indicator: Line2D = $JumpIndicator
@onready var drag_indicator: Line2D = $DragIndicator

var jump_outline: Line2D
var drag_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func _ready() -> void:
	if player:
		player.drag_updated.connect(_on_drag_updated)
		player.drag_ended.connect(clear_indicators)
	
	_setup_stylized_lines()

func _setup_stylized_lines() -> void:
	jump_indicator.width = 20.0
	jump_indicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	jump_indicator.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0)) 
	curve.add_point(Vector2(1.0, 0.2)) 
	jump_indicator.width_curve = curve
	
	# Membuat outline secara otomatis
	jump_outline = jump_indicator.duplicate()
	jump_outline.default_color = outline_color
	jump_outline.width = jump_indicator.width + outline_width
	add_child(jump_outline)
	move_child(jump_outline, jump_indicator.get_index()) # Posisikan di belakang indikator utama

func _on_drag_updated(start_pos: Vector2, current_pos: Vector2, drag_vector: Vector2) -> void:
	is_dragging = true
	drag_start_pos = to_local(start_pos)
	
	# Membatasi drag indicator
	var local_current = to_local(current_pos)
	var offset = local_current - drag_start_pos
	var current_drag_pos = drag_start_pos + offset.limit_length(max_drag_distance)
	
	drag_indicator.points = PackedVector2Array([drag_start_pos, current_drag_pos])
	
	# Membatasi jump indicator
	var clamped_jump = drag_vector.limit_length(max_drag_distance)
	var jump_points = PackedVector2Array([Vector2.ZERO, clamped_jump.rotated(-player.global_rotation)])
	
	jump_indicator.points = jump_points
	jump_outline.points = jump_points # Menyamakan titik outline dengan indikator utama
	
	queue_redraw()

func clear_indicators() -> void:
	is_dragging = false
	
	if is_instance_valid(jump_indicator):
		jump_indicator.clear_points()
	if is_instance_valid(jump_outline):
		jump_outline.clear_points()
	if is_instance_valid(drag_indicator):
		drag_indicator.clear_points()
		
	queue_redraw()

func _draw() -> void:
	if is_dragging:
		# Hanya menggambar lingkaran batas transparan
		draw_arc(drag_start_pos, max_drag_distance, 0, TAU, 64, Color(1, 1, 1, 0.4), 2.0, true)
