extends GameManager


func _ready() -> void:

	Global.game_manager = self
	
	StrayPixel = preload("res://game/pixel/stray_class.tscn")
	PlayerPixel = preload("res://game/pixel/player_patterns.tscn")
	
	randomize()


func game_over(gameover_reason: int):
	# namen: adaptacija cleaned gameoverja
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if game_data["game"] == Profiles.Games.AMAZE:
		if gameover_reason == GameoverReason.CLEANED: # če zadaneš goal steno
			# animacija indikatorjev
			Global.hud.deactivate_all_indicators()
			# ugasnem goal stene
			for cell in Global.current_tilemap.get_used_cells_by_id(7):
				Global.current_tilemap.set_cellv(cell, 0) # menjam za celico tal
				var cell_local_position: Vector2 = Global.current_tilemap.map_to_world(cell)
				var cell_global_position: Vector2 = Global.current_tilemap.to_global(cell_local_position) # pozicija je levo-zgornji vogal celice
				Global.current_tilemap.floor_global_positions.append(cell_global_position)
			# player white animacija
			var signaling_player: KinematicBody2D
			for player in get_tree().get_nodes_in_group(Global.group_players):
				player.all_cleaned()
				signaling_player = player # da se zgodi na obeh plejerjih istočasno
			yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
		
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		if gameover_reason == GameoverReason.CLEANED: # vsi spucani v enem poskusu
			# počaka da so vsi streyi kvefijani
			all_strays_died_alowed = true
			yield(self, "all_strays_died")
			# player white animacija
			var signaling_player: KinematicBody2D
			for player in get_tree().get_nodes_in_group(Global.group_players):
				player.all_cleaned()
				signaling_player = player # da se zgodi na obeh plejerjih istočasno
			yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	stop_game_elements()
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
func set_game_view():
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"
	
	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start
	
	if start_players_count == 2:
		viewport_container_2.visible = true
		viewport_2.world_2d = viewport_1.world_2d
		Global.player2_camera.position = player_start_positions[1] + cell_align_start
	else:
		viewport_container_2.visible = false
		viewport_separator.visible = false
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	get_tree().call_group(Global.group_player_cameras, "set_camera_limits")
	
	# minimap
	var minimap_container: ViewportContainer = $"../Minimap"
	var minimap_viewport: Viewport = $"../Minimap/MinimapViewport"
	var minimap_camera: Camera2D = $"../Minimap/MinimapViewport/MinimapCam"	
	
	if Global.game_manager.game_settings["minimap_on"]:
		minimap_container.visible = true
		minimap_viewport.world_2d = viewport_1.world_2d
		minimap_viewport.size.y = minimap_viewport.size.x * tilemap_edge.size.y / tilemap_edge.size.x # višina minimape v razmerju s formatom tilemapa
		minimap_camera.set_camera(tilemap_edge, cell_size_x, minimap_viewport.size)
	else:
		minimap_container.visible = false	
#
#func _on_tilemap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array) -> void:
#	# namen: ciljni stray
#
#	# opredelim tipe pozicij
#	random_spawn_positions = random_spawn_floor_positions
#	required_spawn_positions = stray_cells_positions
#	player_start_positions = player_cells_positions
#
#	# start strays count setup
#	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
#		game_data["strays_start_count"] = required_spawn_positions.size()
#
#	# preventam preveč straysov (več kot je možnih pozicij)
#	if game_data["strays_start_count"] > random_spawn_positions.size() + required_spawn_positions.size():
#		game_data["strays_start_count"] = random_spawn_positions.size()/2 + required_spawn_positions.size()
#
#	# če ni pozicij, je en player ... random pozicija
#	if player_start_positions.empty():
#		var random_range = random_spawn_positions.size() 
#		print(random_range)
#		var p1_selected_cell_index: int = randi() % int(random_range) + 1
#		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
#		random_spawn_positions.remove(p1_selected_cell_index)
#
#	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
