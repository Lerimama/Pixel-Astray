extends GameManager


#var leftover_stray_count: int = 0 # kar se prenese od prejšnje faze v naslednjo ... planirano
#var skill_stage_spawn_positions: Array # shranim pozicije, da lahko respawnam, če prezgodaj spuca vse


	# kliče main.gd po prikazom igre  ... set_tilemap(), set_game_view(), create_players() # da je plejer viden že na fejdin

#var tutorial_

#var tut_mode: = false
#func set_game(): 
#	# namen: tut mode in normalno
#	# namen: tutorial ne štarta igre ... prikažem intro panel v tutorial gui in sejvam skills spawn pozicije
#
#	# colors 
#	set_color_pool()
#
##	if not Profiles.tutorial_mode:
##
##		if game_settings["show_game_instructions"]:
##			yield(Global.hud, "players_ready")
##
##		# player	
##		current_players_in_game = get_tree().get_nodes_in_group(Global.group_players)
##		var signaling_player: KinematicBody2D
##		for player in current_players_in_game:
##			player.animation_player.play("lose_white_on_start")
##			signaling_player = player # da se zgodi na obeh plejerjih istočasno
##		yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
##		yield(get_tree().create_timer(0.3), "timeout")	
##
###		# strays
###		create_strays(start_strays_spawn_count) # var je za tutorial			
###
###		yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
###		var show_strays_loop: int = 0
###		strays_shown_on_start.clear()
###		while strays_shown_on_start.size() < start_strays_spawn_count:
###			show_strays_loop += 1
###			show_strays_in_loop(show_strays_loop)
###
###		# gui		
###		yield(get_tree().create_timer(0.7), "timeout")
###		Global.hud.slide_in()
###		if game_settings["start_countdown"]:
###			yield(get_tree().create_timer(0.2), "timeout")
###			Global.start_countdown.start_countdown() # GM yielda za njegov signal
###			yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
###		else:
###			yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
##
##
##		skill_stage_spawn_positions = random_spawn_positions.duplicate()
##
##		Global.hud.slide_in()
###		start_game()
##		Global.tutorial_gui.open_tutorial()
##
##		# ugasnem ozadje
##		yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
##		Global.current_tilemap.background_room.hide()
##	if game_settings["show_game_instructions"]:
##		yield(Global.hud, "players_ready")
#
#
#
#
#	# player	
#	current_players_in_game = get_tree().get_nodes_in_group(Global.group_players)
#	var signaling_player: KinematicBody2D
#	for player in current_players_in_game:
#		player.animation_player.play("lose_white_on_start")
#		signaling_player = player # da se zgodi na obeh plejerjih istočasno
#	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
#	yield(get_tree().create_timer(0.3), "timeout")
#
#	# strays
#	create_strays(start_strays_spawn_count) # var je za tutorial
#
#	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
#	var show_strays_loop: int = 0
#	strays_shown_on_start.clear()
#	while strays_shown_on_start.size() < start_strays_spawn_count:
#		show_strays_loop += 1
#		show_strays_in_loop(show_strays_loop)
#
#	# gui		
#	yield(get_tree().create_timer(0.7), "timeout")
#
##	if Profiles.tutorial_mode:
##		yield(get_tree().create_timer(Profiles.get_it_time), "timeout") # tutorial, da čas za ogled
##	Global.tutorial_gui.animation_player.play("tutorial_start")
#	Global.hud.slide_in()
#
#	if game_settings["start_countdown"]:
#		yield(get_tree().create_timer(0.2), "timeout")
#		Global.start_countdown.start_countdown() # GM yielda za njegov signal
#		yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
#	else:
#		yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
#
#	start_game()
#
#	Global.current_tilemap.background_room.hide()
	

	

