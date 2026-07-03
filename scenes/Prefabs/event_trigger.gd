extends Area2D

@export var dialog_id: String = ""
@export var trigger_once: bool = true

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	# Abaikan jika dialog manager sedang sibuk atau area sudah pernah dipicu
	if DialogManager.is_active or (has_triggered and trigger_once):
		return
		
	if dialog_id != "":
		has_triggered = true
		DialogManager.start_dialog_by_id(dialog_id)
		
		# Jika hanya untuk sekali jalan, matikan monitoring area ini
		if trigger_once:
			monitoring = false
