extends Area2D

@export var dialog_id: String = ""
@export var trigger_once: bool = true

var has_triggered: bool = false

func _ready() -> void:
	# 1. Cek data di GameManager saat scene dimuat
	if trigger_once and dialog_id != "" and GameManager.is_dialog_triggered(dialog_id):
		queue_free() # Hapus node jika sudah pernah dipicu
		return
		
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void: # Sebaiknya pastikan yang masuk adalah Player
	if DialogManager.is_active or (has_triggered and trigger_once):
		return
		
	if dialog_id != "":
		has_triggered = true
		DialogManager.start_dialog_by_id(dialog_id)
		
		if trigger_once:
			monitoring = false
			# 2. Simpan status ke GameManager setelah dipicu
			GameManager.set_dialog_triggered(dialog_id)
