extends KinematicBody2D
class_name Stray

enum States {IDLE, MOVING, DYING, WALL} # STATIC # static, unmovable ... ko je GO ali pa je poden
var current_state = States.IDLE # ni vready, da lahko setam že ob spawnu

var stray_color: Color
var visible_on_screen: bool = false
var previous_position: Vector2 = Vector2.ZERO
var step_attempt: int = 1 # začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)

onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var color_poly: Polygon2D = $ColorPoly
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var position_indicator: Node2D = $PositionIndicator
onready var position_indicator_poly: Polygon2D = $PositionIndicator/PositionPoly
onready var cell_size_x: int = Global.current_tilemap.cell_size.x
onready var step_tween: Tween = $StepTween


func _ready() -> void:
	
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	color_poly.modulate = stray_color
	modulate.a = 0
	position_indicator_poly.color = stray_color
	#	position_indicator.set_as_toplevel(true) # strayse skrijem ko so offscreen
	position_indicator.visible = false

	end_move()
	
	
func show_stray(): # kliče GM
	
	# če je pozicija res prazna						
	if current_state == States.WALL:
		die_to_wall()
	else:
		# žrebam animacijo
		var random_animation_index = randi() % 3 + 1
		var random_animation_name: String = "glitch_%s" % random_animation_index
		animation_player.play(random_animation_name)
	
	
func die(stray_in_stack_index: int, strays_in_stack_count: int):
	
	if not current_state == States.DYING:
		
		current_state = States.DYING
		
		global_position = Global.snap_to_nearest_grid(global_position) 
		Global.game_manager.remove_from_free_floor_positions(global_position)	
		
		# čakalni čas
		var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
		yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
		
		# animacije
		if strays_in_stack_count <= 3: # žrebam
			var random_animation_index = randi() % 5 + 1
			var random_animation_name: String = "die_stray_%s" % random_animation_index
			animation_player.play(random_animation_name) 
		else: # ne žrebam
			animation_player.play("die_stray")
		
		# color vanish
		var vanish_time = animation_player.get_current_animation_length()
		var vanish_tween = get_tree().create_tween()
		vanish_tween.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
		
		# run over stray
		var run_over_stray_pause: float = 0.2
		yield(get_tree().create_timer(run_over_stray_pause), "timeout")
		collision_shape.set_deferred("disabled", true)
		Global.game_manager.add_to_free_floor_positions(global_position)
		
		# na koncu animacije sledi KVEFRI in ostalo
	

func die_to_wall():
	
	current_state = States.WALL
	
	var random_animation_index = randi() % 5 + 1
	var random_animation_name: String = "die_stray_%s" % random_animation_index
	animation_player.play(random_animation_name) 
	
	# na koncu animacije sledi ostalo
	
	
# MOVEMENT ------------------------------------------------------------------------------------------------------

	
func step(step_direction: Vector2 = Vector2.DOWN):
	
	if current_state == States.IDLE:
	
		# če je pozicija prosta korakam (in restiram poiskuse, če ni pa probam v drugo smer
		var intended_position: Vector2 = global_position + step_direction * cell_size_x
		
		if Global.game_manager.is_floor_position_free(intended_position):
			
			step_attempt = 1 # reset na 1
			
			current_state = States.MOVING
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(global_position + step_direction * cell_size_x)	
					
			var step_time: float = Global.game_manager.game_settings["stray_step_time"]
			step_tween.interpolate_property(self ,"position", position, intended_position, step_time, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
			step_tween.start()
			
		else:
			# začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)
			step_attempt += 1
			if step_attempt <= 4:
				var new_direction = step_direction.rotated(deg2rad(90))
				step(new_direction)
			else:
				step_attempt = 1 # reset na 1
	

func push_stray(push_direction: Vector2, push_time: float):
	
	current_state = States.MOVING
	
	previous_position = Vector2.ZERO # prejšnja poz je nova pozicija plejerja ali straysa v vrsti
	Global.game_manager.remove_from_free_floor_positions(global_position + push_direction * cell_size_x)	
	
	var heavier_hit_delay: float = 0.0  # z delayom je porinek bolj pristen in "težak"
	var push_tween = get_tree().create_tween()
	push_tween.tween_property(self, "position", global_position + push_direction * cell_size_x, push_time / 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(heavier_hit_delay)
	push_tween.tween_callback(self, "end_move")
	
	
func pull_stray(pull_direction: Vector2, pull_time: float):
	
	current_state = States.MOVING
	
	previous_position = global_position
	Global.game_manager.remove_from_free_floor_positions(global_position + pull_direction * cell_size_x)	

	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x, pull_time)
	pull_tween.tween_callback(self, "end_move")


func end_move():
	
	if current_state == States.MOVING: # da se stanje resetira samo če ni DYING al pa WALL
		current_state = States.IDLE
	
	global_position = Global.snap_to_nearest_grid(global_position)
	
	if not previous_position == Vector2.ZERO:
		Global.game_manager.add_to_free_floor_positions(previous_position)
	
	
# UTILITI ------------------------------------------------------------------------------------------------------


func play_sound(effect_for: String):
	
	if not Global.sound_manager.game_sfx_set_to_off:
		match effect_for:
			"turning_color":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				if current_state == States.DYING: # da se ne oglaša ob obračanju v steno
					var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
					$Sounds/BlinkingStatic.get_child(random_static_index).play()
#			"stepping":
#				var random_step_index = randi() % $Sounds/Stepping.get_child_count()
#				var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()


func get_neighbor_strays_on_hit(): # kliče player on hit
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = Global.detect_collision_in_direction(direction, vision_ray)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			if not neighbor.current_state == neighbor.States.DYING:# # če je vstanju umiranja se ne šteje za soseda
				current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov

	
# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	var die_animations: Array = ["die_stray", "die_stray_1", "die_stray_2", "die_stray_3", "die_stray_4", "die_stray_5", ]
	
	if die_animations.has(anim_name):
		# če postane stena
		if current_state == States.WALL: 
			# wall color
			modulate.a = 1
			color_poly.modulate = Global.color_white_pixel
			# ugasni delovanje
			set_physics_process(false)
			position_indicator.modulate.a = 0
		# če umrje
		else: 
#			collision_shape.set_deferred("disabled", true)
			# odstrani barve iz huda in igre
			Global.game_manager.on_stray_die(self)
			call_deferred("queue_free")


func _on_Stray_tree_exiting() -> void:
	
	Global.game_manager.strays_in_game_count = - 1
	Global.game_manager.add_to_free_floor_positions(global_position)


func _on_Stray_tree_entered() -> void:
	
	Global.game_manager.remove_from_free_floor_positions(global_position)	
	Global.game_manager.strays_in_game_count = 1
	
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if stray.global_position == global_position:
			printt ("overspawn II on stray - stray tree entered", self) 
			call_deferred("queue_free")
			
	for player in get_tree().get_nodes_in_group(Global.group_players):
		if player.global_position == global_position:
			printt ("overspawn II on player - stray tree entered", self) 
			call_deferred("queue_free")


func _on_StepTween_tween_all_completed() -> void:
	
	end_move()
