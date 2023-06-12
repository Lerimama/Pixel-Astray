extends Node2D


# GLOBAL NODES
var main_node = null
var sound_manager = null

var game_manager = null
var level_tilemap = null
var node_creation_parent = null # arena
var hud = null

var main_camera = null
var camera_target = null

# scene switching
var current_scene = null # trenutno predvajana scena (za svičanje)
var scene_reload_time: float = 1

# res rabm?
var color_indicator_parent = null # za barve v hudu
var gameover_menu = null
#var current_camera = null # za tarčo
#var level_start_position = null




func _ready():
	
	randomize()
	
	# za menjavo scen
#	var root = get_tree().root
#	current_scene = root.get_child(root.get_child_count() - 1)
#
#	print ("root: ", root)
#	print ("current_scene: ", current_scene)


func print_id (object):
#	print ("current_scene: ", current_scene)
#	printt("Printam ... ", object.name, object.global_position)
	pass
	

#func get_random_member_index(group_of_elements, offset):
#
#		var random_range = group_of_elements.size()
#		var selected_int = randi() % int(random_range) + offset
##		var selected_value = current_array[random_int]
#
##		printt(current_array, random_range, random_int, selected_int)
#		return selected_int


#func snap_to_nearest_grid(current_global_position, cell_width, floor_cells):
#
#	var current_position = Vector2(current_global_position.x - cell_width/2, current_global_position.y - cell_width/2)
#
#	# če ni že snepano
#	if not floor_cells.has(current_position): 
#		# določimo distanco znotraj katere preverjamo bližino točke
#		var distance_to_position: float = cell_width # začetna distanca je velikosti celice, ker na koncu je itak bližja
#		var nearest_cell: Vector2
#		for cell in floor_cells:
#			if cell.distance_to(current_position) < distance_to_position:
#				distance_to_position = cell.distance_to(current_position)
#				nearest_cell = cell
#
#		# snap it
#		return Vector2(nearest_cell.x + cell_width/2, nearest_cell.y + cell_width/2)




# SCENE MANAGER

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
