extends Node


var fade_time = 0.7

onready var home_scene_path: String = "res://home/home.tscn"
onready var game_scene_path: String = Profiles.current_game_data["game_scene_path"]


func _input(event: InputEvent) -> void:
	
	if OS.is_debug_build():  # debug mode
		if Input.is_action_just_pressed("r"):
			var all_nodes = Global.get_all_nodes_in_node(self)
			
			for node in all_nodes:
				if node.name[0] == "_" and node.name[1] == "_":
					printt("_NODE",node.name)
			
			print("All nodes in MAIN scene",  all_nodes.size())
	
			
func _ready() -> void:

	Global.main_node = self
	
#	home_in_intro()
	home_in_no_intro()
#	game_in()

			
func home_in_intro():
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.open_with_intro()
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)

	
func home_in_no_intro():
	
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(home_scene_path, self)
	Global.current_scene.open_without_intro()
	
#	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima
	
	Global.current_scene.modulate = Color.black
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)


func home_in_from_game(finished_game: int):
	
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(home_scene_path, self)
	
	Global.current_scene.open_from_game(finished_game) # select game screen
	
	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima
	
	Global.current_scene.modulate = Color.black
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time)


func home_out():
	
	if not Global.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
		Global.sound_manager.stop_music("menu_music")
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")
	
	Global.release_scene(Global.current_scene)
	call_deferred("game_in")


func game_in():	
	
	game_scene_path = Profiles.current_game_data["game_scene_path"]	
	
	get_viewport().set_disable_input(false) # anti dablklik
	get_tree().set_pause(false)
	
	Global.spawn_new_scene(game_scene_path, self)
	
	# tukaj se seta GM glede na izbiro igre
	Global.game_manager.set_tilemap()
	Global.game_manager.set_game_view()
	Global.game_manager.create_players()
#	Global.game_manager.create_strays(Profiles.game_settings["create_strays_count"])
#	yield(Global.game_manager, "all_strays_spawned")
	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira (na restart)
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(Global.current_scene, "modulate", Color.white, fade_time).from(Color.black)
	yield(fade_in, "finished")
	
	Global.game_manager.set_game()
	

func game_out(game_to_exit: int):
	
	Global.game_camera = null
	
	Global.sound_manager.play_gui_sfx("menu_fade")
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")
	
	Global.release_scene(Global.current_scene)
	call_deferred("home_in_from_game", game_to_exit) # nujno deferred, ker se tudi relese scene zgodi deferred


func reload_game(): # game out z drugačnim zaključkom
	
	Global.game_camera = null
	Global.sound_manager.play_gui_sfx("menu_fade")

	var current_game_enum: int = Global.game_manager.game_data["game"]
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")
	
	Global.release_scene(Global.current_scene)
	Profiles.call_deferred("set_game_data", current_game_enum) # nujno deferred, ker se tudi relese scene zgodi deferred
	call_deferred("game_in") # nujno deferred, ker se tudi relese scene zgodi deferred


func hard_reset():
	# v bistvu je to reload home ali game scene
	
	# stop elements
	if Global.current_scene.name == "Home":
		Global.sound_manager.stop_music("menu_music")
	else:
		Global.game_manager.stop_game_elements()
		Global.sound_manager.stop_music("game_music_on_gameover")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Global.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Global, "release_scene", [Global.current_scene])
	if Global.current_scene.name == "Home":
		fade_out.tween_callback(self, "home_in_no_intro").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu
	else:
		fade_out.tween_callback(Profiles, "set_game_data", [Global.game_manager.game_data["game"]] ).set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu
		fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu		

	get_viewport().set_disable_input(false) # anti dablklik
