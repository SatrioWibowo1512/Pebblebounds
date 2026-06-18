extends Node2D

@export var smooth_iterations := 3

@onready var poly := $Polygon2D
@onready var collision := $CollisionPolygon2D

func _ready():
	var points = poly.polygon

	for i in smooth_iterations:
		points = chaikin(points)

	poly.polygon = points
	collision.polygon = points


func chaikin(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()

	if points.size() < 3:
		return points

	for i in points.size():
		var p0 = points[i]
		var p1 = points[(i + 1) % points.size()]

		var q = p0.lerp(p1, 0.25)
		var r = p0.lerp(p1, 0.75)

		result.append(q)
		result.append(r)

	return result
