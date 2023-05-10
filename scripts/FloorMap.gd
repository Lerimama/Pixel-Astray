extends TileMap

signal floor_completed (cell_global_positions)



func _ready() -> void:
	print("Jest sem ... ", name)
	get_floor_tiles()
	pass # Replace with function body.



func get_floor_tiles():
	
	# koliko celic je na celem ekranu
	var cell_count_x: float = get_viewport_rect().size.x / get_cell_size().x
	var cell_count_y: float = get_viewport_rect().size.y / get_cell_size().y
	
#	print("cell_count_x: ", cell_count_x)
#	print("cell_count_y: ", cell_count_y)
	var floor_cells_grid: Array # grid koordinate
	var floor_cells_global_positions: Array # global koordinate
	
	# prečesi vse celice na tilemapu in jim določi globalne pozicije
	for x in cell_count_x:
		for y in cell_count_y:	
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position)
			
			
			floor_cells_global_positions.append(cell_global_position)
#			var cell_index = get_cellv(cell)
#			printt (cell, cell_index, cell_global_position)
			# če bom rabil index za manipulacijo polj
			# if cell_index == -1:
			#	pass
#	print(floor_cells_global_positions)
	
	emit_signal("floor_completed", floor_cells_global_positions)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
