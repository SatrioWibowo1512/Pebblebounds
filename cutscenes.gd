extends Node2D

#func _ready() -> void:
	#DialogManager.start_dialog_by_id("opening_1")

func _dialog_2():
	DialogManager.start_dialog_by_id("opening_2")

func _animation_2():
	$AnimationPlayer.play("opening2")

func _dialog_3():
	DialogManager.start_dialog_by_id("opening_3")

func _ending():
	DialogManager.start_dialog_by_id("ending")
