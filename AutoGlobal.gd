extends Node2D


# GLOBAL NODES
var level_tilemap = null
var node_creation_parent = null
var game_manager = null
var color_indicator_parent = null # za barve v hudu
var camera_target = null
var player_camera = null
var hud = null
var gameover_menu = null
var level_start_position = null


# ---
var current_camera = null
var current_scene = null

func _ready():
	
	randomize()
	# za menjavo scen
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
	print ("root: ", root)
	print ("current_scene: ", current_scene)


func print_id (object):
#	print ("current_scene: ", current_scene)
#	printt("Printam ... ", object.name, object.global_position)
	pass
	

func get_random_member_index(group_of_elements, offset):

		var random_range = group_of_elements.size()
		var selected_int = randi() % int(random_range) + offset
#		var selected_value = current_array[random_int]
		
#		printt(current_array, random_range, random_int, selected_int)
		return selected_int


func switch_to_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function from the running scene.
	# Deleting the current scene at this point might be
	# a bad idea, because it may be inside of a callback or function of it.
	# The worst case will be a crash or unexpected behavior.

	# The way around this is deferring the load to a later time, when
	# it is ensured that no code from the current scene is running:
	call_deferred("_deferred_goto_scene", path)
	

func _deferred_goto_scene(path):

	# free current
#	get_tree().get_current_scene().free()
	print ("deleted_scene: ", current_scene)	
	current_scene.free()
	
	# spawn new
#	var packed_scene = ResourceLoader.load(path)
#	var instanced_scene = packed_scene.instance()
#	get_tree().get_root().add_child(instanced_scene) # direct child of root
	# set as current scene after it is added to tree
#	get_tree().set_current_scene(instanced_scene)
	
	var new_scene = ResourceLoader.load(path)
	current_scene = new_scene.instance()
	get_tree().root.add_child(current_scene) # direct child of root

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().current_scene = current_scene
	print ("new_scene: ", current_scene)




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
