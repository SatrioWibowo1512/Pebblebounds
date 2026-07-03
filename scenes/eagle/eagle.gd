extends CharacterBody2D

signal attack_warning(target_position: Vector2)

enum State { IDLE, PATROL, THINK, POSITIONING, ATTACK, REST, RETURNING, ESCAPE }

# ================= KELOMPOK VARIABEL =================

@export_group("Node References")
@export var patrol_marker: Marker2D
@export var ground_marker: Marker2D

@export_group("Stats & Movement")
@export var hp: int = 3
@export var base_speed: float = 100.0
@export var attack_speed: float = 350.0
@export var patrol_distance: float = 200.0
@export var y_tolerance: float = 80.0
@export var detection_range_x: float = 450.0

@export_group("Combat Forces")
@export var knockback_force: float = 600.0
@export var shockwave_radius: float = 200.0 
@export var shockwave_force: float = 500.0  

var current_state: State = State.IDLE
var patrol_dir: int = 1
var attack_type: int = 1 
var attack_dir: Vector2 = Vector2.ZERO
var target_positioning_x: float = 0.0 
var can_take_damage: bool = false
var player_ref: RigidBody2D

@onready var visual = $Visual
@onready var sprite = $Visual/AnimatedSprite2D
@onready var timer = $Timer
@onready var hurtbox = $HurtBox

# ================= SIKLUS UTAMA =================

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	change_state(State.IDLE)
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		change_state(State.PATROL)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.PATROL:
			_handle_patrol()
			_check_player_detection()
		State.POSITIONING:
			_handle_positioning()
		State.ATTACK:
			_handle_attack()
		State.RETURNING:
			_handle_returning()
		State.ESCAPE:
			_handle_escape()
	
	move_and_slide()
	if current_state == State.ATTACK:
		_check_collisions()

# ================= STATE MACHINE =================

func change_state(new_state: State) -> void:
	current_state = new_state
	can_take_damage = false
	hurtbox.set_deferred("monitoring", false)
	_toggle_collisions(new_state)
	
	match current_state:
		State.IDLE:
			sprite.play("Idle")
			velocity = Vector2.ZERO
		State.PATROL, State.RETURNING:
			sprite.play("Fly")
		State.THINK:
			sprite.play("Idle")
			velocity = Vector2.ZERO
			_pikir_dan_pilih_serangan()
		State.POSITIONING:
			sprite.play("Fly")
		State.ATTACK:
			sprite.play("Attack1" if attack_type == 1 else "Attack2")
		State.REST:
			sprite.play("Rest")
			velocity = Vector2.ZERO
			if ground_marker: global_position.y = ground_marker.global_position.y
			
			hurtbox.set_deferred("monitoring", true) 
			can_take_damage = true 
			timer.start(2.5) 
		State.ESCAPE:
			sprite.play("Fly")
			# Hapus node setelah 5 detik terbang kabur agar tidak bocor memori
			get_tree().create_timer(5.0).timeout.connect(queue_free)

# ================= LOGIKA PERGERAKAN =================

func _handle_patrol() -> void:
	if not patrol_marker: return
	var center_x = patrol_marker.global_position.x
	
	if global_position.x > center_x + patrol_distance: patrol_dir = -1
	elif global_position.x < center_x - patrol_distance: patrol_dir = 1
		
	velocity.x = patrol_dir * _get_current_speed()
	velocity.y = 0
	_update_facing(patrol_dir)

func _handle_positioning() -> void:
	if not is_instance_valid(player_ref) or not patrol_marker:
		change_state(State.RETURNING)
		return
		
	var speed = _get_current_speed() * 1.5
	var dir = 1 if target_positioning_x > global_position.x else -1
	
	velocity.x = dir * speed
	velocity.y = (patrol_marker.global_position.y - global_position.y) * 5.0 
	_update_facing(dir)
	
	if abs(global_position.x - target_positioning_x) <= 15.0:
		global_position.x = target_positioning_x
		_execute_attack()

func _handle_attack() -> void:
	velocity = attack_dir * (attack_speed * (1.0 + (3 - hp) * 0.4))
	if velocity.x != 0: _update_facing(1 if velocity.x > 0 else -1)
		
	if ground_marker and global_position.y >= ground_marker.global_position.y:
		_trigger_earthquake_and_shockwave()
		change_state(State.REST)

func _handle_returning() -> void:
	if not patrol_marker: return
	velocity = Vector2(0, -_get_current_speed() * 1.5)
	
	if global_position.y <= patrol_marker.global_position.y:
		global_position.y = patrol_marker.global_position.y
		change_state(State.PATROL)

