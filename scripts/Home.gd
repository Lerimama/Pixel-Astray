extends Node


func _unhandled_input(event: InputEvent) -> void:

#	if Input.is_action_just_pressed("no1"):
#		spawn_player_pixel()
#	if Input.is_action_just_pressed("r"):
#		end_game()
	pass

func _on_PlayBtn_pressed() -> void:
	Global.main_node.home_out()
#
