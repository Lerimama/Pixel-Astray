extends GameTilemap


var floor_cells_count_x: int = 0
var floor_cells_count_y: int

var floor_cells_count: Vector2 = Vector2.ZERO
var edge_global_positions: Array # prepoznavanje GO
var edge_cell_side_global_positions: Array # prepoznavanje GO

onready var top_screen_limit: StaticBody2D = $TopScreenLimit
onready var bottom_screen_limit: StaticBody2D = $BottomScreenLimit
onready var left_screen_limit: StaticBody2D = $LeftScreenLimit
onready var right_screen_limit: StaticBody2D = $RightScreenLimit
onready var edge_cover: Node2D = $EdgeCover


func _ready() -> void:
	# namen: rob ekrana je static_body
	
	add_to_group(Global.group_tilemap)
	Global.current_tilemap = self

	# set_color_theme
	get_tileset().tile_set_modulate(wall_tile_id, Global.color_wall)
	get_tileset().tile_set_modulate(edge_tile_id, Global.color_edge)
	get_tileset().tile_set_modulate(floor_tile_id, Global.color_floor)

	top_screen_limit.add_to_group(Global.group_tilemap)
	bottom_screen_limit.add_to_group(Global.group_tilemap)
	left_screen_limit.add_to_group(Global.group_tilemap)
	right_screen_limit.add_to_group(Global.group_tilemap)



func get_tiles():
	# namen: drugače nabere froor tile (samo no_strays in players
	
	var inside_edge_level_tiles: Rect2 = get_used_rect()
	var cell_size_x = cell_size.x
	inside_edge_level_rect.position.x = inside_edge_level_tiles.position.x * cell_size_x + cell_size_x
	inside_edge_level_rect.size.x = inside_edge_level_tiles.end.x * cell_size_x + cell_size_x
	inside_edge_level_rect.position.y = inside_edge_level_tiles.position.y * cell_size_x + cell_size_x
	inside_edge_level_rect.size.y = inside_edge_level_tiles.end.x * cell_size_x + cell_size_x
	
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
#					all_floor_tiles_global_positions.append(cell_global_position)
					random_spawn_floor_positions.append(cell_global_position)
				5: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
#					all_floor_tiles_global_positions.append(cell_global_position)
				2: # no stray
					no_stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					all_floor_tiles_global_positions.append(cell_global_position)
				4: # player 1 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					all_floor_tiles_global_positions.append(cell_global_position)
				6: # player 2 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					all_floor_tiles_global_positions.append(cell_global_position)
				7: # spawn wall stray
					stray_wall_global_positions.append(cell_global_position)
					stray_global_positions.append(cell_global_position) # stray wall je tudi stray pozicija
					set_cellv(cell, 0)
#					all_floor_tiles_global_positions.append(cell_global_position)
					
	
	# pošljem v GM
	emit_signal("tilemap_completed", random_spawn_floor_positions, stray_global_positions, stray_wall_global_positions, no_stray_global_positions, player_global_positions)
