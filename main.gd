extends Node


var fade_time = 0.7
var camera_shake_on: bool =  true #_temp

onready var home_scene_path: String = "res://home/home.tscn"
onready var game_scene_path: String = "res://game/game.tscn"


func _ready() -> void:
	
	Global.main_node = self
	
#	home_in_intro()
#	home_in_no_intro()
	game_in()


func home_in_intro():
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.open_with_intro()
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)
	
	
func home_in_no_intro(): # debug
	
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.open_without_intro()
	
	Global.current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)


func home_in_from_game():
	
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.open_from_game() # select game screen
	
	Global.current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)


func home_out():
	
	if not Global.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
		Global.sound_manager.stop_music("menu_music")
#	Global.sound_manager.play_gui_sfx("menu_fade")
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in")#.set_delay(1)


func game_in():
	
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(game_scene_path, self)
	Global.game_manager.set_tilemap()
	Global.game_manager.set_game_view()
	
	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira (na restart)
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time).from(Color.black)
	fade_in.tween_callback(Global.game_manager, "set_game")
	

func game_out():
	
	# stop all
	Global.player1_camera = null
	Global.player2_camera = null
	Global.sound_manager.stop_music("game_music") # za exit iz pavze
	
	Global.sound_manager.play_gui_sfx("menu_fade")
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "home_in_from_game").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu


func reload_game(): # game out z drugačnim zaključkom
	
	Global.player1_camera = null
	Global.player2_camera = null
	Global.sound_manager.stop_music("game_music")
	
	Global.sound_manager.play_gui_sfx("menu_fade")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu
	