#func start_game():
#	# namen: open_tutorial, brez respawna
#
#
#	Global.hud.game_timer.start_timer()
#	Global.sound_manager.current_music_track_index = game_settings["game_music_track_index"]
#	Global.sound_manager.play_music("game_music")
#
#	for player in current_players_in_game:
#		if not game_settings ["zoom_to_level_size"]:
#			Global.game_camera.camera_target = player
#		player.set_physics_process(true)
#
#	game_on = true
	
		
			
	
#func create_players():
#	# namen: drugačen prikaz in barva na začetku
#
#	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
#		spawned_player_index += 1 # torej začnem z 1
#
#		# spawn
#		var new_player_pixel: KinematicBody2D
#		new_player_pixel = PlayerPixel.instance()
#		new_player_pixel.name = "p%s" % str(spawned_player_index)
#		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
#		new_player_pixel.modulate = Global.color_almost_black_pixel # da se lažje bere text nad njim
#		new_player_pixel.z_index = 1 # nižje od straysa
#		Global.node_creation_parent.add_child(new_player_pixel)
#
#		# stats
#		new_player_pixel.player_stats = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
#		new_player_pixel.player_stats["player_energy"] = game_settings["player_start_energy"]
#		new_player_pixel.player_stats["player_life"] = game_settings["player_start_life"]
#
#		# povežem s hudom
#		new_player_pixel.connect("stat_changed", Global.hud, "_on_stat_changed")
#		new_player_pixel.emit_signal("stat_changed", new_player_pixel, new_player_pixel.player_stats) # štartno statistiko tako javim 
#
#		# pregame setup
#		new_player_pixel.set_physics_process(false)
#		new_player_pixel.player_camera = Global.game_camera

	
#func create_strays_(strays_to_spawn_count: int):
#	# namen: na koncu pokaže strayse, če je tutorial
#
#	var color_pool_split_size: int = floor(color_pool_colors.size() / strays_to_spawn_count)
#
#	# positions
#	var available_required_spawn_positions = required_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
#	var available_random_spawn_positions = random_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
#
#	# spawn
#	for stray_index in strays_to_spawn_count: 
#
#		var new_stray_color_pool_index: int = stray_index * color_pool_split_size
#		var new_stray_color: Color = color_pool_colors[new_stray_color_pool_index] # barva na lokaciji v spektrumu
#
#		# spawn positions
#		var current_spawn_positions: Array
#		if current_level > 1 and not game_data["game"] == Profiles.Games.SWEEPER: # leveli večji od prvega ... random respawn
#			current_spawn_positions = get_free_positions()
#		else:
#			# najprej obvezne pozicije, potem random pozicije, ko so obvezne spraznjene
#			if not available_required_spawn_positions.empty():
#				# najprej bele pixle, potem barvne
#				if not wall_spawn_positions.empty():
#					current_spawn_positions = wall_spawn_positions
#				else: 
#					current_spawn_positions = available_required_spawn_positions
#			elif not available_random_spawn_positions.empty():
#				current_spawn_positions = available_random_spawn_positions
#
#		# žrebanje random pozicije določenih spawn pozicij
#		var random_range = current_spawn_positions.size()
#		var selected_cell_index: int = randi() % int(random_range)		
#		var selected_cell_position: Vector2 = current_spawn_positions[selected_cell_index]
#		var selected_stray_position: Vector2 = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)
#
#		# je beli? ... če pozicija bela in, če je index večji od planiranega deleža belih
#		var turn_to_white: bool = false
#		var spawn_white_start_limit: int = strays_to_spawn_count - round(strays_to_spawn_count * spawn_white_stray_part)
#		if wall_spawn_positions.has(selected_cell_position) or stray_index > spawn_white_start_limit: 
#			turn_to_white = true
#
#		# je pozicija zasedena
#		var selected_stray_position_is_free: bool = true
#		for player in current_players_in_game:
#			if player.global_position == selected_stray_position:
#				selected_stray_position_is_free = false
#		for stray in get_tree().get_nodes_in_group(Global.group_strays):
#			if stray.global_position == selected_stray_position:
#				selected_stray_position_is_free = false
#
#		# če je prazna
#		if selected_stray_position_is_free:
#			spawn_stray(stray_index, new_stray_color, selected_stray_position, turn_to_white)
#			 # dodam barvo
#			all_stray_colors.append(new_stray_color)
#
#		else: # varovalka če je zasedena se ne spawna in takega streya ne spawnam več
#			print("pozicija je zaseden tik pred spawn_stray()")
#			strays_to_spawn_count -= 1
#
#		# apdejtam pozicije ... če se ne spawna, moram pozicijo vseeno brisat, če ne se spawnajo vsi na to pozicijo
#		wall_spawn_positions.erase(selected_cell_position)
#		available_required_spawn_positions.erase(selected_cell_position)
#		available_random_spawn_positions.erase(selected_cell_position)
#
#	# varovalka, če se noben ne spawna, grem še enkrat čez cel postopek ... možno samo ko naj se spawna 1
#	if strays_to_spawn_count == 0:
#		printt("Noben stray se ni spawnal. Naredim še en krog spawnanja.")
#		create_strays(start_strays_spawn_count)
#		return
#
#	if Global.game_manager.game_data.has("level_goal_count"):
#		Global.hud.spawn_color_indicators(get_level_colors())
#	else:	
#		Global.hud.spawn_color_indicators(all_stray_colors) # barve pokažem v hudu		


