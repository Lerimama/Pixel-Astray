extends Node2D

onready var line_2d: Line2D = $Line2D

var no_line_yet: bool = true

func _ready() -> void:
	
	Global.node_creation_parent = self
	
#	print("rect ", get_viewport_rect())
	if no_line_yet:
		no_line_yet = false
		line_2d.set_point_position(0, Vector2.ZERO)
		line_2d.set_point_position(1, Vector2.ZERO)
#			line_2d.(0, player.global_position)
	
	
func _process(delta: float) -> void:
	if get_tree().get_nodes_in_group(Global.group_players).size() == 2:
#		printt (ray_target_1, ray_target_2)
			
#		printt(line_2d.get_point_position(0),line_2d.get_point_position(1))
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if player.name == "p1":
				line_2d.set_point_position(0, player.global_position)
			elif player.name == "p2":
				line_2d.set_point_position(1, player.global_position)
#				ray_target_2 = player.position
#
#		if name == "p1":
#			ray_cast_2d.cast_to = ray_target_2 - ray_cast_2d.global_position
#			ray_cast_2d.cast_to.x = clamp(ray_cast_2d.cast_to.x, 20, 200)
#			ray_cast_2d.cast_to.y = clamp(ray_cast_2d.cast_to.y, 20, 200)
#		elif name == "p2":
#			ray_cast_2d.cast_to = ray_target_2
#		line_2d.add_point(get_parent().global_position)
#	line_2d.add_point(gun_target.global_position)
