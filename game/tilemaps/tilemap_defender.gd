extends GameTilemap


onready var top_screen_limit: StaticBody2D = $TopScreenLimit
onready var bottom_screen_limit: StaticBody2D = $BottomScreenLimit
onready var left_screen_limit: StaticBody2D = $LeftScreenLimit
onready var right_screen_limit: StaticBody2D = $RightScreenLimit


func _ready() -> void:
	# namen: rob ekrana je static_body

	add_to_group(Global.group_tilemap)
	Global.current_tilemap = self

	edge_cover.modulate = Color.black
	edge_cover.hide()

	top_screen_limit.add_to_group(Global.group_tilemap)
	bottom_screen_limit.add_to_group(Global.group_tilemap)
	left_screen_limit.add_to_group(Global.group_tilemap)
	right_screen_limit.add_to_group(Global.group_tilemap)


func get_tiles():
	# namen: drugače nabere froor tile (samo no_strays in players

	tilemap_thumb.queue_free()
	get_tilemap_edge_rect()

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
				floor_tile_id: # floor
					random_spawn_floor_positions.append(cell_global_position)
					# all_floor_tiles_global_positions.append(cell_global_position)
				stray_tile_id: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
					# all_floor_tiles_global_positions.append(cell_global_position)
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
				stray_white_tile_id: # spawn wall stray
					stray_wall_global_positions.append(cell_global_position)
					stray_global_positions.append(cell_global_position) # stray wall je tudi stray pozicija
					set_cellv(cell, 0)
					# all_floor_tiles_global_positions.append(cell_global_position)

	_colorize_tilemap_elements()

	# pošljem v GM
	emit_signal("tilemap_completed", random_spawn_floor_positions, stray_global_positions, stray_wall_global_positions, no_stray_global_positions, player_global_positions)


func get_tilemap_edge_rect():
	# namen: upoštevam, da edge tiles niso najbolj zunanje

	var inside_edge_level_tiles: Rect2 = get_used_rect()
	var cell_size_x = cell_size.x

	tilemap_edge_rectangle.position.x = inside_edge_level_tiles.position.x * cell_size_x + 1 * cell_size_x
	tilemap_edge_rectangle.position.y = inside_edge_level_tiles.position.y * cell_size_x + 1 * cell_size_x
	tilemap_edge_rectangle.size.x = inside_edge_level_tiles.end.x * cell_size_x - 2 * cell_size_x
	tilemap_edge_rectangle.size.y = inside_edge_level_tiles.end.y * cell_size_x - 2 * cell_size_x # 2 * ker se pozicija zamakne

	edge_rect.rect_position.x = tilemap_edge_rectangle.position.x
	edge_rect.rect_position.y = tilemap_edge_rectangle.position.y
	edge_rect.rect_size.x = tilemap_edge_rectangle.size.x
	edge_rect.rect_size.y = tilemap_edge_rectangle.size.y
