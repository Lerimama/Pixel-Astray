extends TileMap


signal floor_completed (floor_tiles_global_positions, player_start_global_position)


var floor_cells_global_positions: Array # global koordinate celic
var player_start_global_position: Vector2 


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Global.group_tilemap)	
	
	Global.level_tilemap = self
	
	get_floor_tiles()


func get_floor_tiles():
	
	
	# prečesi vse celice in določi globalne pozicije
	for x in get_used_rect().size.x: # širina v celicah
		for y in get_used_rect().size.y: # višina širina v celicah	 
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position)
	
			
	# zaznavanje tiletov ----------------------------------------------------------------------------
			
			var cell_index = get_cellv(cell)
			
			match cell_index:
			
				0: # floor
					floor_cells_global_positions.append(cell_global_position)
				4:# player start position
					set_cellv(cell, 0)
					floor_cells_global_positions.append(cell_global_position) # v GM damo to pozicijo ven da ni na voljo za generacij pixlov
					player_start_global_position = cell_global_position + cell_size
	
	# pošljemo podatk v GM
	emit_signal("floor_completed", floor_cells_global_positions, player_start_global_position)


	
	
	
