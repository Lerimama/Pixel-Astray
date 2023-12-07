extends Camera2D


#var camera_target: Node2D
#
#
#func _physics_process(delta: float) -> void:
#
#	if camera_target:
#		position = camera_target.position
		

			
func set_camera(tilemap_edge: Rect2, tilemap_cell_size: Vector2, viewport_size: Vector2):	
	
	var corner_TL: float = tilemap_edge.position.x * tilemap_cell_size.x + tilemap_cell_size.x # k mejam prištejem edge debelino
	var corner_TR: float = tilemap_edge.end.x * tilemap_cell_size.x - tilemap_cell_size.x
	var corner_BL: float = tilemap_edge.position.y * tilemap_cell_size.y + tilemap_cell_size.y
	var corner_BR: float = tilemap_edge.end.y * tilemap_cell_size.y - tilemap_cell_size.y
	
	# limits
	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR
	
	# zoom
	zoom.x = (limit_right - tilemap_cell_size.x) / viewport_size.x
	zoom.y = zoom.x # (limit_bottom - tilemap_cell_size.x) / viewport_size.y
	
#	printt ("zoom_razmerje x", zoom.x, limit_left, limit_right, viewport_size.x )
#	printt ("zoom_razmerje y", zoom.y, limit_top, limit_bottom, viewport_size.y )
