extends Stray

# spawn strani
enum Sides {TOP, BOTTOM, RIGHT, LEFT}
var stray_spawn_side: int 
var top_spawn_position_y: float = -368
var bottom_spawn_position_y: float = 368
var left_spawn_position_x: float = -656
var right_spawn_position_x: float = 688

var step_count: int = 0 # da vidim kdaj je prek meje
var stray_crossed_wall_step_limit: int = 2


func _ready() -> void:
	 # namen: grupiranje glede na izvorno stran	
	
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	color_poly.modulate = stray_color
	modulate.a = 0
	position_indicator.get_node("PositionPoly").color = stray_color
	count_label.text = name
	position_indicator.visible = false

#	printt ("SP", global_position)
	
	if global_position.y <= top_spawn_position_y:
		stray_spawn_side = Sides.TOP
	elif global_position.y >= bottom_spawn_position_y:
		stray_spawn_side = Sides.BOTTOM
	elif global_position.x >= right_spawn_position_x:
		stray_spawn_side = Sides.RIGHT
	elif global_position.x <= left_spawn_position_x:
		stray_spawn_side = Sides.LEFT
	else: 
		printt("stray", global_position)
	
	
func show_stray(): # kliče GM
	# namen: neteatralen prikaz streja

	modulate.a = 1
	
	if current_state == States.WALL:
		stray_color.s = 0.0
		color_poly.modulate = Global.color_wall_pixel


func die(stray_in_stack_index: int, strays_in_stack: int):
	# namen: stage upgrade in die, camera shake in vibra off, collisions enabled, die off, če je DYING (walled)
	
	if current_state == States.DYING:
		return
		
	current_state = States.DYING
	global_position = Global.snap_to_nearest_grid(global_position) 
	
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

	position_indicator.modulate.a = 0	
	collision_shape.disabled = true
	collision_shape_ext.disabled = true
	
	# color vanish
	var vanish_time = animation_player.get_current_animation_length()
	var vanish: SceneTreeTween = get_tree().create_tween()
	vanish.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

	if not Global.game_manager.in_level_transition:
#	if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER and not Global.game_manager.in_level_transition:
		Global.game_manager.upgrade_stage()	
		
	# KVEFRI je v animaciji


func step(step_direction: Vector2):
	# namen: metanje ext collisiona za prepoznavanje stene
	# namen: določanje smeri glede na tip straya
	
	match stray_spawn_side:
		Sides.TOP:
			step_direction = Vector2.DOWN
		Sides.BOTTOM:
			step_direction = Vector2.UP
		Sides.LEFT:
			step_direction = Vector2.RIGHT
		Sides.RIGHT:
			step_direction = Vector2.LEFT	
	
	# preverjam state		
	if not current_state == States.IDLE:
		return
	
	var current_collider = detect_collision_in_direction(step_direction)
	#	var current_collider# = first_collider		
	#	# obrnem vision grupo v smeri...
	#	vision.look_at(global_position + step_direction)
	#	# vsi ray gledajo naravnost
	#	for ray in vision_rays:
	#		ray.cast_to = Vector2(45, 0) # en pixel manj kot 48, da ne seže preko celice
	#	# grebanje kolajderja	
	#	var first_collider: Node2D
	#	for ray in vision_rays:
	#		ray.add_exception(self)
	#		ray.add_exception(Global.current_tilemap)
	#		ray.force_raycast_update()
	#		if not step_count > 2:
	#			for n in get_tree().get_nodes_in_group(Global.group_tilemap):
	#				print("JEJ")
	#				ray.add_exception(n)
	#		if ray.is_colliding():
	#
	#			first_collider = ray.get_collider()
	##			if first_collider.is_in_group(Global.group_tilemap) and not step_count > 2:
	##				pass
	##			else:
	#			current_collider = first_collider		
	#			break # ko je kolajder neham čekirat
			
	# preverjam kolizije glede na število korakov, da vem kdaj je prek meje
	step_count += 1
	# če delam pravi korak, je pred mano stena
	if current_collider:
		if current_collider.is_in_group(Global.group_tilemap):
			if step_count > stray_crossed_wall_step_limit:
				return current_collider
		else: # if current_collider.is_in_group(Global.group_strays):
			return current_collider
	
	current_state = States.MOVING
	
	# vržem ext coll			
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika
	
	# preverim available positions ... zadnja varovalka, da se ne pokrijej ... redko pride do nje
	var planned_new_position: Vector2 = global_position + step_direction * cell_size_x
	var tiles_taken: Array = Global.game_manager.available_respawn_positions
	if tiles_taken.has(planned_new_position):
		print ("position taken")
		return
		
	var step_time: float = 0.2
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")
	

func play_sound(effect_for: String):
	# namen: ni soundow na spawn
	
	if Global.sound_manager.game_sfx_set_to_off:
		return
		
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
		"stepping":
			var random_step_index = randi() % $Sounds/Stepping.get_child_count()
			var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()
			
				
# ON FLOOR --------------------------------------------------------------------------------------------


func get_all_neighbors_in_directions(directions_to_check: Array): # kliče player on hit
	# namen: preverjanje vseh_sosedov, tudi tilemapa
	
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
		if neighbor and neighbor.is_in_group(Global.group_tilemap): # če je kolajder, je tilemap
			current_cell_neighbors.append(neighbor)
		
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


func turn_to_wall(stray_in_stack_index: int):
	
	current_state = States.WALL # takoj je izločen iz igre. po pavzi pa efekt
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# efekti
	# Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("turning_color")
	play_sound("blinking")
	
#	var shake_power: float = 0.2
#	var shake_time: float = 0.3
#	var shake_decay: float = 0.7
#	Global.player1_camera.shake_camera(shake_power, shake_time, shake_decay)	

	# turn to color
	stray_color.s = 0.0
	
	var color_tween: SceneTreeTween = get_tree().create_tween()
	color_tween.tween_property(self, "color_poly:modulate", stray_color, 0.2) # barva straysa
	color_tween.parallel().tween_property(self, "modulate", Global.color_wall_pixel, 0.2) # siva stena
	
	# povzroča error, ker hoče vrnit funkciji ki ne obstaja več ... nekaj takega
	# color_tween.tween_callback(self, "return", [true])#.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

	# preverim, če je pozicija na robu
