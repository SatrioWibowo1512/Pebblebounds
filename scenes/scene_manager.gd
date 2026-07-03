extends CanvasLayer

@onready var transition_rect = $TransitionRect
@onready var shader_mat = transition_rect.material
@onready var loading_ui = $LoadingUI
@onready var anim = $LoadingUI/AnimationPlayer

func _ready():
	shader_mat.set_shader_parameter("scale", 2.0)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_ui.hide()

func load_scene(path: String, duration: float = 0.5):
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP 

	var tween = create_tween()
	tween.tween_property(shader_mat, "shader_parameter/scale", 0.0, duration)
	await tween.finished

	loading_ui.show()
	anim.play("loading") 
	tween = create_tween()
	tween.tween_property(shader_mat, "shader_parameter/scale", 2.0, duration)
	await tween.finished

	ResourceLoader.load_threaded_request(path)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame 

	tween = create_tween()
	tween.tween_property(shader_mat, "shader_parameter/scale", 0.0, duration)
	await tween.finished

	# 5. Terapkan scene baru dan sembunyikan UI loading
	var loaded_scene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(loaded_scene)
	loading_ui.hide()
	anim.stop()

	tween = create_tween()
	tween.tween_property(shader_mat, "shader_parameter/scale", 2.0, duration)
	await tween.finished

	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
