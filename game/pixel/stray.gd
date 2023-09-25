extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

export (float, 0, 1) var die_shake_power: float = 0.2
export (float, 0, 10) var die_shake_time: float = 0.4
export (float, 0, 1) var die_shake_decay: float = 0.3

enum StrayStates {IDLE, WANDERING}
var current_stray_state

var pixel_color: Color
var neighbouring_cells: Array = [] # stray stalno čekira sosede
var step_time: float = 0.1 # uporabi se pri step tweenu in je nekonstanten, če je "energy_speed_mode"
var is_stepping: bool = false

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa

	
func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	current_stray_state = StrayStates.IDLE  
	modulate = pixel_color
	modulate.a = 0
	

func fade_in(): # kliče GM
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	

func _physics_process(delta: float) -> void:
	
	match current_stray_state:
		StrayStates.IDLE:
			# stray vedno ve kdo so njegovi sosedi
			neighbouring_cells = check_for_neighbours()
		
		StrayStates.WANDERING:
			if is_stepping:
				return
			is_stepping = true
			var random_direction_index: int = randi() % int(7) # + offset
			var wandering_direction: Vector2
			match random_direction_index:
				0: wandering_direction = Vector2.LEFT
				1: wandering_direction = Vector2.UP
				2: wandering_direction = Vector2.RIGHT
				4: wandering_direction = Vector2.DOWN
				5: wandering_direction = Vector2.DOWN
				6: wandering_direction = Vector2.DOWN
				7: wandering_direction = Vector2.DOWN
#				8: wandering_direction = Vector2.DOWN
#				9: wandering_direction = Vector2.DOWN
			var random_pause_time_factor: float = randi() % int(100) + 30
			var random_pause_time = 500 / random_pause_time_factor
			yield(get_tree().create_timer(random_pause_time), "timeout")
			step(wandering_direction)
			is_stepping = false
	

func step(step_direction):
			
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not Global.detect_collision_in_direction(vision_ray, step_direction):
		
		global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
		step_tween.tween_callback(Global, "snap_to_nearest_grid", [global_position, Global.level_tilemap.floor_cells_global_positions])
	else:
		print("stray karambol")	


func die(stray_in_row):
	
	$CollisionShape2D.disabled = true
	emit_signal("stat_changed", self, "stray_hit", stray_in_row)
	# Global.main_camera.shake_camera(die_shake_power, die_shake_time, die_shake_decay)
	
	# žrebam animacijo
	var random_animation_index = randi() % 5 + 1
	var random_animation_name: String = "die_stray_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	
	# KVEFRI je v animaciji

	
func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")


func check_for_neighbours(): 
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

# warning-ignore:unassigned_variable
	var current_cell_neighbours: Array
	
	for dir in directions_to_check:
		
		if Global.detect_collision_in_direction(vision_ray, dir):
			
			# če je kolajder stray in ni self
			var neighbour = Global.detect_collision_in_direction(vision_ray, dir)
			
			if neighbour.is_in_group(Global.group_strays) and neighbour != self:
				current_cell_neighbours.append(neighbour)
				
	return current_cell_neighbours # uporaba v stalnem čekiranj sosedov
	
