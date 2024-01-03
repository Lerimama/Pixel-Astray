extends KinematicBody2D

enum States {IDLE, MOVING}
var current_state # = States.IDLE

var stray_color: Color
#var neighboring_cells: Array = []
var is_stepping: bool = false

onready var extended_shape: CollisionShape2D = $CollisionShapeExt
onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
onready var vision_rays: Array = [$Vision/VisionRay1, $Vision/VisionRay2, $Vision/VisionRay3]
onready var vision: Node2D = $Vision
onready var color_poly: Polygon2D = $ColorPoly
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var count_label: Label = $CountLabel # debug
onready var cell_size_x: int = Global.game_tilemap.cell_size.x


func _ready() -> void:
	
	add_to_group(Global.group_strays)

	randomize() # za random die animacije
	
	current_state = States.IDLE
	
	color_poly.modulate = stray_color
	modulate.a = 0
	count_label.text = name


func fade_in(): # kliče GM
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name)


func step(step_direction: Vector2):
	
	if detect_collision_in_direction(step_direction) or current_state == States.MOVING: # če kolajda izbrani smeri gibanja ali je "moving"
		return
	
	current_state = States.MOVING
	extended_shape.position = step_direction * cell_size_x # vržem koližn v smer premika
	var step_time: float = 0.2
	
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(extended_shape, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")


func end_move():
	
	current_state = States.IDLE
	global_position = Global.snap_to_nearest_grid(global_position, Global.game_manager.floor_positions) 
	
		
func die(stray_in_stack_index: int, strays_in_stack: int):
	
	end_move()
	
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
	extended_shape.disabled = true
	# KVEFRI je v animaciji


# UTILITI ------------------------------------------------------------------------------------------------------


func play_blinking_sound():
	
	Global.sound_manager.play_sfx("blinking")


func check_for_neighbors(): # kliče player on hit
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


func detect_collision_in_direction(direction_to_check):
	
	# obrnem vision grupo v smeri...
	vision.look_at(global_position + direction_to_check)
	
	# vsi ray gledajo naravnost
	for ray in vision_rays:
		ray.cast_to = Vector2(47, 0) # en pixel manj kot 48, da ne seže preko celice
	
	# grebanje kolajderja	
	var first_collider: Node2D
	for ray in vision_rays:
		ray.add_exception(self)
		ray.force_raycast_update()
		if ray.is_colliding():
			first_collider = ray.get_collider()
			break # ko je kolajder neham čekirat
	
	return first_collider
