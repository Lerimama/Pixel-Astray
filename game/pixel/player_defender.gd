extends Player


func idle_inputs():
	# namen: odstranim SKILLED stanje
	
	if player_stats["player_energy"] > 1:
		var current_collider: Object = Global.detect_collision_in_direction(direction, vision_ray)
		if not current_collider:
		# dokler ne zazna kolizije se premika zvezno ... is_action_pressed
			if Input.is_action_pressed(key_up):
				direction = Vector2.UP
				step()
			elif Input.is_action_pressed(key_down):
				direction = Vector2.DOWN
				step()
			elif Input.is_action_pressed(key_left):
				direction = Vector2.LEFT
				step()
			elif Input.is_action_pressed(key_right):
				direction = Vector2.RIGHT
				step()
		else:
			end_move()

	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
			change_color_tween.kill()
			pixel_color = change_to_color
		burst_light_on()
			
					
func cocking_inputs():
	# namen: cocking, varianta na short cock
	
	if Input.is_action_pressed(key_up):
		if cocked_ghosts.empty(): # če je smer setana, ni pa potrjena
			direction = Vector2.DOWN
		if direction == Vector2.DOWN: # če je smer setana (ista)
			cock_burst()
	elif Input.is_action_pressed(key_down):
		if cocked_ghosts.empty():
			direction = Vector2.UP
		if direction == Vector2.UP:
			cock_burst()
	elif Input.is_action_pressed(key_left):
		if cocked_ghosts.empty():
			direction = Vector2.RIGHT
		if direction == Vector2.RIGHT:
			cock_burst()
	elif Input.is_action_pressed(key_right):
		if cocked_ghosts.empty():
			direction = Vector2.LEFT
		if direction == Vector2.LEFT:
			cock_burst()

	# releasing		
	if Input.is_action_just_released(key_burst):
		if cocked_ghosts.empty():
			end_move()
		else:
			release_burst()
			burst_light_off()
			

func spawn_cock_ghost(cocking_direction: Vector2): 
	# namen: vsi cock ghosti polni barve, zaznavanje cock_room z deffered klicom (da lahko bolje zazna cock room)
	
	var cocked_ghost_alpha: float = 1 # najnižji alfa za ghoste ... old 0.55
	var cocked_ghost_alpha_divider: float = 5 # faktor nižanja po zaporedju (manjši je bolj oster) ... old 14
	
	# spawn ghosta pod manom
	var cock_ghost_position = (global_position - cocking_direction * cell_size_x/2) + (cocking_direction * cell_size_x * (cocked_ghosts.size() + 1)) # +1, da se ne začne na pixlu
	var new_cock_ghost = spawn_ghost(cock_ghost_position)
	new_cock_ghost.z_index = 3 # nad straysi in playerjem
	new_cock_ghost.modulate.a  = cocked_ghost_alpha - (cocked_ghosts.size() / cocked_ghost_alpha_divider)
	new_cock_ghost.direction = cocking_direction
	
	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_cock_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_cock_ghost.scale.y = 0

	# animiram cock celico
	var cock_cell_tween = get_tree().create_tween()
	cock_cell_tween.tween_property(new_cock_ghost, "scale", Vector2.ONE, cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cock_cell_tween.parallel().tween_property(new_cock_ghost, "position", global_position + cocking_direction * cell_size_x * (cocked_ghosts.size() + 1), cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_cock_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_cock_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	return new_cock_ghost


func burst():
	# namen: konstantna hitrost bursta (neodvisna od vrednosti cocka)
	
	var burst_direction = direction
	var backup_direction = - burst_direction
	var current_ghost_count = cocked_ghosts.size()
	
	var new_stretch_ghost: Node
	
	# spawn stretch ghost
	new_stretch_ghost = spawn_ghost(global_position)
	new_stretch_ghost.color_poly.hide()
	new_stretch_ghost.color_poly_alt.show()
	if burst_direction.y == 0: # če je smer hor
		new_stretch_ghost.scale = Vector2(current_ghost_count, 1)
	elif burst_direction.x == 0: # če je smer ver
		new_stretch_ghost.scale = Vector2(1, current_ghost_count)
	new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * current_ghost_count)/2 - burst_direction * cell_size_x/2

	# release cocked ghosts
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
	
	play_sound("burst")
	
	# release strech ghost 
	var strech_ghost_shrink_time: float = 0.1 # original je bila 0.2
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	yield(release_tween, "finished")		
	
	# release pixel
	current_state = States.BURSTING
	previous_position = global_position
	
	if Global.game_manager.game_settings["full_power_mode"]:
		#		burst_speed = 3 * cock_ghost_speed_addon
		burst_speed = cocked_ghost_max_count * cock_ghost_speed_addon # maximalna možna hitrost
	else:
		burst_speed = current_ghost_count * cock_ghost_speed_addon

	change_stat("burst_count", 1)
	
	
func play_sound(effect_for: String):
	# namen: brez vrtoglavice hit wall
	
	if not Global.sound_manager.game_sfx_set_to_off:
		match effect_for:
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
				$Sounds/BlinkingStatic.get_child(random_static_index).play()
			"heartbeat":
				$Sounds/Heartbeat.play()
			# bursting
			"hit_stray":
				$Sounds/Burst/HitStray.play()
			"hit_wall":
				$Sounds/Burst/HitWall.play()
			#			$Sounds/Burst/HitDizzy.play()
			"burst":
				yield(get_tree().create_timer(0.1), "timeout")
				$Sounds/Burst/Burst.play()
				$Sounds/Burst/BurstLaser.play()
			"burst_cocking":
				if not $Sounds/Burst/BurstCocking.is_playing():
					$Sounds/Burst/BurstCocking.play()
			"burst_uncocking":
				if not $Sounds/Burst/BurstUncocking.is_playing():
					$Sounds/Burst/BurstUncocking.play()			
			"burst_stop":
				$Sounds/Burst/BurstStop.play()
			# skills
			"pushpull_start":
				$Sounds/Skills/PushPull.play()
			"pushpull_end":
				$Sounds/Skills/PushedPulled.play()
			"pulled":
				$Sounds/Skills/StoneSlide.play()
			"pushed":
			#			$Sounds/Skills/Cling.play()
				$Sounds/Skills/StoneSlide.play()
			"teleport":
				$Sounds/Skills/TeleportIn.play()
	
