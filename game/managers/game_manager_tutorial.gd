extends GameManager


func set_game(): 
	
	# kliče main.gd pred prikazom igre
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
			
	
func _change_strays_in_game_count(strays_count_change: int):
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
