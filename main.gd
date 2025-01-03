extends Node


var current_scene: Node2D
var fade_scene_time: float = 0.7

onready var inverted_scheme: Node2D = $InvertedScheme

#func _process(delta: float) -> void:
#	printt ("strays count", get_tree().get_nodes_in_group(Global.group_strays).size())

func _ready() -> void:

	#	TranslationServer.set_locale("sl")
	#	print("Current lang: ", TranslationServer.get_locale())

	Global.main_node = self
	inverted_scheme.modulate.a = 0
	inverted_scheme.hide()


	Global.main_node = self
	inverted_scheme.modulate.a = 0
	inverted_scheme.hide()


#	if Profiles.html5_mode and not Profiles.debug_mode:
#		call_deferred("home_in_no_intro")
#	else:
#		var start_with: String = Profiles.start_with_method
#		call_deferred(start_with)
#
#	Analytics.call_deferred("start_new_session")


	var start_with: String = Profiles.start_with_method
	if Profiles.html5_mode:
		start_with = "home_in_no_intro"
	elif not Profiles.debug_mode:
		start_with = "home_in_intro"

	call_deferred(start_with)

#	Analytics.call_deferred("start_new_session")


func home_in_intro():

	get_viewport().set_disable_input(false)

	var home_scene = spawn_new_scene(Profiles.home_scene_path, self)
	home_scene.open_with_intro()

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_scene_time)


func home_in_no_intro():

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var home_scene = spawn_new_scene(Profiles.home_scene_path, self)
	home_scene.open_without_intro()

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_scene_time).from(Color.black)


func home_in_from_game(finished_game: int):

	# ker se v sweeperju zaklene
	Profiles.default_game_settings["always_zoomed_in"] = false

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var home_scene = spawn_new_scene(Profiles.home_scene_path, self)
	home_scene.open_from_game(finished_game) # select game screen

#	spawn_new_scene(Profiles.home_scene_path, self)
#	current_scene.open_from_game(finished_game) # select game screen

	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima

	home_scene.modulate = Color.black
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(home_scene, "modulate", Color.white, fade_scene_time)


func home_out():

	get_viewport().set_disable_input(true) # zazih ... dobra praksa
	var sound_to_play: AudioStreamPlayer = Global.sound_manager.play_gui_sfx("menu_fade")
	if not Global.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
		Global.sound_manager.stop_music("menu_music")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_scene_time)
	yield(fade_out, "finished")
	yield(sound_to_play, "finished") # sound more bit daljši od tweena

	release_scene(current_scene)
	call_deferred("game_in")


func game_in():

	if Profiles.tutorial_mode:
		Global.sound_manager.current_music_track_index = Profiles.tutorial_music_track_index
	else:
		Global.sound_manager.current_music_track_index = Profiles.game_settings["game_music_track_index"]

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)

	var game_scene = spawn_new_scene(Profiles.game_scene_path, self)

	# tukaj se seta GM glede na izbiro igre
	Global.game_manager.set_tilemap()
	Global.game_manager.set_game_view()
	Global.game_manager.create_players()

	yield(get_tree().create_timer(0.3), "timeout") # da se kamera centrira

	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(game_scene, "modulate", Color.white, fade_scene_time).from(Color.black)
	yield(fade_in, "finished")

	Global.game_manager.set_game()


func game_out(game_to_exit: int):

	get_viewport().set_disable_input(true) # zazih ... dobra praksa
	Global.game_camera = null
	var sound_to_play: AudioStreamPlayer = Global.sound_manager.play_gui_sfx("menu_fade")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_scene_time)
	yield(fade_out, "finished")
	yield(sound_to_play, "finished") # sound more bit daljši od tweena

	release_scene(current_scene)
	call_deferred("home_in_from_game", game_to_exit) # nujno deferred, ker se tudi relese scene zgodi deferred
	var krknek: Expression

func reload_game(): # game out z drugačnim zaključkom

	Global.game_camera = null
	var sound_to_play: AudioStreamPlayer = Global.sound_manager.play_gui_sfx("menu_fade")
	var current_game_enum: int = Global.game_manager.game_data["game"]
#	printt ("reload", Global.game_manager.game_data["game"], Global.game_manager.game_data.key())

	# če relouda, se trenutna igra konča ob kliku in potem tukaj začne nova (nadomešča home btn klik
#	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"])

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_scene_time)
	yield(fade_out, "finished")
	yield(sound_to_play, "finished") # sound more bit daljši od tweena

	release_scene(current_scene)
	Profiles.call_deferred("set_game_data", current_game_enum) # nujno deferred, ker se tudi relese scene zgodi deferred
	call_deferred("game_in") # nujno deferred, ker se tudi relese scene zgodi deferred


func quit_exit_game(): # ta funkcija je v htmlju nedosegljiva

	#	if not Profiles.html5_mode:
	Data.write_settings_to_file()

#	Analytics.end_session()
#	yield(Analytics, "session_saved")
	get_tree().call_deferred("quit")


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


func release_scene(scene_node): # release scene

	scene_node.propagate_call("queue_free", []) # kvefrijam vse node v njem

	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)


func _free_scene(scene_node):

#	if Profiles.debug_mode:
#		#		print("SCENE RELEASED (in next step): ", scene_node)
#		pass
	scene_node.free()


func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	var new_current_scene = scene_resource.instance()

#	if Profiles.debug_mode:
#		#		print("SCENE INSTANCED: ", new_current_scene)
#		pass
	new_current_scene.modulate.a = 0
	parent_node.add_child(new_current_scene)

#	if Profiles.debug_mode:
#		#		print("SCENE ADDED: ", new_current_scene)
#		print("--- new scene ---")

	current_scene = new_current_scene
	return new_current_scene


func invert_colors(invert_time: float):

	var fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	if inverted_scheme.modulate.a == 1:
		fade.tween_property(inverted_scheme, "modulate:a", 0, invert_time)
		fade.tween_callback(inverted_scheme, "hide")
	elif inverted_scheme.modulate.a == 0:
		fade.tween_callback(inverted_scheme, "show")
		fade.tween_property(inverted_scheme, "modulate:a", 1, invert_time)
