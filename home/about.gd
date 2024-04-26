extends Control

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"


func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("about")
	get_viewport().set_disable_input(true)
