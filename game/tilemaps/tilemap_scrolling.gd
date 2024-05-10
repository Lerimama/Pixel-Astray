extends GameTilemap


var floor_cells_count_x: int = 0
var floor_cells_count_y: int

var floor_cells_count: Vector2 = Vector2.ZERO
var strays_in_top_area: Array = []
var stray_in_floor_area: Array = []
var edge_global_positions: Array # prepoznavanje GO
var edge_cell_side_global_positions: Array # prepoznavanje GO


func get_tiles():
	# namen: prepoznavanje edge tileta za preverjanje gameoverja
	# namen: za dodajanje med tla, da stray lahko gre čez
	
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
		if Global.game_manager.game_settings["solutions_mode"]:
#			$SolutionLine.modulate = Color("#0a0a0a")
			$SolutionLine.modulate = Global.color_almost_black
		else:
			$SolutionLine.hide()
	
	# prečesi vse celice in določi globalne pozicije
	for x in get_used_rect().size.x: # širina v celicah
		for y in get_used_rect().size.y: # višina širina v celicah	 
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position) # pozicija je levo-zgornji vogal celice
			
			# zaznavanje tiletov
			var cell_index = get_cellv(cell)
			match cell_index:
				0: # floor
					floor_global_positions.append(cell_global_position)
					random_spawn_floor_positions.append(cell_global_position)
				5: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
					floor_global_positions.append(cell_global_position)
				2: # no stray
					no_stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
				4: # player 1 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
				6: # player 2 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
				1: # edge cells
					floor_global_positions.append(cell_global_position)
					edge_global_positions.append(cell_global_position)
					
					# pripnem 4 strani celice
					var position_up: Vector2 = cell_global_position - Vector2(0, cell_size.x)
					var position_down: Vector2 = cell_global_position + Vector2(0, cell_size.x)
					var position_left: Vector2 = cell_global_position - Vector2(cell_size.x, 0)
					var position_right: Vector2 = cell_global_position + Vector2(cell_size.x, 0)
#					if cell_global_position.y < 0: # je gor
#						edge_cell_side_global_positions.append(position_down)
#					elif cell_global_position.y > 0: # je dol
#						edge_cell_side_global_positions.append(position_up)
#					elif cell_global_position.x < 0: # je na levi
#						edge_cell_side_global_positions.append(position_right)
#					elif cell_global_position.x > 0: # je na desni
#						edge_cell_side_global_positions.append(position_left)
				
					var top_spawn_position_y: float = -368 + cell_size.x/2
					var bottom_spawn_position_y: float = 368 - cell_size.x/2
					var left_spawn_position_x: float = - 656 + cell_size.x/2
					var right_spawn_position_x: float = 688 - cell_size.x/2
					if cell_global_position.y == top_spawn_position_y: # je gor
						edge_cell_side_global_positions.append(position_down)
					elif cell_global_position.y == bottom_spawn_position_y: # je dol
						edge_cell_side_global_positions.append(position_up)
					elif cell_global_position.x == left_spawn_position_x: # je na levi
						edge_cell_side_global_positions.append(position_right)
					elif cell_global_position.x == right_spawn_position_x: # je na desni
						edge_cell_side_global_positions.append(position_left)
					
	
	# pošljem v GM
	emit_signal("tilemap_completed", random_spawn_floor_positions, stray_global_positions, no_stray_global_positions, player_global_positions)
	
	
	
func _on_TopArea_body_entered(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		strays_in_top_area.append(body)


func _on_TopArea_body_exited(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		strays_in_top_area.erase(body)
	

func _on_FloorArea_body_entered(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		stray_in_floor_area.append(body)

		
func _on_FloorArea_body_exited(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		stray_in_floor_area.erase(body)
		body.queue_free()
