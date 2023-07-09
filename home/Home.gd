extends Node


onready var play_btn: Button = $Menu/PlayBtn


func _ready():
	play_btn.grab_focus()


func _on_PlayBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	Global.main_node.home_out()


func _on_PlayBtn_focus_exited() -> void:
	Global.sound_manager.play_sfx("btn_focus_change")
