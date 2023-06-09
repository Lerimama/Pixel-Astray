extends TileMap


signal floor_completed (floor_tiles_global_positions)


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Config.group_tilemap)	
	
	Global.level_tilemap = self

	
	# pogrebam celice tal
	get_floor_tiles()


func get_floor_tiles():
	
	var floor_cells_grid: Array # grid koordinate celic
	var floor_cells_global_positions: Array # global koordinate celic
	
	# prečesi vse celice na tilemapu in jim določi globalne pozicije
	for x in get_used_rect().size.x: # širina v celicah
		for y in get_used_rect().size.y: # višina širina v celicah	 
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position)
			
			var cell_index = get_cellv(cell)
			if cell_index == 0: # 0 je celica tal
				floor_cells_global_positions.append(cell_global_position)
	
	emit_signal("floor_completed", floor_cells_global_positions)

