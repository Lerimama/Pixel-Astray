extends Node2D




onready var floor_map: TileMap = $FloorMap
onready var pixel: KinematicBody2D = $Pixel

 
var available_positions 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Global.node_creation_parent = self
	
	print("Jest sem ... ", name)
#	floor_map.connect("floor_completed", self, "_on_floor_completed")
	
	pass # Replace with function body.

func _on_floor_completed(floor_cell_positions):
#	print("floor_cells_positions")
#	print(floor_cells_positions)
	
	pixel.available_positions = floor_cell_positions
#	print(floor_cell_positions )
#	call_deferred()
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

var te_pozicije: = 5
func _on_FloorMap_floor_completed(cells_global_positions) -> void:

	available_positions = cells_global_positions 
#	pixel.available_positions = cells_global_positions
#	print(cells_global_positions )
	pass
