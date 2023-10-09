extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

export (float, 0, 1) var die_shake_power: float = 0.2
export (float, 0, 10) var die_shake_time: float = 0.4
export (float, 0, 1) var die_shake_decay: float = 0.3

enum StrayState {IDLE, WANDERING}
var current_stray_state

var pixel_color: Color
var neighbouring_cells: Array = [] # stray stalno čekira sosede
var step_time: float = 0.1
var is_stepping: bool = false

onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var stepping_timer: Timer = $SteppingTimer
onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

	
func _ready() -> void:
	
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	current_stray_state = StrayState.IDLE  
	modulate = pixel_color
	modulate.a = 0
	

func fade_in(): # kliče GM
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	

func _physics_process(delta: float) -> void:

	match current_stray_state:
		StrayState.IDLE:
			neighbouring_cells = check_for_neighbours()
		StrayState.WANDERING:
			if is_stepping:
				return
			is_stepping = true
			var random_pause_time_factor: float = randi() % int(50) + 1 # višji offset da manjši razpon v random času
			var random_pause_time = 500 / random_pause_time_factor
			stepping_timer.start(random_pause_time)


func step(step_direction):
	
	if Global.detect_collision_in_direction(vision_ray, step_direction): # če kolajda izbrani smeri gibanja
		return
	global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.tween_callback(Global, "snap_to_nearest_grid", [global_position, Global.level_tilemap.floor_cells_global_positions])
	step_tween.tween_property(self, "is_stepping", false, 0.01)


func die(stray_in_row):
	
	collision_shape_2d.disabled = true
	emit_signal("stat_changed", self, "stray_hit", stray_in_row)
	
	# žrebam animacijo
	var random_animation_index = randi() % 5 + 1
	var random_animation_name: String = "die_stray_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	# KVEFRI je v animaciji
	
	
func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")


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


func _on_SteppingTimer_timeout() -> void:
	
	var random_direction_index: int = randi() % int(4)
	var stepping_direction: Vector2
	match random_direction_index:
		0: stepping_direction = Vector2.LEFT
		1: stepping_direction = Vector2.UP
		2: stepping_direction = Vector2.RIGHT
		3: stepping_direction = Vector2.DOWN
	step(stepping_direction)
