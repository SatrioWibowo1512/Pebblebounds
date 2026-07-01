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
@export var tebal_outline: float = 17.0: 
	set(v): tebal_outline = v; _update_visual()
@export var tebal_rumput: float = 10.0: 
	set(v): tebal_rumput = v; _update_visual()
@export var tebal_tanah_gelap: float = 10.0: 
	set(v): tebal_tanah_gelap = v; _update_visual()

@export_category("Optimasi Fisika")
@export_range(1, 5) var max_stages: int = 2
@export var toleransi_sudut: float = 5.0
@export var bake_collision: bool = false:
	set(v):
		if v: _bake_collision_polygon()
		bake_collision = false

var _last_pts: PackedVector2Array
var _nodes_visual: Array[Node] = []

func _process(_delta):
	if Engine.is_editor_hint() and curve:
		var current_pts = curve.get_baked_points()
		if current_pts != _last_pts:
			_update_visual()
			_last_pts = current_pts.duplicate()

func  _ready():
	_update_visual()

func _update_visual():
	if not is_inside_tree() or not curve or curve.get_baked_points().size() < 3: return
	for n in _nodes_visual: if is_instance_valid(n): n.queue_free()
	_nodes_visual.clear()
	
	var pts = curve.get_baked_points()
	var poly_pts = Array(pts)
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	
	# 1. Base Ground (Polygon)
	var poly = Polygon2D.new()
	poly.polygon = poly_pts
	poly.color = warna_tanah_terang
	# [PENTING] Mengaktifkan Masking. Semua child dari polygon ini 
	# yang melewati batas atas (langit) akan dipotong/disembunyikan!
	poly.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(poly); _nodes_visual.append(poly)

	# 2. Shadow Tanah Gelap (Inner Stroke)
	# Kita buat jauh lebih tebal, dan dimasukkan sebagai child dari polygon
	var l_shadow = Line2D.new()
	l_shadow.points = pts
	# Hitungan otomatis agar ketebalan bayangan pas dengan input Inspector
	l_shadow.width = tebal_outline + (tebal_tanah_gelap * 2.0) 
	l_shadow.default_color = warna_tanah_gelap
	l_shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	poly.add_child(l_shadow) 

	# 3. Outline & Rumput
	# Dirender normal tanpa masking di paling depan untuk menutupi potongan
	_buat_garis(pts, tebal_outline, warna_outline)
	_buat_garis(pts, tebal_rumput, warna_rumput)

func _buat_garis(pts: PackedVector2Array, tebal: float, warna: Color):
	var l = Line2D.new()
	l.points = pts; l.width = tebal; l.default_color = warna
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(l); _nodes_visual.append(l)

func _bake_collision_polygon():
	if not curve or curve.get_baked_points().size() < 3: return
	
	var pts = curve.tessellate(max_stages, toleransi_sudut)
	
	var body = get_node_or_null("StaticBody2D")
	if not body:
		body = StaticBody2D.new(); body.name = "StaticBody2D"; add_child(body)
		body.owner = get_tree().edited_scene_root
		
	var col = body.get_node_or_null("CollisionPolygon2D")
	if not col:
		col = CollisionPolygon2D.new(); col.name = "CollisionPolygon2D"; body.add_child(col)
		col.owner = get_tree().edited_scene_root

	var poly_pts = Array(pts)
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	col.polygon = poly_pts
	
