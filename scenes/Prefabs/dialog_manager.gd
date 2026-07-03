extends CanvasLayer

@onready var dialog_box: TextureRect = $DialogBox
@onready var text_label: RichTextLabel = $DialogBox/RichTextLabel

var dialog_queue: Array = []
var current_index: int = 0
var is_active: bool = false
var typing_speed: float = 0.03

var default_scale: Vector2
var base_position: Vector2
var time_passed: float = 0.0

func _ready():
	visible = false
	default_scale = dialog_box.scale
	base_position = dialog_box.position

func _process(delta: float):
	if is_active:
		time_passed += delta
		dialog_box.position.y = base_position.y + sin(time_passed * 3.0) * 6.0
		dialog_box.rotation = sin(time_passed * 2.0) * deg_to_rad(1.5)

func start_dialog(data: Array):
	if is_active: return
	dialog_queue = data
	current_index = 0
	is_active = true
	visible = true
	
	# Langsung panggil show_dialog tanpa menganimasikannya di sini
	show_dialog()

func show_dialog():
	if current_index >= dialog_queue.size():
		end_dialog()
		return
		
	var current_line = dialog_queue[current_index]
	
	# 1. Ganti tekstur terlebih dahulu saat box belum membesar/terlihat
	var texture_path = "res://assets/dialog/DialogBox_" + current_line["char"] + ".webp"
	if ResourceLoader.exists(texture_path):
		dialog_box.texture = load(texture_path)
		
	# 2. Jika ini adalah baris pertama, jalankan animasi pop-in SETELAH tekstur berubah
	if current_index == 0:
		dialog_box.pivot_offset = dialog_box.size / 2
		dialog_box.scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(dialog_box, "scale", default_scale, 0.4)
		await tween.finished
		
	# 3. Mulai efek mengetik teks
	text_label.text = current_line["text"]
	text_label.visible_characters = 0
	
	var tween_text = create_tween()
	var duration = text_label.text.length() * typing_speed
	tween_text.tween_property(text_label, "visible_characters", text_label.text.length(), duration)
	await tween_text.finished
	
	var display_time = current_line.get("time", 2.0)
	await get_tree().create_timer(display_time).timeout
	
	current_index += 1
	show_dialog()

func end_dialog():
	text_label.text = ""
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(dialog_box, "scale", Vector2.ZERO, 0.3)
	await tween.finished
	
	dialog_box.position = base_position
	dialog_box.rotation = 0
	
	visible = false
	is_active = false
	dialog_queue.clear()
