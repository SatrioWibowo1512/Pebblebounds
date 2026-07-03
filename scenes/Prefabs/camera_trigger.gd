extends Area2D

@export var zone_camera: Camera2D 
var main_camera: Camera2D
var dialog_has_apper: bool = false
@export var dialog_id:String 

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	main_camera = get_viewport().get_camera_2d() as Camera2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and main_camera and zone_camera:
		main_camera.switch_camera(zone_camera)
		if dialog_has_apper == false:
			DialogManager.start_dialog_by_id(dialog_id)
			dialog_has_apper = true
		

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and main_camera:
		main_camera.switch_camera(null) 
