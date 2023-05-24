extends Node


#var active_players_count: int = 4
onready var game_view_grid: GridContainer = $GameViewGrid
onready var viewport_1: Viewport = $Viewports/ViewportContainer1/Viewport1
onready var camera_1: Camera2D = $Viewports/ViewportContainer1/Viewport1/Camera2D

onready var viewport_2: Viewport = $Viewports/ViewportContainer2/Viewport2
onready var camera_2: Camera2D = $Viewports/ViewportContainer2/Viewport2/Camera2D
onready var arena: Node2D = $Viewports/ViewportContainer1/Viewport1/Arena

onready var prvi_pixel: Node2D = $Viewports/ViewportContainer1/Viewport1/Arena/Pixel


func _ready() -> void:
	
#	viewport_1.world_2d = viewport_2.world_2d
	
#	if Global.game_manager.players_in_game.empty():
#		for player in Global.game_manager.players_in_game:
#			if player.is_in_group(Config.group_players):
#				camera_1.target = player
#	else:
	camera_1.target = prvi_pixel
#		camera_1.target = null
		
	
#func reload_scene(vp_count):
#	get_tree().reload_current_scene()
#	pass # Replace with function body.
#
#
#func _on_Button_pressed() -> void:
#	game_view_grid.active_players_count = 1
##	reload_scene(1)
#
#
#func _on_Button2_pressed() -> void:
#	game_view_grid.active_players_count = 2
##	reload_scene(2)
#
#
#func _on_Button3_pressed() -> void:
#	game_view_grid.active_players_count = 3
##	reload_scene(3)
#
#
#func _on_Button4_pressed() -> void:
#	game_view_grid.active_players_count = 4
##	reload_scene(4)
