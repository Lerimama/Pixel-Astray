extends Node


var fade_time = 1

onready var home_scene_path: String = "res://scenes/Home.tscn"
onready var game_scene_path: String = "res://scenes/Game.tscn"


func _ready() -> void:
	
	Global.main_node = self
	
#	home_in()
	game_in()
	

func home_in():
	
	Global.spawn_new_scene(home_scene_path, self)
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate:a", 1, fade_time)
	

func home_out():
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate:a", 0, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1)


func game_in():
	
	Global.spawn_new_scene(game_scene_path, self)
	
	yield(get_tree().create_timer(1), "timeout")
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate:a", 1, fade_time)


func game_out():
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate:a", 0, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "home_in").set_delay(1)


func reload_game():
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate:a", 0, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in")
	
