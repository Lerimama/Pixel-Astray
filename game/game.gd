extends Node


onready var game_camera: Camera2D = $GameView/Viewports/ViewportContainer1/Viewport1/GameCam
onready var game_camera_2: Camera2D = $GameView/Viewports/ViewportContainer2/Viewport2/GameCam
onready var viewport_1: Viewport = $GameView/Viewports/ViewportContainer1/Viewport1
onready var viewport_2: Viewport = $GameView/Viewports/ViewportContainer2/Viewport2
onready var viewport_container_1: ViewportContainer = $GameView/Viewports/ViewportContainer1
onready var viewport_container_2: ViewportContainer = $GameView/Viewports/ViewportContainer2
onready var viewport_separator: VSeparator = $GameView/Viewports/ViewportSeparator

onready var minimap: ViewportContainer = $Minimap
onready var minimap_viewport: Viewport = $Minimap/MinimapViewport
onready var minimap_camera: Camera2D = $Minimap/MinimapViewport/MinimapCam


func _ready() -> void:
	get_viewport()	
	set_camera_limits()
	
	# minimapa
	if Global.game_manager.game_settings["minimap_on"]:
		minimap.visible = true
		minimap_viewport.world_2d = viewport_1.world_2d
		# višina minimape v razmerju s formatom tilemapa
		var rect = Global.game_tilemap.get_used_rect()
		minimap_viewport.size.y = minimap_viewport.size.x * rect.size.y / rect.size.x
	else:
		minimap.visible = false
	
	# multiplejer setup
	if Profiles.current_game == Profiles.Games.DUEL:
		viewport_2.world_2d = viewport_1.world_2d
		viewport_container_2.visible = true
	else:
		viewport_container_2.visible = false
		viewport_separator.visible = false

	
func set_camera_limits():
	
	var tilemap_edge = Global.game_tilemap.get_used_rect()	
	var tilemap_cell_size = Global.game_tilemap.cell_size
	
	var corner_TL: float = tilemap_edge.position.x * tilemap_cell_size.x
	var corner_TR: float = tilemap_edge.end.x * tilemap_cell_size.x
	var corner_BL: float = tilemap_edge.position.y * tilemap_cell_size.y
	var corner_BR: float = tilemap_edge.end.y * tilemap_cell_size.y
	
	# v tem koraku odštejem tilemap edge debelino
	for camera in [minimap_camera, game_camera, game_camera_2]:
		camera.limit_left = corner_TL + tilemap_cell_size.x 
		camera.limit_right = corner_TR - tilemap_cell_size.x
		camera.limit_top = corner_BL + tilemap_cell_size.y
		camera.limit_bottom = corner_BR - tilemap_cell_size.y
