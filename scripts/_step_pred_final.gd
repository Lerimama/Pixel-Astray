extends Node



func step_control():
	
# V3 boljši slajd
	if Input.is_action_just_pressed("ui_up") and not step_burst_on:
		direction = Vector2.UP
#		step_burst_on = true
		step_by_step(direction)
	if Input.is_action_just_released("ui_up"):
#		step_burst_on = false
		direction = Vector2.ZERO
		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()
	
	if Input.is_action_just_pressed("ui_down") and not step_burst_on:
		direction = Vector2.DOWN
#		step_burst_on = true
		step_by_step(direction)
	if Input.is_action_just_released("ui_down"):
#		step_burst_on = false
		direction = Vector2.ZERO
		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()

	elif Input.is_action_just_pressed("ui_left") and not step_burst_on:
		direction = Vector2.LEFT
#		step_burst_on = true
		step_by_step(direction)
	if Input.is_action_just_released("ui_left"):
#		step_burst_on = false
		direction = Vector2.ZERO
		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()
		
	if Input.is_action_just_pressed("ui_right") and not step_burst_on:
		direction = Vector2.RIGHT
#		step_burst_on = true
		step_by_step(direction)
	if Input.is_action_just_released("ui_right"):
#		step_burst_on = false
		direction = Vector2.ZERO
		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()




# V2 is JUST pressed
#	if Input.is_action_just_pressed("ui_up"):
#		direction = Vector2.UP
#		step_by_step(direction)
#	elif Input.is_action_just_pressed("ui_down"):
#		direction = Vector2.DOWN
#		step_by_step(direction)
#	elif Input.is_action_just_pressed("ui_left"):
#		direction = Vector2.LEFT
#		step_by_step(direction)
#	elif Input.is_action_just_pressed("ui_right"):
#		direction = Vector2.RIGHT
#		step_by_step(direction)
#	else:
#		direction = Vector2.ZERO
#		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()
		
# V1 is pressed
#	if Input.is_action_pressed("ui_up") and not step_burst_on:
#		direction = Vector2.UP
#		step_burst_on = true
#		step_by_step(direction)
#	elif Input.is_action_pressed("ui_down") and not step_burst_on:
#		direction = Vector2.DOWN
#		step_burst_on = true
#		step_by_step(direction)
#	elif Input.is_action_pressed("ui_left") and not step_burst_on:
#		direction = Vector2.LEFT
#		step_burst_on = true
#		step_by_step(direction)
#
#	elif Input.is_action_pressed("ui_right") and not step_burst_on:
#		direction = Vector2.RIGHT
#		step_burst_on = true
#		step_by_step(direction)
#	else:
#		step_burst_on = false
#		direction = Vector2.ZERO
#		collision_ray.cast_to = direction * cell_size_x 
#		snap_to_nearest_grid()

var step_burst_on	
onready var step_tween: Tween = $StepTween


func step_by_step(step_direction):
	
	snap_to_nearest_grid()
	
	# če vidi steno v planirani smeri
	if detect_collision_in_direction(direction) or skill_activated: 
		return		
	# če ni stena naredi korak
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()
	if not collision_ray.is_colliding():
		
#			step_tween.interpolate_property(self, "position", position, position + direction * cell_size_x, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
#			step_tween.start()
		
		new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		new_tween.tween_property(self, "position", global_position + direction * cell_size_x, 0.2)
#			new_tween.tween_property(ray_collider, "position", ray_collider.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
#			new_tween.parallel().tween_property(new_pixel_ghost, "position", new_pixel_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
#			new_tween.tween_callback(self, "_change_state", [States.WHITE])
#			new_tween.tween_callback(ray_collider, "select_next_state")
#		new_tween.tween_callback(self, "snap_to_nearest_grid()")

func _on_StepTween_tween_all_completed() -> void:
	snap_to_nearest_grid() # če slajdam
	pass # Replace with function body.

# Steping v1

#func step_control():
#
#	if Input.is_action_pressed("ui_up"):
#		direction = Vector2.UP
#		step_by_step(direction)
#	elif Input.is_action_pressed("ui_down"):
#		direction = Vector2.DOWN
#		step_by_step(direction)
#	elif Input.is_action_pressed("ui_left"):
#		direction = Vector2.LEFT
#		step_by_step(direction)
#	elif Input.is_action_pressed("ui_right"):
#		direction = Vector2.RIGHT
#		step_by_step(direction)
#	else:
##		if not dir_memory_mode:
#		direction = Vector2.ZERO
#		# reset ray
#		collision_ray.cast_to = direction * cell_size_x 	
		
#func step_by_step(direction): 
#	# premik samo, če je smerna tipka stisnjena
#
#	# če vidi steno v planirani smeri
#	if detect_collision_in_direction(direction) or skill_activated: 
#		return	
#
#	if Global.game_manager.deathmode_on:
#		steping_frame_skip = death_mode_frame_skip
#
#	if frame_counter % steping_frame_skip == 0:
#		global_position += direction * cell_size_x # premik za velikost celice
