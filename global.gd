extends Node2D


## konstantne variable in metode

# VARS ----------------------------------------------------------

var main_node = null
var node_creation_parent = null # arena

# managers
var sound_manager = null
var data_manager = null
var game_manager = null # tudi za intro

# gui
var current_tilemap = null
var hud = null
var start_countdown = null
var gameover_menu = null
var tutorial_gui = null

# camera
var intro_camera = null
var player1_camera = null
var player2_camera = null

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap"
var group_player_cameras = "Player Cameras"
var group_ghosts = "Ghosts"

# colors
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")

var color_white: Color = Color("#ffffff")
var hud_text_color: Color = Color("#fafafa")

# reference ... niso v kodi
var color_almost_black: Color = Color("#141414") # start player, wall, floor
var color_gray_dark: Color = Color("#232323")
var color_gui_gray: Color = Color("#838383") # siva v tekstih (naslovi) in ikonah
var hud_background_color: Color = Color("#141414")


# FUNKCIJE -----------------------------------------------------------------------------------------------------


func snap_to_nearest_grid(current_global_position: Vector2):
#func snap_to_nearest_grid(current_global_position: Vector2, floor_cells: Array):
	
	if not is_instance_valid(current_tilemap):
		print("ERROR! Snapanje na grid ... manjka Global.current_tilemap")
		
	var floor_cells: Array = current_tilemap.floor_global_positions
	var cell_size_x: float = current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
	
	# adaptacija zaradi središčne točke strejsa in playerja
	var current_position: Vector2 = Vector2(current_global_position.x - cell_size_x/2, current_global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice ... potem izbrana je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell
		# snap position
		var snap_to_position: Vector2 = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)
		return snap_to_position
	else: 
		return current_global_position # vrneš isto pozicijo na katere že je 

		
func detect_collision(ray, direction_to_check, ignore):
	
	var cell_size_x: int = current_tilemap.cell_size.x #+ current_tilemap.cell_size.x/2 # pogreba od GMja, ki jo dobi od tilemapa
	
	ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
	ray.force_raycast_update()	
	
	if ray.is_colliding():
		var ray_collider = ray.get_collider()
		
#		print("ray colider ", ray_collider)
		if ray_collider.is_in_group(Global.group_ghosts) or ignore:
			return null 	
		else: 
			return ray_collider

				
func detect_group_collision_in_direction(ray_group, direction_to_check):
	
	var cell_size_x: int = current_tilemap.cell_size.x #+ current_tilemap.cell_size.x/2 # pogreba od GMja, ki jo dobi od tilemapa
	var current_colliders: Array 
	print("current_colliders 1 ", current_colliders)
	
	for ray in ray_group:
#		if ray_group.find(ray) == 0:
#			pass
#		if ray_group.find(ray) == 1:
#			ray.position.x = direction_to_check.x -16
#			ray.position.y = direction_to_check.y + 16
#		if ray_group.find(ray) == 2:
#			pass
##			ray.position.x = direction_to_check.x + 16
##			ray.position.y = direction_to_check.y - 16
#		ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
#		ray.position.y = direction_to_check.y - ray_group.find(ray) * -16
		pass
		
	for ray in ray_group:
		ray.force_raycast_update()
		if ray.is_colliding():
			var ray_collider = ray.get_collider()
			current_colliders.append(ray_collider)
#			print("ray colider ", ray_collider)
#			return [ray_collider]
	
#	print("current_colliders ", current_colliders)
	return current_colliders
#			break
			
					
func detect_collision_in_direction(ray, direction_to_check):
	
	var cell_size_x: int = current_tilemap.cell_size.x #+ current_tilemap.cell_size.x/2 # pogreba od GMja, ki jo dobi od tilemapa
	
	ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var ray_collider = ray.get_collider()
		if not ray_collider.is_in_group(Global.group_ghosts):
#			print("ray colider ", ray_collider)
			return ray_collider
		else: 
			return null 

# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


var current_scene = null # za scene switching


func release_scene(scene_node): # release scene
	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)	


func _free_scene(scene_node):
	print ("SCENE RELEASED (in next step): ", scene_node)	
	scene_node.free()
	

func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	print ("SCENE INSTANCED: ", current_scene)
	
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root
	print ("SCENE ADDED: ", current_scene)	
	
	return current_scene


# NI V RABI --------------------------------------------------------------------------------------------------

	
#func get_random_member_index(group_of_elements, offset): # offset je če zamakneš začetek
#		# uporabljam pri: ... nikjer
#
#		var random_range = group_of_elements.size()
#		var selected_int = randi() % int(random_range) + offset
##		var selected_value = current_array[random_int]
#
#		printt("RANDOM", random_range, selected_int)
#		return selected_int
