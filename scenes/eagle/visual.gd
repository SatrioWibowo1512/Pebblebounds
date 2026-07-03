extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var parent = get_parent()

var last_state: int = -1
var juice_tween: Tween

# [_process]: Memantau perubahan state dari parent secara otomatis tanpa mengubah script eagle.gd
func _process(_delta: float) -> void:
	if parent and parent.get("current_state") != last_state:
		last_state = parent.current_state
		_apply_juice(last_state)

# [_apply_juice]: Hub untuk memicu efek animasi berdasarkan state elang
func _apply_juice(state: int) -> void:
	if juice_tween:
		juice_tween.kill() # Hentikan animasi sebelumnya agar tidak bertumpuk
	
	# FIX: Jangan buat tween jika state tidak terdaftar dalam animasi juice
	if not state in [1, 2, 3, 4]:
		sprite.scale = Vector2.ONE # Reset skala ke normal (1.0, 1.0)
		return
		
	juice_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	match state:
		2: # State.ATTACK -> Efek memanjang/meruncing saat menerjang player
			juice_tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.1)
			juice_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
		
		3: # State.REST -> Efek gepeng membal (squash) saat jatuh menghantam tanah
			juice_tween.set_trans(Tween.TRANS_BOUNCE)
			juice_tween.tween_property(sprite, "scale", Vector2(0.6, 1.4), 0.15)
			juice_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
		
		1, 4: # State.PATROL / RETURNING -> Efek bernapas/mengepak dinamis saat terbang biasa
			juice_tween.set_loops().set_trans(Tween.TRANS_SINE)
			juice_tween.tween_property(sprite, "scale", Vector2(1.05, 0.95), 0.3)
			juice_tween.tween_property(sprite, "scale", Vector2(0.95, 1.05), 0.3)
