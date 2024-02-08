extends Node


var fade_time = 1

onready var home_scene_path: String = "res://home/Home.tscn"
onready var game_scene_path: String = "res://game/Game.tscn"


func _ready() -> void:
	
	Global.main_node = self
	
	home_in()
#	game_in()
	

func home_in():
	Global.sound_manager.play_sfx("menu_music")	
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)
	

func home_out():
	
	Global.sound_manager.stop_sfx("menu_music")
	Global.sound_manager.play_sfx("fade_in_out")
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1)


func game_in():
	
	Global.spawn_new_scene(game_scene_path, self)
	
	yield(get_tree().create_timer(1), "timeout")
	Global.current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)


func game_out():
	
	Global.sound_manager.play_sfx("fade_in_out")
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "home_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu


func reload_game():
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
#	fade_out.tween_callback(Global, "reload_scene", [Global.current_scene])
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu
	
