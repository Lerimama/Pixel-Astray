extends Control


signal countdown_finished

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var position_control: Control = $Countdown/PositionControl


func _ready() -> void:
	Global.start_countdown = self
	visible = false

	
func start_countdown():
	modulate.a = 0
	visible = true
	
	# toggle countdown
	if Global.game_manager.game_settings["start_countdown_on"]:
		animation_player.play("countdown_3")
	else:
		emit_signal("countdown_finished")
	
	
func play_countdown_a_sound():
	Global.sound_manager.play_sfx("countdown_a")


func play_countdown_b_sound():
	Global.sound_manager.play_sfx("countdown_b")

	
func _on_AnimationPlayer_animation_finished(coundown_5) -> void:
	
	emit_signal("countdown_finished") # preda štafeto na GM
	visible = false
