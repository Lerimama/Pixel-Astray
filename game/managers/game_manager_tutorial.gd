extends GameManager


func set_game(): 
	
	# kliče main.gd pred po igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	# tutorial funkcijo prikaza plejerja izpelje v svoji kodi
	
	yield(get_tree().create_timer(1), "timeout") # da se animacija plejerja konča	
	Global.hud.slide_in(start_players_count)
	start_game()
	yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
	Global.current_tilemap.background_room.hide()	
	
	
func start_game():

	Global.tutorial_gui.open_tutorial()

	
func set_players():
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.modulate = Global.color_almost_black # da se lažje bere text nad njim
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# stats
		new_player_pixel.player_stats = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
		new_player_pixel.player_stats["player_energy"] = game_settings["player_start_energy"]
		new_player_pixel.player_stats["player_life"] = game_settings["player_start_life"]
		
		# povežem s hudom
		new_player_pixel.connect("stat_changed", Global.hud, "_on_stat_changed")
		new_player_pixel.emit_signal("stat_changed", new_player_pixel, new_player_pixel.player_stats) # štartno statistiko tako javim 
		
		# pregame setup
		new_player_pixel.set_physics_process(false)
		new_player_pixel.player_camera = Global.game_camera


func upgrade_level(level_upgrade_reason: String):
	# namen: level = tutorial stage
	
	print ("level_up")
	if level_upgrade_in_progress:
		return
	level_upgrade_in_progress = true	
	
	if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.COLLECT:
		print ("burst end", Global.tutorial_gui.current_tutorial_stage)
		Global.tutorial_gui.finish_collect()	
		
	elif Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.MULTICOLLECT:
		print ("skill end", Global.tutorial_gui.current_tutorial_stage)
		Global.tutorial_gui.finish_multicollect()
		
	# reset players
	for player in Global.game_manager.current_players_in_game:
		player.end_move()
	Global.hud.empty_color_indicators()
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	# start new level
	Global.game_manager.set_strays() 
	get_tree().call_group(Global.group_players, "set_physics_process", true)
	
	level_upgrade_in_progress = false
	
var prev_stage_stray_count: int = 0 # kar ostane od prejšnje faze ... planirano

func _change_strays_in_game_count(strays_count_change: int):
	# namen: upgrade namest GO, upoštava tiste, ki ostane os prejšne faze
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
#	if game_data.has("level") and not game_data["game"] == Profiles.Games.SWEEPER: # multi level game
#		# naberem število sten
#		var wall_strays_count: int = 0
#		for stray in get_tree().get_nodes_in_group(Global.group_strays): # nujno jih ponovno zajamem
#			if stray.current_state == stray.States.WALL:
#				wall_strays_count += 1
#		# če ostajajo samo še stene ali pa ni straysa nobenega več
#		if strays_in_game_count == 0: 
#		#		if strays_in_game_count == wall_strays_count or strays_in_game_count == 0: 
#			upgrade_level("cleaned")
#	else:
	if strays_in_game_count - prev_stage_stray_count == 0: 
		if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.WINLOSE:
			game_over(GameoverReason.CLEANED)
		else:
			upgrade_level("cleaned")
