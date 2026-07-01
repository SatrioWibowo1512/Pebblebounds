@tool
class_name GroundPath
extends Path2D

@export var kedalaman_tanah: float = 1000.0:
	set(v): kedalaman_tanah = v; _update_visual()

@export_group("Warna Elemen")
@export var warna_outline: Color = Color.BLACK: 
	set(v): warna_outline = v; _update_properties()
@export var warna_rumput: Color = Color("70c345"): 
	set(v): warna_rumput = v; _update_properties()
@export var warna_tanah_gelap: Color = Color("c1784c"): 
	set(v): warna_tanah_gelap = v; _update_properties()
@export var warna_tanah_terang: Color = Color("e09b69"): 
	set(v): warna_tanah_terang = v; _update_properties()

@export_group("Ketebalan Elemen")
@export var tebal_outline: float = 17.0: 
	set(v): tebal_outline = v; _update_properties(); _update_visual()
@export var tebal_rumput: float = 10.0: 
	set(v): tebal_rumput = v; _update_properties(); _update_visual()
@export var tebal_tanah_gelap: float = 10.0: 
	set(v): tebal_tanah_gelap = v; _update_properties(); _update_visual()

@export_category("Fisika")
@export var offset_collision: float = 0.0
@export var bake_collision: bool = false:
	set(v):
		if v: _bake_collision_polygon()
		bake_collision = false

var _base_poly: Polygon2D
var _l_shadow: Line2D
var _l_outline: Line2D
var _l_rumput: Line2D

func _enter_tree():
	if curve and not curve.changed.is_connected(_update_visual):
		curve.changed.connect(_update_visual)
	_setup_nodes()
	_update_visual()

func _ready():
	_setup_nodes()
	_update_visual()

func _setup_nodes():
	if not is_inside_tree(): return
	
	_base_poly = get_node_or_null("BasePolygon") as Polygon2D
	if not _base_poly:
		_base_poly = Polygon2D.new(); _base_poly.name = "BasePolygon"
		_base_poly.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		add_child(_base_poly)
		
	_l_shadow = _base_poly.get_node_or_null("ShadowLine") as Line2D
	if not _l_shadow:
		_l_shadow = Line2D.new(); _l_shadow.name = "ShadowLine"
		_l_shadow.joint_mode = Line2D.LINE_JOINT_ROUND
		_base_poly.add_child(_l_shadow)
		
	_l_outline = get_node_or_null("OutlineLine") as Line2D
	if not _l_outline:
		_l_outline = Line2D.new(); _l_outline.name = "OutlineLine"
		_l_outline.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(_l_outline)
		
	_l_rumput = get_node_or_null("GrassLine") as Line2D
	if not _l_rumput:
		_l_rumput = Line2D.new(); _l_rumput.name = "GrassLine"
		_l_rumput.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(_l_rumput)
		
	_update_properties()

func _update_properties():
	if not is_inside_tree() or !_base_poly: return
	_base_poly.color = warna_tanah_terang
	_l_shadow.default_color = warna_tanah_gelap
	_l_shadow.width = tebal_outline + (tebal_tanah_gelap * 2.0)
	_l_outline.default_color = warna_outline
	_l_outline.width = tebal_outline
	_l_rumput.default_color = warna_rumput
	_l_rumput.width = tebal_rumput

func _update_visual():
	if not is_inside_tree() or not curve or !_base_poly: return
	var pts = curve.get_baked_points()
	if pts.size() < 3:
		_base_poly.visible = false; _l_outline.visible = false; _l_rumput.visible = false
		return
		
	_base_poly.visible = true; _l_outline.visible = true; _l_rumput.visible = true
	
	var poly_pts = Array(pts)
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	
	_base_poly.polygon = PackedVector2Array(poly_pts)
	_l_shadow.points = pts
	_l_outline.points = pts
	_l_rumput.points = pts

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
	for i in range(poly_pts.size()):
		poly_pts[i].y -= (tebal_outline / 2.0) + offset_collision
		
	poly_pts.append(Vector2(pts[-1].x, pts[-1].y + kedalaman_tanah))
	poly_pts.append(Vector2(pts[0].x, pts[0].y + kedalaman_tanah))
	col.polygon = PackedVector2Array(poly_pts)