#func upgrade_level(level_upgrade_reason: String):
#	# namen: level = tutorial stag, zaporedje je pomembno
#
#	if level_upgrade_in_progress:
#		return
#	level_upgrade_in_progress = true	
#
#
#	# NEXT  tutorial + classic
#	# per stage 
##	if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.TRAVEL:
##		start_strays_spawn_count = 500
##		set_real_game() # debug
##		level_upgrade_in_progress = false	
##		return
##
##		Global.tutorial_gui.finish_collect()	
#
#	if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.COLLECT:
#		Global.tutorial_gui.finish_collect()	
#	elif Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.MULTICOLLECT:
#		Global.tutorial_gui.finish_multicollect()
#
#	# reset
#	for player in Global.game_manager.current_players_in_game:
#		player.end_move()
#	# get_tree().call_group(Global.group_players, "set_physics_process", false)
#	yield(get_tree().create_timer(0.5), "timeout") # pavza, da zabeleži zaseden pozicije (plejer) 
#
#	# od tukaj je novi stage enum
#	Global.game_manager.create_strays(start_strays_spawn_count)
#	# get_tree().call_group(Global.group_players, "set_physics_process", true)
#
#	level_upgrade_in_progress = false
	

#func _change_strays_in_game_count(strays_count_change: int):
#	# namen: upgrade namest GO, upoštava tiste, ki ostane os prejšne faze
#
#	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
#	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
#
#	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
#		strays_cleaned_count += abs(strays_count_change)
#
#	if strays_in_game_count - leftover_stray_count == 0: 
#		if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.WINLOSE:
#			Global.tutorial_gui.finish_tutorial()
#		if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.SKILLS:
#			# če je spucano vse barvno, spawnam novo serijo, studi, če je beli spucan
#			random_spawn_positions = skill_stage_spawn_positions.duplicate()
#			upgrade_level("cleaned")
#		else:
#			upgrade_level("cleaned")

#
#func set_real_game():
#
#	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
#
#	var tilemap_to_load_path: String
#	tilemap_to_load_path = game_data["tilemap_path_game"]
#
#	# release default tilemap	
#	tilemap_to_release.set_physics_process(false)
#	tilemap_to_release.free()
#
#	# spawn new tilemap
#	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
#	var new_tilemap = GameTilemap.instance()
#	Global.node_creation_parent.add_child(new_tilemap) # direct child of root
#
#	# povežem s signalom	
#	Global.current_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
#
#	# grab tilemap tiles
#	Global.current_tilemap.get_tiles()
#	cell_size_x = Global.current_tilemap.cell_size.x 
#
#	printt("setam", start_strays_spawn_count)
#	Profiles.tutorial_mode = false
##	yield(Global.current_tilemap, "tilemap_completed")
#	start_strays_spawn_count = 300
#	set_game()
