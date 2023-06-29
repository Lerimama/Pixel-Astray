extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

export (float, 0, 1) var die_shake_power: float = 0.2
export (float, 0, 10) var die_shake_time: float = 0.4
export (float, 0, 1) var die_shake_decay: float = 0.3

var pixel_color: Color
var neighbouring_cells: Array = [] # stray stalno čekira sosede
var stray_die_value: int = 1 # def = 1, če ima sosede se duplicira

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	modulate = pixel_color
	modulate.a = 0
	
	global_position = Global.snap_to_nearest_grid(global_position)
	
	#fade_in() ... kliče se iz GM


func fade_in():
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name) 


func _physics_process(delta: float) -> void:
	
	# stray vedno ve kdo so njegovi sosedi
	neighbouring_cells = check_for_neighbours()


func die():
	
	emit_signal("stat_changed", self, "off_pixels_count", stray_die_value)
	# Global.main_camera.shake_camera(die_shake_power, die_shake_time, die_shake_decay)
	
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
	
