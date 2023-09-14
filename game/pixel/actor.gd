extends KinematicBody2D

export var actor_in_motion: bool = true # exportano za animacijo

var step_time: float = 0.065

func _ready() -> void:
	pass # Replace with function body.

func play_stepping_loop():
	if not actor_in_motion:
		Global.sound_manager.stop_sfx("stepping")
		return
	Global.sound_manager.play_stepping_sfx(1)
	yield(get_tree().create_timer(step_time), "timeout")
	play_stepping_loop()

func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")
