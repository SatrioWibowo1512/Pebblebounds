@tool
extends Path2D

@export var warna_tengah: Color = Color("e09b69"):
	set(v): warna_tengah = v; _update_visual()

@export_group("Konfigurasi Multi-Layer")
@export var tebal_layer: Array[float] = [40.0, 30.0, 20.0]
@export var warna_layer: Array[Color] = [Color.BLACK, Color("70c345"), Color("c1784c")]

@export_category("Fisika & Performa")
@export var offset_collision: float = 0.0
@export var bake_collision: bool = false:
	set(v):
		if v: _bake_collision_polygon()
		bake_collision = false

var _nodes_visual: Array[Node] = []

func _enter_tree():
	if curve and not curve.changed.is_connected(_update_visual):
		curve.changed.connect(_update_visual)

func _ready():
	_update_visual()

func _update_visual():
	if not is_inside_tree() or not curve or curve.get_baked_points().size() < 3: return
	for n in _nodes_visual: if is_instance_valid(n): n.queue_free()
	_nodes_visual.clear()
	
	var pts = curve.get_baked_points()
	
	# Anti-Bleeding: Gunakan Poly Tengah sebagai Masker utama
	var poly = Polygon2D.new()
	poly.polygon = pts; poly.color = warna_tengah
	poly.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(poly); _nodes_visual.append(poly)
	
	var clean_pts = Array(pts)
	if clean_pts.size() > 1 and clean_pts[0].distance_to(clean_pts[-1]) < 1.0:
		clean_pts.pop_back()
	var pts_garis = PackedVector2Array(clean_pts)

	var size = min(tebal_layer.size(), warna_layer.size())
	for i in range(size):
		# Dikali 2 karena separuh garis luar terpotong oleh clipping mask
		_buat_garis_layer(poly, pts_garis, tebal_layer[i] * 2.0, warna_layer[i])

func _buat_garis_layer(parent: Node, pts: PackedVector2Array, tebal: float, warna: Color):
	var l = Line2D.new()
	l.points = pts; l.width = tebal; l.default_color = warna
	l.joint_mode = Line2D.LINE_JOINT_ROUND; l.closed = true
	parent.add_child(l)

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

	# Mengembang/mengempis secara akurat berdasarkan nilai offset manual
	var offset_polys = Geometry2D.offset_polygon(pts, offset_collision, Geometry2D.JOIN_SQUARE)
	if offset_polys.size() > 0:
		col.polygon = offset_polys[0]
