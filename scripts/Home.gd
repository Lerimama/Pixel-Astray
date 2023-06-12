extends Node


var home_scene_path: String = "res://scenes/Home.tscn"
var game_scene_path: String = "res://scenes/game/Game.tscn"
onready var animation_player: AnimationPlayer = $AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:

#	if Input.is_action_just_pressed("no1"):
#		spawn_player_pixel()
#	if Input.is_action_just_pressed("r"):
#		end_game()
	pass

func _on_PlayBtn_pressed() -> void:
	Global.main_node.home_out()
#	animation_player.play("main_out")

#
#func _load_game():
#
#	Global.spawn_new_scene(game_scene_path, Global.main_node)
#	Global.release_scene(self)
#
##	Global.switch_to_scene(game_scene_path)
#
#
