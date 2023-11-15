extends TileMap


signal tilemap_completed #(floor_tiles_global_positions, player_start_global_position)

var floor_cells_global_positions: Array
var title_cells_global_positions: Array


func _ready() -> void:
	
	add_to_group(Global.group_tilemap)	
	Global.game_tilemap = self
	get_tiles()


func get_tiles():
	
	# prečesi vse celice in določi globalne pozicije
	for x in get_used_rect().size.x: # širina v celicah
		for y in get_used_rect().size.y: # višina širina v celicah	 
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position)
			
			# zaznavanje tiletov
			var cell_index = get_cellv(cell)
			match cell_index:
				0: # floor
					floor_cells_global_positions.append(cell_global_position)
				5: # game title positions ... stray start positions
					title_cells_global_positions.append(cell_global_position + cell_size/2) # more bit +, če ne zignjajo
					floor_cells_global_positions.append(cell_global_position) # se dodajo, ker so tla istočasno prostor za premikanje

	# pošljemo podatke v GM
	emit_signal("tilemap_completed", floor_cells_global_positions, title_cells_global_positions)
	

func get_collision_tile_id(collider: Node2D, direction: Vector2): # collider je node ki se zaleteva in ne collision object
	
	# pozicija celice stene
	var collider_position = collider.position
	var colliding_cell_position = collider_position + direction * cell_size.x # dodamo celico v smeri gibanja, da ne izber pozicije pixla
	
	# index tileta
	var colliding_cell_grid_position: Vector2 = world_to_map(colliding_cell_position) # katera celica je bila zadeta glede na global coords
	var tile_index: int = get_cellv(colliding_cell_grid_position) # index zadete celice na poziciji v grid koordinatah
	
	return tile_index
