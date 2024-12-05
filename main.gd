extends Node


var fade_time: float = 0.7
var menu_fade_sound_length: float = 1.29
var wait_sound_time: float = menu_fade_sound_length - fade_time + 0.1 # da ne traja med menjavo scen ... 0.1 = zazih

onready var home_scene_path: String = "res://home/home.tscn"
onready var game_scene_path: String = Profiles.current_game_data["game_scene_path"]

var current_scene: Node2D


func _unhandled_input(event: InputEvent) -> void:
#func _input(event: InputEvent) -> void:

	if OS.is_debug_build():  # debug OS mode
		if Input.is_action_just_pressed("r"):
			var all_nodes = Global.get_all_nodes_in_node(self)

			for node in all_nodes:
				if node.name[0] == "_" and node.name[1] == "_":
					printt("_NODE",node.name)

			print("All nodes in MAIN scene",  all_nodes.size())


func _ready() -> void:

	#	TranslationServer.set_locale("sl")
	#	print("Current lang: ", TranslationServer.get_locale())

	Global.main_node = self

#	call_deferred("home_in_intro")
	call_deferred("home_in_no_intro")
#	call_deferred("game_in")

	Analytics.call_deferred("start_new_session")


func home_in_intro():

	get_viewport().set_disable_input(false)

	var home_scene = spawn_new_scene(home_scene_path, self)
	home_scene.open_with_intro()

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_time)


func home_in_no_intro():

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var home_scene = spawn_new_scene(home_scene_path, self)
	home_scene.open_without_intro()

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_time).from(Color.black)


func home_in_from_game(finished_game: int):

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var home_scene = spawn_new_scene(home_scene_path, self)
	home_scene.open_from_game(finished_game) # select game screen

#	spawn_new_scene(home_scene_path, self)
#	current_scene.open_from_game(finished_game) # select game screen

	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima

	home_scene.modulate = Color.black

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_time)


func home_out():

	get_viewport().set_disable_input(true) # zazih ... dobra praksa

	Global.sound_manager.play_gui_sfx("menu_fade")

	if not Global.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
		Global.sound_manager.stop_music("menu_music")

#	Global.current_scene.get_node("SelectGame/BackBtn").grab_focus() # anti pregame toggle
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")

	yield(get_tree().create_timer(wait_sound_time), "timeout")

	release_scene(current_scene)
	call_deferred("game_in")


func game_in():

	if Profiles.tutorial_mode:
		Global.sound_manager.current_music_track_index = Profiles.tutorial_music_track_index
	else:
		Global.sound_manager.current_music_track_index = Profiles.game_settings["game_music_track_index"]

	game_scene_path = Profiles.current_game_data["game_scene_path"]

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var game_scene = spawn_new_scene(game_scene_path, self)

	# tukaj se seta GM glede na izbiro igre
	Global.game_manager.set_tilemap()
	Global.game_manager.set_game_view()
	Global.game_manager.create_players()

	yield(get_tree().create_timer(0.3), "timeout") # da se kamera centrira

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(game_scene, "modulate", Color.white, fade_time).from(Color.black)
	yield(fade_in, "finished")

	Global.game_manager.set_game()


func game_out(game_to_exit: int):

	get_viewport().set_disable_input(true) # zazih ... dobra praksa

	Global.game_camera = null
	Global.sound_manager.play_gui_sfx("menu_fade")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")

	yield(get_tree().create_timer(wait_sound_time), "timeout")

	release_scene(current_scene)
	call_deferred("home_in_from_game", game_to_exit) # nujno deferred, ker se tudi relese scene zgodi deferred


func reload_game(): # game out z drugačnim zaključkom

	Global.game_camera = null
	Global.sound_manager.play_gui_sfx("menu_fade")

	var current_game_enum: int = Global.game_manager.game_data["game"]

	# če relouda, se trenutna igra konča ob kliku in potem tukaj začne nova (nadomešča home btn klik
	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"])

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")

	yield(get_tree().create_timer(wait_sound_time), "timeout")

	release_scene(current_scene)
	Profiles.call_deferred("set_game_data", current_game_enum) # nujno deferred, ker se tudi relese scene zgodi deferred
	call_deferred("game_in") # nujno deferred, ker se tudi relese scene zgodi deferred


func quit_exit_game():

	Data.write_settings_to_file()

	Analytics.end_session()
	yield(Analytics, "session_saved")
	get_tree().call_deferred("quit")


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


#var current_scene = null # za scene switching


func release_scene(scene_node): # release scene

	scene_node.propagate_call("queue_free", []) # kvefrijam vse node v njem

	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)


func _free_scene(scene_node):

	if OS.is_debug_build():  # debug OS mode
		#		print("SCENE RELEASED (in next step): ", scene_node)
		pass
	scene_node.free()


func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	var new_current_scene = scene_resource.instance()

	if OS.is_debug_build(): # debug OS mode
		#		print("SCENE INSTANCED: ", new_current_scene)
		pass
	new_current_scene.modulate.a = 0
	parent_node.add_child(new_current_scene)

	if OS.is_debug_build():  # debug OS mode
		#		print("SCENE ADDED: ", new_current_scene)
		print("--- new scene ---")

	current_scene = new_current_scene
	return new_current_scene
