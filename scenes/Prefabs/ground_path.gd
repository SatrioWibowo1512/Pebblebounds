@tool
extends Path2D

@export var kedalaman_tanah: float = 200.0:
	set(v): kedalaman_tanah = v; _update_visual()

@export_group("Warna Elemen")
@export var warna_outline: Color = Color.BLACK: 
	set(v): warna_outline = v; _update_visual()
@export var warna_rumput: Color = Color("70c345"): 
	set(v): warna_rumput = v; _update_visual()
@export var warna_tanah_gelap: Color = Color("c1784c"): 
	set(v): warna_tanah_gelap = v; _update_visual()
@export var warna_tanah_terang: Color = Color("e09b69"): 
	set(v): warna_tanah_terang = v; _update_visual()

@export_group("Ketebalan Elemen")
@export var tebal_outline: float = 40.0: 
	set(v): tebal_outline = v; _update_visual()
@export var tebal_rumput: float = 30.0: 
	set(v): tebal_rumput = v; _update_visual()
@export var tebal_tanah_gelap: float = 20.0: 
	set(v): tebal_tanah_gelap = v; _update_visual()

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
	var poly_pts = Array(pts)
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	
	var poly = Polygon2D.new()
	poly.polygon = poly_pts; poly.color = warna_tanah_terang
	poly.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(poly); _nodes_visual.append(poly)

	var l_shadow = Line2D.new()
	l_shadow.points = pts
	l_shadow.width = tebal_outline + (tebal_tanah_gelap * 2.0)
	l_shadow.default_color = warna_tanah_gelap
	l_shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	poly.add_child(l_shadow)

	_buat_garis(pts, tebal_outline, warna_outline)
	_buat_garis(pts, tebal_rumput, warna_rumput)

func _buat_garis(pts: PackedVector2Array, tebal: float, warna: Color):
	var l = Line2D.new()
	l.points = pts; l.width = tebal; l.default_color = warna
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(l); _nodes_visual.append(l)

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

	var poly_pts = Array(pts)
	# Koreksi posisi atas collision mengikuti tebal outline + manual offset
	for i in range(poly_pts.size()):
		poly_pts[i].y -= (tebal_outline / 2.0) + offset_collision
		
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	col.polygon = PackedVector2Array(poly_pts)
