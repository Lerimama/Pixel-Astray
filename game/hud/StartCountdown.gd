extends Control


signal countdown_finished

onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	Global.game_countdown = self
	visible = false
	
func start_countdown():
	visible = true
	animation_player.play("countdown_5")

	
func _on_AnimationPlayer_animation_finished(coundown_5) -> void:
	
	emit_signal("countdown_finished") # preda štafeto na GM
	
