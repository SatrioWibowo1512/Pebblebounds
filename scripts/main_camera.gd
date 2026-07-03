class_name AdvancedTransitionCamera
extends Camera2D

@export var smooth_speed: float = 5.0

var target_camera: Camera2D

# Variabel untuk sistem camera shake
var shake_time: float = 0.0
var shake_timer: float = 0.0
var shake_power: float = 0.0

func _ready() -> void:
	make_current()
	_find_default_target()
	
	# Menghubungkan fungsi ke Signal Bus global
	if ProjectSettings.has_setting("autoload/SignalBus") or Engine.has_singleton("SignalBus") or get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").connect("camera_shake_requested", start_shake)

# FIX: Mengubah ke _physics_process agar sinkron dengan pergerakan fisika Player
func _physics_process(delta: float) -> void:
	if is_instance_valid(target_camera):
		var weight: float = 1.0 - exp(-smooth_speed * delta)
		
		# Kejar posisi target murni tanpa gangguan offset guncangan
		var target_pos: Vector2 = target_camera.global_position
		global_position = global_position.lerp(target_pos, weight)
		zoom = zoom.lerp(target_camera.zoom, weight)
		
		# FIX: Gunakan property 'offset' bawaan Camera2D khusus untuk guncangan shake
		# Cara ini tidak akan merusak kalkulasi lerp pada global_position
		if shake_timer > 0.0:
			shake_timer -= delta
			var current_power: float = (shake_timer / shake_time) * shake_power
			offset = Vector2(
				randf_range(-current_power, current_power),
				randf_range(-current_power, current_power)
			)
		else:
			offset = Vector2.ZERO
	else:
		_find_default_target()

func switch_camera(new_camera: Camera2D) -> void:
	if is_instance_valid(new_camera):
		target_camera = new_camera
	else:
		_find_default_target()

func _find_default_target() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and "camera_2d" in player:
		target_camera = player.get("camera_2d") as Camera2D

func start_shake(time: float, power: float) -> void:
	shake_time = time
	shake_timer = time
	shake_power = power
