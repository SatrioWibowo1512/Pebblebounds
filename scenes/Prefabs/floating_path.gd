@tool
class_name FloatingPath
extends Path2D

@export var warna_tengah: Color = Color("e09b69"):
	set(v): warna_tengah = v; _update_colors()

@export_group("Konfigurasi Multi-Layer")
@export var tebal_layer: Array[float] = [30.0, 18.0, 14.0, 4.0]:
	set(v): tebal_layer = v; _rebuild_layers(); _update_visual()
@export var warna_layer: Array[Color] = [Color("c1784c"), Color.BLACK, Color("70c345"), Color.BLACK]:
	set(v): warna_layer = v; _update_colors()

@export_category("Fisika")
@export var offset_collision: float = 0.0
@export var bake_collision: bool = false:
	set(v):
		if v: _bake_collision_polygon()
		bake_collision = false

var _base_poly: Polygon2D
var _lines: Array[Line2D] = []

func _enter_tree():
	if curve and not curve.changed.is_connected(_update_visual):
		curve.changed.connect(_update_visual)
	_rebuild_layers()
	_update_visual()

func _ready():
	_rebuild_layers()
	_update_visual()

func _rebuild_layers():
	if not is_inside_tree(): return
	
	_base_poly = get_node_or_null("BasePolygon") as Polygon2D
	if not _base_poly:
		_base_poly = Polygon2D.new(); _base_poly.name = "BasePolygon"
		_base_poly.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		add_child(_base_poly)
	
	for child in _base_poly.get_children():
		child.queue_free()
	_lines.clear()
	
	var target_size = min(tebal_layer.size(), warna_layer.size())
	for i in range(target_size):
		var l = Line2D.new()
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.closed = true
		_base_poly.add_child(l)
		_lines.append(l)
	
	_update_colors()

func _update_colors():
	if not is_inside_tree() or !_base_poly: return
	_base_poly.color = warna_tengah
	var target_size = min(_lines.size(), warna_layer.size())
	for i in range(target_size):
		_lines[i].default_color = warna_layer[i]

func _update_visual():
	if not is_inside_tree() or not curve or !_base_poly: return
	var pts = curve.get_baked_points()
	if pts.size() < 3: 
		_base_poly.visible = false
		return
	
	_base_poly.visible = true
	_base_poly.polygon = pts
	
	var clean_pts = Array(pts)
	if clean_pts.size() > 1 and clean_pts[0].distance_to(clean_pts[-1]) < 1.0:
		clean_pts.pop_back()
	var pts_garis = PackedVector2Array(clean_pts)
	
	var target_size = min(_lines.size(), tebal_layer.size())
	for i in range(target_size):
		_lines[i].points = pts_garis
		_lines[i].width = tebal_layer[i] * 2.0

func _bake_collision_polygon():
	if not curve or curve.get_baked_points().size() < 3: return
	var pts = curve.tessellate(2, 5.0)

	var body = get_node_or_null("StaticBody2D") as StaticBody2D
	if not body:
		body = StaticBody2D.new(); body.name = "StaticBody2D"; add_child(body)
		body.owner = get_tree().edited_scene_root
		
	var col = body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if not col:
		col = CollisionPolygon2D.new(); col.name = "CollisionPolygon2D"; body.add_child(col)
		col.owner = get_tree().edited_scene_root

	var offset_polys = Geometry2D.offset_polygon(pts, offset_collision, Geometry2D.JOIN_SQUARE)
	if offset_polys.size() > 0:
		col.polygon = offset_polys[0]
