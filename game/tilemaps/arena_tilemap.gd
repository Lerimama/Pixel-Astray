extends TileMap


signal tilemap_completed

var floor_global_positions: Array # global koordinate celic
var stray_global_positions: Array
var no_stray_global_positions: Array
var player_global_positions: Array 


func _ready() -> void:
	
	add_to_group(Global.group_tilemap)	
	Global.game_tilemap = self
	print("tilemap")


func get_tiles():
	
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
				5: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
				2: # no stray
					no_stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
				4: # player 1 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
				6: # player 2 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
	
	
	# pošljem v GM
	emit_signal("tilemap_completed", floor_global_positions, stray_global_positions, no_stray_global_positions, player_global_positions)
#	emit_signal("tilemap_completed", floor_global_positions, title_cells_global_positions)
	
func get_collision_tile_id(collider: Node2D, direction: Vector2): # collider je node ki se zaleteva in ne collision object
	
	# pozicija celice stene
	var collider_position = collider.position
	var colliding_cell_position = collider_position + direction * cell_size.x # dodamo celico v smeri gibanja, da ne izber pozicije pixla
	
	# index tileta
	var colliding_cell_grid_position: Vector2 = world_to_map(colliding_cell_position) # katera celica je bila zadeta glede na global coords
	var tile_index: int = get_cellv(colliding_cell_grid_position) # index zadete celice na poziciji v grid koordinatah
	
	return tile_index


# debug
onready var DebugIndicator = preload("res://assets/position_indicator.tscn")

func spawn_debug_indicator(current_cell_position, color):
	
	var pos_indi = DebugIndicator.instance()
	pos_indi.rect_position = current_cell_position
	pos_indi.modulate = color
	pos_indi.modulate.a = 0.5
	pos_indi.get_node("Label").text = str(current_cell_position)
	Global.node_creation_parent.add_child(pos_indi)
