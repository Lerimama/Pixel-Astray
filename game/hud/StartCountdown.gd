extends Control

onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	Global.game_countdown = self
	
func start_countdown():
	animation_player.play("countdown_5")
	
func _on_AnimationPlayer_animation_finished(coundown_5) -> void:
	
	Global.game_manager.start_game()
