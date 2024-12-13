extends TileMap
class_name GameTilemap

signal tilemap_completed

var all_floor_tiles_global_positions: Array # original tileti tal (samo tisto, kar je del uradnega igrišča)
var player_global_positions: Array
var stray_global_positions: Array
var stray_wall_global_positions: Array # podvrsta stray positions
var no_stray_global_positions: Array
var random_spawn_floor_positions: Array # vsi še ne zasedeni tileti, kamor se lahko potem random spawna (floor - stray - no-stray - player)
var solution_line: Line2D # opredelim popreverjanj, če je prisotna

var wall_tile_id: int = 3
var edge_tile_id: int = 1
var floor_tile_id: int = 0
var stray_tile_id: int = 5 # za home sweeper btne
var stray_white_tile_id: int = 7 # za home sweeper btne
var player_tile_ids: Array = [4, 6]
var tilemap_edge_rectangle: Rect2 # velikost floor "igralne mize"

onready var camera_position_node: Position2D = $CameraPosition
onready var background_room: TextureRect = $Background/Room
onready var tilemap_background: Node2D = $Background
onready var edge_cover: Control = $EdgeCover/Edge # da se rob ne vidi na zoomin in, da se ne vidijo pixli prek roba (malo bolje je)
onready var edge_holder: Node2D = $EdgeCover # da se rob ne vidi na zoomin in, da se ne vidijo pixli prek roba (malo bolje je)


func _ready() -> void:

	add_to_group(Global.group_tilemap)
	Global.current_tilemap = self

#	edge_cover.hide()
	edge_cover.show()

	if has_node("SolutionLine"):
		solution_line = $SolutionLine
		# če je hintline prazen, se pokaže tekst
		if solution_line.points.empty():
			solution_line.get_node("NoSolutionHint").show()
			solution_line.get_node("Dots").hide()
		else:
			solution_line.get_node("NoSolutionHint").hide()
			solution_line.get_node("Dots").show()


func get_tiles():

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
				0: # floor
					all_floor_tiles_global_positions.append(cell_global_position)
					random_spawn_floor_positions.append(cell_global_position)
				5: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
					all_floor_tiles_global_positions.append(cell_global_position)
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
					all_floor_tiles_global_positions.append(cell_global_position)


	_colorize_tiles()

	# pošljem v GM
	emit_signal("tilemap_completed", random_spawn_floor_positions, stray_global_positions, stray_wall_global_positions, no_stray_global_positions, player_global_positions)


func _colorize_tiles():

	get_tileset().tile_set_modulate(wall_tile_id, Global.color_wall)
	get_tileset().tile_set_modulate(floor_tile_id, Global.color_floor)

	# tilemap edge
	match Global.game_manager.game_data["game"]:
		# manjši ekran
		Profiles.Games.ERASER_XS, Profiles.Games.ERASER_S:
			# ga obarvam drugače da je viden
			get_tileset().tile_set_modulate(edge_tile_id, Global.color_almost_black)
			edge_cover.hide()
		# večji ekran (+ defender vogali
		Profiles.Games.CLEANER, Profiles.Games.ERASER_L, Profiles.Games.ERASER_XL:
			get_tileset().tile_set_modulate(edge_tile_id, Color.black)
			edge_cover.show()
		# fit
		_:
			get_tileset().tile_set_modulate(edge_tile_id, Color.black)
			edge_cover.hide()


func get_tilemap_edge_rect():

	var inside_edge_level_tiles: Rect2 = get_used_rect()
	var cell_size_x = cell_size.x

	tilemap_edge_rectangle.position.x = inside_edge_level_tiles.position.x * cell_size_x# + cell_size_x
	tilemap_edge_rectangle.position.y = inside_edge_level_tiles.position.y * cell_size_x# + cell_size_x
	tilemap_edge_rectangle.size.x = inside_edge_level_tiles.end.x * cell_size_x# - 2 * cell_size_x
	tilemap_edge_rectangle.size.y = inside_edge_level_tiles.end.y * cell_size_x# - 2 * cell_size_x # 2 * ker se pozicija zamakne

	edge_cover.rect_position.x = tilemap_edge_rectangle.position.x
	edge_cover.rect_position.y = tilemap_edge_rectangle.position.y
	edge_cover.rect_size.x = tilemap_edge_rectangle.size.x
	edge_cover.rect_size.y = tilemap_edge_rectangle.size.y


func get_collision_tile_id(collider: Node2D, direction: Vector2): # collider je node ki se zaleteva in ne collision object

	# pozicija celice stene
	var collider_position = collider.position
	var colliding_cell_position = collider_position + direction * cell_size.x # dodamo celico v smeri gibanja, da ne izber pozicije pixla

	# index tileta
	var colliding_cell_grid_position: Vector2 = world_to_map(colliding_cell_position) # katera celica je bila zadeta glede na global coords
	var tile_index: int = get_cellv(colliding_cell_grid_position) # index zadete celice na poziciji v grid koordinatah

	return tile_index
