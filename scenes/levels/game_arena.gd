extends Node2D

@onready var player = $Player # Sesuaikan dengan path node Player kamu

func _ready() -> void:
	if GameManager.player_position != Vector2.ZERO:
		player.global_position = GameManager.player_position

	DialogManager.dialog_ended.connect(_on_dialog_ended)
	
	DialogManager.start_dialog_by_id("before_the_journey")
	
	await DialogManager.dialog_ended 
	await get_tree().create_timer(3).timeout
	DialogManager.start_dialog_by_id("opening_1")
	
	await DialogManager.dialog_ended 
	await get_tree().create_timer(3).timeout
	DialogManager.start_dialog_by_id("training")

func _on_dialog_ended(dialog_id: String) -> void:
	if dialog_id == "ending":
		credit_scene()

func credit_scene() -> void:
	print("Credit scene dimulai!")

func remove_player() -> void:
	player.queue_free()

func _on_camera_trigger_body_entered(body: Node2D) -> void:
	$Camera2D/AnimationPlayer.play("credit_scene")
