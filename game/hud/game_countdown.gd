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
	animation_player.play("countdown_3")
	
	
func play_countdown_a_sound():
	Global.sound_manager.play_sfx("countdown_a")


func play_countdown_b_sound():
	Global.sound_manager.play_sfx("countdown_b")

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	emit_signal("countdown_finished") # preda štafeto na GM
	visible = false
