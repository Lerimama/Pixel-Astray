extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

var pixel_color: Color
var neighbouring_cells: Array = [] # stray stalno čekira sosede

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay

# glow in dihanje
#var breath_speed: float = 1.2
#var tired_breath_speed: float = 2.4


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Global.group_strays)
	
	modulate = pixel_color
	randomize() # za random die animacije
	global_position = Global.snap_to_nearest_grid(global_position)


func _physics_process(delta: float) -> void:
	
	# stray vedno ve kdo so njegovi sosedi
	neighbouring_cells = check_for_neighbours()


func die():
	
	emit_signal("stat_changed", self, "off_pixels_count", 1)
	Global.main_camera.stray_die_shake()		
	
	# žrebam animacijo
	var random_animation_index = randi() % 5 + 1
	var random_animation_name: String = "die_stray_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	
	# KVEFRI je v animaciji


func check_for_neighbours(): 
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbours: Array
	
	for dir in directions_to_check:
		
		if Global.detect_collision_in_direction(vision_ray, dir):
			
			# če je kolajder stray in ni self
			var neighbour = Global.detect_collision_in_direction(vision_ray, dir)
			
			if neighbour.is_in_group(Global.group_strays) and neighbour != self:
				current_cell_neighbours.append(neighbour)
				
	return current_cell_neighbours # uporaba v stalnem čekiranj sosedov
	
