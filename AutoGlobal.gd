extends Node2D


# GLOBAL NODES
var level_tilemap = null
var node_creation_parent = null
var game_manager = null
var color_indicator_parent = null # za barve v hudu
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



func instance_node (node, location, direction, parent):
# uporaba -> var bullet = instance_node(bullet_instance, global_position, get_parent()) -> bullet.scale = Vector(1,1)

	var node_instance = node.instance()
	parent.add_child(node_instance) # instance je uvrščen v določenega starša
	node_instance.global_position = location
	node_instance.global_rotation = direction # dodal samostojno

	node_instance.set_name(str(node_instance.name))  # dodal samostojno, da nima generičnega imena  z @ znakci
	print("ustvarjen node: %s" % node_instance.name)

#	add_child manjka? ... pomoje ga v funkciji dodaš
	return node_instance


func get_random_position():
# uporaba -> object.global_position = Global.get_random_position()
 
	randomize() # vedno če hočeš randomizirat
	var random_position = Vector2(rand_range(50, get_viewport_rect().size.x - 100), rand_range(50, get_viewport_rect().size.y - 100))
	return random_position


func get_random_rotation():

	randomize() # vedno če hočeš randomizirat
	var random_rotation = rand_range(-3, 3)
	return random_rotation


func get_direction_to (A_position, B_position):

	var x_to_B = B_position.x - A_position.x
	var y_to_B = B_position.y - A_position.y

	var A_direction_to_B = atan2(y_to_B, x_to_B)

	return A_direction_to_B


func get_distance_to (A_position, B_position):

	var x_to_B = B_position.x - A_position.x
	var y_to_B = B_position.y - A_position.y

	var A_distance_to_B = sqrt ((y_to_B * y_to_B) + (x_to_B * x_to_B))

	return A_distance_to_B


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
