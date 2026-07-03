extends TextureButton

@export var ukuran: Vector2
@export var ukuran2: Vector2

func _ready():
	pivot_offset = size / 2.0 
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

func _on_hover():
	create_tween().tween_property(self, "scale", ukuran2, 0.1)

func _on_exit():
	create_tween().tween_property(self, "scale", ukuran, 0.1)
 
