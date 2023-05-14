extends Node2D


#onready var floor_map: TileMap = $FloorMap
#onready var pixel: KinematicBody2D = $Pixel
 
#var available_positions 
#var grid_cell_size


func _ready() -> void:
	
	Global.print_id(self)
	Global.node_creation_parent = self

#func _on_floor_completed(floor_cell_positions):
#
#	pixel.available_positions = floor_cell_positions
#
#
#func _on_FloorMap_floor_completed(cells_global_positions, cell_size) -> void:
#
#	available_positions = cells_global_positions 
#	grid_cell_size = cell_size


func _on_Main_PlayBtn_pressed() -> void:
	pass # Replace with function body.
