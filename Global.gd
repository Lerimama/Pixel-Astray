extends Node2D


# GLOBAL NODES

# scene switching
#var current_scene = null # trenutno predvajana scena (za svičanje)
#var scene_reload_time: float = 1


# GLOBAL NODES ---------------------------------------------------------------------------------------------------------

var main_node = null
var sound_manager = null
var data_manager = null
var game_manager = null
var level_tilemap = null
var node_creation_parent = null # arena
var hud = null
var main_camera = null
var camera_target = null
var game_countdown = null
var gameover_menu = null
#var gameover_gui = null

# res rabm?
#var color_indicator_parent = null # za barve v hudu




# GLOBAL VARS ---------------------------------------------------------------------------------------------------------

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap"
#var group_ghosts = "Ghosts"

# sivi klin
var color_black = Color("#000000")
var color_gray0 = Color("#171a23") # najtemnejša
var color_gray1 = Color("#1d212d")
var color_gray2 = Color("#272d3d")
var color_gray3 = Color("#2f3649")
var color_gray4 = Color("#404954")
var color_gray5 = Color("#535b68") # najsvetlejša
var color_white = Color("#ffffff")

# colors
var color_blue = Color("#4b9fff")
var color_green = Color("#5effa9")
var color_red = Color("#f35b7f")
var color_yellow = Color("#fef98b")



func _ready():
	
	randomize()

func print_id (node: Node):
#	printt("Živijo! Jaz sem " + node.name + " na koordinatah " + str(node.global_position) + ".")
	pass

func snap_to_nearest_grid(current_global_position: Vector2):

	var floor_cells: Array = level_tilemap.floor_cells_global_positions
	var cell_size_x: float = level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
	
	var current_position: Vector2 = Vector2(current_global_position.x - cell_size_x/2, current_global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice, ker na koncu je itak bližja
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


func detect_collision_in_direction(ray, direction_to_check):
	
#	var floor_cells: Array = level_tilemap.floor_cells_global_positions
	var cell_size_x: int = level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
	
	ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
	ray.force_raycast_update()	
	
	if ray.is_colliding():
		var ray_collider = ray.get_collider()
		return ray_collider
		


	

#func get_random_member_index(group_of_elements, offset):
#
#		var random_range = group_of_elements.size()
#		var selected_int = randi() % int(random_range) + offset
##		var selected_value = current_array[random_int]
#
##		printt(current_array, random_range, random_int, selected_int)
#		return selected_int


# SCENE MANAGER ---------------------------------------------------------------------------

var current_scene = null # trenutno predvajana scena (za svičanje)
var scene_reload_time: float = 1

# spawn scene
func spawn_new_scene(scene_path, parent_node):

	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	printt ("SCENE INSTANCED: ", current_scene.name, current_scene)	
	
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root
	printt ("SCENE ADDED: ", current_scene.name, current_scene)	
	

# release scene
func release_scene(scene_node):
	call_deferred("_free_scene", scene_node)	

func _free_scene(scene_node):
	printt ("SCENE RELEASED (next step): ", current_scene.name, current_scene)	
	scene_node.free()

# reload scene
func reload_scene(scene_node, scene_path, parent_node):
	
	release_scene(scene_node)
	yield(get_tree().create_timer(scene_reload_time), "timeout")
	spawn_new_scene(scene_path, parent_node)
	current_scene.modulate.a = 1
	
	
	
# switch root scene

#func switch_to_scene(scene_path):
#	# This function will usually be called from a signal callback,
#	# or some other function from the running scene.
#	# Deleting the current scene at this point might be
#	# a bad idea, because it may be inside of a callback or function of it.
#	# The worst case will be a crash or unexpected behavior.
#
#	# The way around this is deferring the load to a later time, when
#	# it is ensured that no code from the current scene is running:
#	call_deferred("_deferred_goto_scene", scene_path)
	

#func _deferred_goto_scene(path):
#
#	# free current
#	print ("deleted_scene: ", current_scene)	
#	current_scene.free()
#
#
#	var new_scene = ResourceLoader.load(path)
#	current_scene = new_scene.instance()
##	main_node.add_child(current_scene) # direct child of root
#	get_tree().root.add_child(current_scene) # direct child of root
#
#	# Optionally, to make it compatible with the SceneTree.change_scene() API.
#	get_tree().current_scene = current_scene
#	print ("new_scene: ", current_scene)




## INSTANCE FROM TILEMAPS ---------------------------------------------------------------------------
#
##func create_instance_from_tilemap(coord:Vector2, prefab:PackedScene, parent: Node2D, origin_zamik:Vector2 = Vector2.ZERO):	# primer dobre prakse ... static typing
##	print("COORD")
##	print(coord)
##	$BrickSet.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
##	var pf = prefab.instance()
##	pf.position = $BrickSet.map_to_world(coord) - origin_zamik
##	parent.add_child(pf)
##	print("COORD")
##	print(coord)