func _handle_escape() -> void:
	# Bergerak ke kanan atas dengan kecepatan tinggi
	velocity = Vector2(1, -1).normalized() * (base_speed * 3.5)
	_update_facing(1)

# ================= LOGIKA TARUNG & DETEKSI =================

func _check_player_detection() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty() or not ground_marker: return
	
	var target = players[0]
	var dist_x = abs(target.global_position.x - global_position.x)
	var dist_y = abs(target.global_position.y - ground_marker.global_position.y)
	
	if dist_y <= y_tolerance and dist_x <= detection_range_x:
		player_ref = target
		change_state(State.THINK)

func _pikir_dan_pilih_serangan() -> void:
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	
	if not is_instance_valid(player_ref) or not ground_marker:
		change_state(State.PATROL)
		return
		
	var height_diff = ground_marker.global_position.y - global_position.y
	var player_x = player_ref.global_position.x
	
	if abs(player_x - global_position.x) <= 100.0:
		attack_type = 2 
		target_positioning_x = player_x
	else:
		attack_type = 1 
		var side = 1 if player_x > global_position.x else -1
		target_positioning_x = player_x - (side * height_diff)
		
	change_state(State.POSITIONING)

func _execute_attack() -> void:
	var ground_y = ground_marker.global_position.y
	var warning_pos = Vector2.ZERO
	
	if attack_type == 2:
		attack_dir = Vector2.DOWN
		warning_pos = Vector2(global_position.x, ground_y)
	else:
		var side = 1 if player_ref.global_position.x > global_position.x else -1
		attack_dir = Vector2(side, 1).normalized()
		warning_pos = Vector2(global_position.x + (side * (ground_y - global_position.y)), ground_y)
		
	attack_warning.emit(warning_pos)
	change_state(State.ATTACK)

func _check_collisions() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		
		if collider.is_in_group("player"):
			_toggle_collisions(State.IDLE) # Matikan collision attack
			var dir_x = 1.0 if global_position.x < collider.global_position.x else -1.0
			collider.apply_central_impulse(Vector2(dir_x, -1.2).normalized() * knockback_force)
			change_state(State.RETURNING) 
			break
		else:
			_trigger_earthquake_and_shockwave()
			change_state(State.REST)
			break

func take_damage() -> void:
	hp -= 1
	visual.modulate = Color.RED 
	create_tween().tween_property(visual, "modulate", Color.WHITE, 0.2)
	_trigger_camera_shake(0.3, 18.0)
	
	if hp <= 0:
		change_state(State.ESCAPE) # Berubah dari queue_free() menjadi kabur
	else:
		change_state(State.RETURNING)

# ================= EVENT & HELPER =================

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.REST and can_take_damage:
		if body is RigidBody2D:
			body.linear_velocity.y = 0
			body.apply_central_impulse(Vector2(0, -600.0))
		take_damage()

func _on_timer_timeout() -> void:
	if current_state == State.REST: change_state(State.RETURNING)

func _trigger_earthquake_and_shockwave() -> void:
	_trigger_camera_shake(0.25, 14.0)
	for player in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(player) and player is RigidBody2D:
			if global_position.distance_to(player.global_position) <= shockwave_radius:
				var side = 1.0 if player.global_position.x > global_position.x else -1.0
				player.apply_central_impulse(Vector2(side, -1.2).normalized() * shockwave_force)

func _trigger_camera_shake(duration: float, magnitude: float) -> void:
	var sig_bus = get_node_or_null("/root/SignalBus")
	if sig_bus: sig_bus.camera_shake_requested.emit(duration, magnitude)

func _get_current_speed() -> float:
	return base_speed * (1.0 + (3 - hp) * 0.5)

func _update_facing(dir: int) -> void:
	visual.scale.x = 0.4 if dir == 1 else -0.4

func _toggle_collisions(state: State) -> void:
	$CollisionShapeRest.set_deferred("disabled", state != State.REST)
	$CollisionShapeAttack1.set_deferred("disabled", state != State.ATTACK or attack_type != 1)
	$CollisionShapeAttack2.set_deferred("disabled", state != State.ATTACK or attack_type != 2)
	if has_node("CollisionShapeFlyStanding"): $CollisionShapeFlyStanding.set_deferred("disabled", true)
	if has_node("CollisionShapeFly"): $CollisionShapeFly.set_deferred("disabled", true)
