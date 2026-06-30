extends CanvasLayer

@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var next_indicator: Label = $Panel/NextIndicator

var dialog_lines: Array[String] = []
var current_line: int = 0
var is_active: bool = false

@export var text_speed: float = 0.05

func _ready() -> void:
	hide_dialog()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept"):
		if text_label.visible_characters < text_label.text.length():
			text_label.visible_characters = text_label.text.length()
		else:
			next_line()

func start_dialog(lines: Array[String]) -> void:
	if is_active:
		return
		
	dialog_lines = lines
	current_line = 0
	is_active = true
	show()
	show_line()

func show_line() -> void:
	next_indicator.hide()
	text_label.text = dialog_lines[current_line]
	text_label.visible_characters = 0
	
	var tween = create_tween()
	tween.tween_property(text_label, "visible_characters", text_label.text.length(), text_label.text.length() * text_speed)
	tween.finished.connect(_on_text_finished)

func _on_text_finished() -> void:
	next_indicator.show()

func next_line() -> void:
	current_line += 1
	if current_line >= dialog_lines.size():
		hide_dialog()
	else:
		show_line()

func hide_dialog() -> void:
	is_active = false
	hide()
