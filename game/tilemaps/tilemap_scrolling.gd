extends GameTilemap


var floor_cells_count_x: int = 0
var floor_cells_count_y: int

var floor_cells_count: Vector2 = Vector2.ZERO
var edge_global_positions: Array # prepoznavanje GO
var edge_cell_side_global_positions: Array # prepoznavanje GO

var top_spawn_position_from_center: float = 368 # trenutno je center določen s plejerjem
var bottom_spawn_position_from_center: float = 368
var left_spawn_position_from_center: float = 656
var right_spawn_position_from_center: float = 688

onready var top_screen_limit: StaticBody2D = $TopScreenLimit
onready var bottom_screen_limit: StaticBody2D = $BottomScreenLimit
onready var left_screen_limit: StaticBody2D = $LeftScreenLimit
onready var right_screen_limit: StaticBody2D = $RightScreenLimit


func _ready() -> void:
	# namen: add static_body edge walls
	
	add_to_group(Global.group_tilemap) # za scrolling in patterns
	Global.current_tilemap = self

	# set_color_theme
	get_tileset().tile_set_modulate(wall_tile_id, Global.color_wall)
	get_tileset().tile_set_modulate(edge_tile_id, Global.color_edge)
#	background.color = Global.color_background
	get_tileset().tile_set_modulate(floor_tile_id, Global.color_floor)

	top_screen_limit.add_to_group(Global.group_tilemap)
	bottom_screen_limit.add_to_group(Global.group_tilemap)
	left_screen_limit.add_to_group(Global.group_tilemap)
	right_screen_limit.add_to_group(Global.group_tilemap)
