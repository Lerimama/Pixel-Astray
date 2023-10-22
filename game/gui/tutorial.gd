extends Control


onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	
	Global.tutorial_gui = self

func start():
	visible = true
	animation_player.play("goals_in")
	set_process_input(false)
	$Goals/Menu/StartBtn.grab_focus()
	
	
func start_tutorial():
	pass


func _on_StartBtn_pressed() -> void:
	animation_player.play("panels_in")
