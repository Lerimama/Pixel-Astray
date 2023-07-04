extends Control


signal countdown_finished

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var position_control: Control = $Countdown/PositionControl


func _ready() -> void:
	Global.game_countdown = self
	visible = false
	
func start_countdown():
	modulate.a = 0
	visible = true
	
	emit_signal("countdown_finished") # ... še na GM
#	animation_player.play("countdown_5")
	
func _on_AnimationPlayer_animation_finished(coundown_5) -> void:
	
	emit_signal("countdown_finished") # preda štafeto na GM
	
