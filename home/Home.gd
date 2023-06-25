extends Node


onready var play_btn: Button = $Menu/PlayBtn

func _ready():
	play_btn.grab_focus()

func _on_PlayBtn_pressed() -> void:
	Global.main_node.home_out()
