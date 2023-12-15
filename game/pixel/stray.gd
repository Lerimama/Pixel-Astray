extends KinematicBody2D


export (float, 0, 1) var die_shake_power: float = 0.2
export (float, 0, 10) var die_shake_time: float = 0.4
export (float, 0, 1) var die_shake_decay: float = 0.3

var stray_color: Color
var neighboring_cells: Array = [] # stray stalno čekira sosede
var step_time: float = 0.1
var is_stepping: bool = false

onready var cell_size_x: int = Global.game_tilemap.cell_size.x
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# debug
onready var count_label: Label = $CountLabel
onready var color_poly: Polygon2D = $ColorPoly

#onready var glow_light: Light2D = $GlowLight
	
	
func _ready() -> void:
	
	add_to_group(Global.group_strays)

	randomize() # za random die animacije
	
	color_poly.modulate = stray_color
	modulate.a = 0
	count_label.text = name


func fade_in(): # kliče GM
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name)
	
	
func step(step_direction):
#	return	
	
	if Global.detect_collision_in_direction(vision_ray, step_direction) or is_stepping: # če kolajda izbrani smeri gibanja
		return
	
	is_stepping = true
	
	global_position = Global.snap_to_nearest_grid(global_position, Global.game_manager.floor_positions)
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.tween_callback(Global, "snap_to_nearest_grid", [global_position, Global.game_manager.floor_positions])
	step_tween.tween_property(self, "is_stepping", false, 0)


func die(stray_in_stack_index, strays_in_stack: int):
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# animacije
	if strays_in_stack <= 3: # žrebam
		var random_animation_index = randi() % 5 + 1
		var random_animation_name: String = "die_stray_%s" % random_animation_index
		animation_player.play(random_animation_name) 
	else: # ne žrebam
		animation_player.play("die_stray")
	
	# color vanish
	var vanish_time = animation_player.get_current_animation_length()
	var vanish: SceneTreeTween = get_tree().create_tween()
	vanish.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	
	collision_shape_2d.disabled = true
	# KVEFRI je v animaciji


func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")


func check_for_neighbors(): 
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	
	for dir in directions_to_check:
		if Global.detect_collision_in_direction(vision_ray, dir):
			# če je kolajder stray in ni self
			var neighbor = Global.detect_collision_in_direction(vision_ray, dir)
			if neighbor.is_in_group(Global.group_strays) and neighbor != self:
				current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov
