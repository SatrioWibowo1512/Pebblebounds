extends Node2D

@export var player: RigidBody2D
@onready var jump_indicator: Line2D = $JumpIndicator
@onready var drag_indicator: Line2D = $DragIndicator

func _ready() -> void:
	if player:
		player.drag_updated.connect(_on_drag_updated)
		player.drag_ended.connect(clear_indicators)

func _on_drag_updated(start_pos: Vector2, current_pos: Vector2, drag_vector: Vector2) -> void:
	jump_indicator.points = PackedVector2Array([Vector2.ZERO, drag_vector.rotated(-player.global_rotation)])
	drag_indicator.points = PackedVector2Array([to_local(start_pos), to_local(current_pos)])
	
func clear_indicators() -> void:
	jump_indicator.clear_points()
	drag_indicator.clear_points()
