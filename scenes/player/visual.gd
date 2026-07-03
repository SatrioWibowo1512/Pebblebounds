extends Node2D

@export var idle_velocity_threshold: float = 10.0
@export var falling_velocity_threshold: float = 50.0
@export var landing_velocity_threshold: float = 10.0
@export var idle_time_to_change: float = 4.0
@export var long_fall_time: float = 1.5
@export var sad_duration: float = 2.0
@export var mad_duration: float = 2.0
@export var default_override_time: float = 1.5

@onready var expression: Sprite2D = $Expression

var textures = {
	"Cry": preload("res://assets/player/Pebble_Cry.webp"),
	"Dizzy": preload("res://assets/player/Pebble_Dizzy.webp"),
	"Excited": preload("res://assets/player/Pebble_Excited.webp"),
	"Happy": preload("res://assets/player/Pebble_Happy.webp"),
	"Mad": preload("res://assets/player/Pebble_Mad.webp"),
	"Sad": preload("res://assets/player/Pebble_Sad.webp"),
	"Shock": preload("res://assets/player/Pebble_Shock.webp"),
	"Wow": preload("res://assets/player/Pebble_Wow.webp")
}

var player: RigidBody2D
var idle_timer: float = 0.0
var air_timer: float = 0.0
var override_timer: float = 0.0

var landing_stage: int = 0
var landing_timer: float = 0.0
var was_in_air: bool = false
var current_expression: String = ""

func _ready() -> void:
	player = get_parent() as RigidBody2D
	if player and player.has_signal("jumped"):
		player.jumped.connect(_on_player_jumped)
	change_to_random_normal()

func _process(delta: float) -> void:
	if override_timer > 0.0:
		override_timer -= delta
		return

	if landing_stage > 0:
		_process_landing_sequence(delta)
		return

	if not player:
		return

	var current_velocity = player.linear_velocity
	var is_moving_slowly = current_velocity.length() <= idle_velocity_threshold
	var is_vertically_stable = abs(current_velocity.y) <= landing_velocity_threshold
	var is_idle = is_moving_slowly and is_vertically_stable
	var is_falling = current_velocity.y > falling_velocity_threshold

	if is_idle:
		if was_in_air:
			_trigger_landing_logic()
			return
			
		air_timer = 0.0
		
		if current_expression == "Dizzy" or current_expression == "Shock":
			change_to_random_normal()
		
		idle_timer += delta
		if idle_timer >= idle_time_to_change:
			idle_timer = 0.0
			change_to_random_normal()
	else:
		idle_timer = 0.0
		
		if is_falling:
			air_timer += delta
			was_in_air = true
			if air_timer >= long_fall_time:
				change_expression("Shock")
		elif current_velocity.y < -landing_velocity_threshold:
			was_in_air = true

func _on_player_jumped(_impulse: Vector2) -> void:
	if override_timer <= 0.0:
		landing_stage = 0
		air_timer = 0.0
		was_in_air = true
		change_expression("Dizzy")

func _trigger_landing_logic() -> void:
	if air_timer >= long_fall_time:
		landing_stage = 1
		landing_timer = sad_duration
		change_expression("Sad")
	air_timer = 0.0
	was_in_air = false

func _process_landing_sequence(delta: float) -> void:
	landing_timer -= delta
	if landing_timer <= 0.0:
		if landing_stage == 1:
			landing_stage = 2
			landing_timer = mad_duration
			change_expression("Mad")
		elif landing_stage == 2:
			landing_stage = 0
			change_to_random_normal()

func change_expression(expr_name: String) -> void:
	if textures.has(expr_name):
		current_expression = expr_name
		expression.texture = textures[expr_name]

func change_to_random_normal() -> void:
	var normal_expressions = ["Happy", "Excited", "Wow"]
	var random_index = randi() % normal_expressions.size()
	change_expression(normal_expressions[random_index])

func set_override_expression(expr_name: String, duration: float = 0.0) -> void:
	if duration <= 0.0:
		duration = default_override_time
		
	change_expression(expr_name)
	override_timer = duration
	landing_stage = 0
	air_timer = 0.0
