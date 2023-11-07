extends Node


onready var d_camera: Camera2D = $GameView/Viewports/ViewportContainer1/Viewport1/GameCam
onready var viewport_1: Viewport = $GameView/Viewports/ViewportContainer1/Viewport1

onready var minimap: ViewportContainer = $Minimap
onready var minimap_viewport: Viewport = $Minimap/MinimapViewport
onready var minimap_camera: Camera2D = $Minimap/MinimapViewport/MinimapCam


func _ready() -> void:
	
	get_viewport()	
	set_camera_limits()
	
	# minimapa
	if Profiles.game_rules["minimap_on"]:
		minimap.visible = true
	else:
		minimap.visible = false
	minimap_viewport.world_2d = viewport_1.world_2d
	
	# višina minimape v razmerju s formatom levela
	var rect = Global.level_tilemap.get_used_rect()
	minimap_viewport.size.y = minimap_viewport.size.x * rect.size.y / rect.size.x
	
	
func set_camera_limits():
	
	var tilemap_edge = Global.level_tilemap.get_used_rect()	
	var tilemap_cell_size = Global.level_tilemap.cell_size
	
	var corner_TL: float = tilemap_edge.position.x * tilemap_cell_size.x
	var corner_TR: float = tilemap_edge.end.x * tilemap_cell_size.x
	var corner_BL: float = tilemap_edge.position.y * tilemap_cell_size.y
	var corner_BR: float = tilemap_edge.end.y * tilemap_cell_size.y
	
	# v tem koraku odštejem tilemap edge debelino
	for camera in [minimap_camera, d_camera]:
		camera.limit_left = corner_TL + tilemap_cell_size.x 
		camera.limit_right = corner_TR - tilemap_cell_size.x
		camera.limit_top = corner_BL + tilemap_cell_size.y
		camera.limit_bottom = corner_BR - tilemap_cell_size.y

