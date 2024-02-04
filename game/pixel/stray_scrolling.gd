extends Stray


func show_stray(): # kliče GM
	
	modulate.a = 1


func die(stray_in_stack_index: int, strays_in_stack: int):
	# namen: stage upgrade in die, camera shake in vibra, collisions enabled, die off, če je DYING (walled)
#	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
#	shake_player_camera(burst_speed)
	
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
#	collision_shape.disabled = true
#	collision_shape_ext.disabled = true
	
	# color vanish
	var vanish_time = animation_player.get_current_animation_length()
	var vanish: SceneTreeTween = get_tree().create_tween()
	vanish.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

	if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
		Global.game_manager.upgrade_stage()	
		
	# KVEFRI je v animaciji


func step(step_direction: Vector2):
	# namen: nerandom smer, pošiljanje collisiona za prepoznavanje stene
	
	if not current_state == States.IDLE:
		return
		
	var current_collider = detect_collision_in_direction(step_direction)
	
	if current_collider:
		return current_collider
	
	current_state = States.MOVING
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika
	
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")


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


func turn_to_wall_stray(stray_in_stack_index: int):
	
	current_state = States.DYING # takoj je izločen iz igre. po pavzi pa efekt
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# efekti
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("turning_color")
	# spawn_collision_particles()
	var shake_power: float = 0.2
	var shake_time: float = 0.3
	var shake_decay: float = 0.7
	Global.player1_camera.shake_camera(shake_power, shake_time, shake_decay)	
	
	# turn to color
	var color_tween: SceneTreeTween = get_tree().create_tween()
	color_tween.tween_property(self, "color_poly:color", Global.color_floor_scroller, 0.2)#.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	color_tween.tween_callback(self, "return", [true])#.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	

func check_for_neighbor_strays_on_hit(): # kliče player on hit
	 
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni selfž
			if not neighbor.current_state == neighbor.States.DYING: # če je vstanju umiranja se ne šteje za soseda
				current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov
