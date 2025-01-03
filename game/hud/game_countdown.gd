extends Control


signal countdown_finished

onready var animation_player: AnimationPlayer = $AnimationPlayer


func start_countdown():

	yield(get_tree().create_timer(0.7), "timeout")
	animation_player.play("ready_go")


func play_countdown_a_sound():

	Global.sound_manager.play_event_sfx("start_countdown_a")

func play_countdown_b_sound():

	Global.sound_manager.play_event_sfx("start_countdown_b")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:

	# signal je v animaciji
	#	emit_signal("countdown_finished") # preda štafeto na GM
	visible = false
