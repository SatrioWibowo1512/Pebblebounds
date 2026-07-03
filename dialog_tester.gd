extends Node2D

func _ready():
	var cerita = [
		{"char": "Froggy", "text": "Halo! [wave]Lompat sana lompat sini![/wave]", "time": 3.0},
		{"char": "Pebble", "text": "Hei, jangan berisik! [shake level=15]Aku sedang tidur![/shake]", "time": 2.5}
	]
	DialogManager.start_dialog(cerita)
