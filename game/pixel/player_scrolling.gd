extends Player_class


var player_surrounded: bool = false

	
# INPUTS ------------------------------------------------------------------------------------------


func idle_inputs():
	# namen: odstranim SKILLED stanje, dodam surrounded setanje
	
	if player_surrounded:
		return
	
	# preveri vse štiri smeri
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var direction_with_collision: Array
	for direction in directions_to_check:
		var current_collider = detect_collision_in_direction(direction)
		if current_collider:
			direction_with_collision.append(direction)
	
	# če so vse štiri polne
	if direction_with_collision.size() == directions_to_check.size():
		player_surrounded = true
	else:
		player_surrounded = false
	
	
	if player_stats["player_energy"] > 1:
		var current_collider: Node2D = detect_collision_in_direction(direction)
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

	# cocking
	# varianta na short cock
	
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
			
				
# BURST ------------------------------------------------------------------------------------------


func cock_burst():
	# namen: brez ciklanja, moč je vedno polna, hitrejše cockanje, manjša dolžina
	
	cocked_ghost_max_count = 3
	cock_ghost_cocking_time = 0.05 # čas nastajanja ghosta in njegova animacija 	
	
	var burst_direction = direction
	var cock_direction = - burst_direction
	
	if detect_collision_in_direction(cock_direction):
		stop_sound("burst_cocking")
		end_move()
		return
		
	if cocked_ghosts.size() < cocked_ghost_max_count and cocking_room: # prostor za napenjanje preverja ghost
		current_ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
		if current_ghost_cocking_time > cock_ghost_cocking_time: # ko je čas za eno celico mimo, jo spawnam
			current_ghost_cocking_time = 0
			var new_cock_ghost = spawn_cock_ghost(cock_direction)
			cocked_ghosts.append(new_cock_ghost)	
			play_sound("burst_cocking")
			

func spawn_cock_ghost(cocking_direction: Vector2): 
	# namen: vsi cock ghosti polni barve
	
	# spawn ghosta pod manom
	var cock_ghost_position = (global_position - cocking_direction * cell_size_x/2) + (cocking_direction * cell_size_x * (cocked_ghosts.size() + 1)) # +1, da se ne začne na pixlu
	var new_cock_ghost = spawn_ghost(cock_ghost_position)
	new_cock_ghost.z_index = 3 # nad straysi in playerjem
	new_cock_ghost.modulate.a  = 1 # cocked_ghost_alpha - (cocked_ghosts.size() / cocked_ghost_alpha_divider)
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
		
		
func release_burst(): 
	# namen: manjšam trajanje in pavzo
	
	current_state = States.RELEASING
	
	play_sound("burst_cocked")

	var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	var cocked_pause_time: float = 0.05 # pavza pred strelom

	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
#		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
#	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	burst()
		

func burst():
	# namen: konstantna hitrost bursta (neodvisna od vrednosti cocka), bomba stil
	
	var burst_direction = direction
	var backup_direction = - burst_direction
	var current_ghost_count = cocked_ghosts.size()
	
	var new_stretch_ghost: Node
	
	if player_surrounded == false: # središčni burst
		new_stretch_ghost = spawn_ghost(global_position)
		# spawn stretch ghost
		if burst_direction.y == 0: # če je smer hor
			new_stretch_ghost.scale = Vector2(current_ghost_count, 1)
		elif burst_direction.x == 0: # če je smer ver
			new_stretch_ghost.scale = Vector2(1, current_ghost_count)
		new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * current_ghost_count)/2 - burst_direction * cell_size_x/2

	# release cocked ghosts
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
	
	stop_sound("burst_cocking")
	stop_sound("burst_uncocking")
	play_sound("burst")
	
	if player_surrounded == false: # središčni burst
		# release strech ghost 
		var strech_ghost_shrink_time: float = 0.05 # original je bila 0.2
		var release_tween = get_tree().create_tween()
		release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		release_tween.tween_callback(new_stretch_ghost, "queue_free")
		# release pixel
		yield(get_tree().create_timer(strech_ghost_shrink_time), "timeout") # čaka na zgornji tween
		
	current_state = States.BURSTING
	burst_speed = current_ghost_count * cock_ghost_speed_addon
	#if current_ghost_count < cocked_ghost_max_count and not current_ghost_count == 0:
	#	burst_speed = 2 * cock_ghost_speed_addon
	#else:
	#	burst_speed = 7 * cock_ghost_speed_addon
	change_stat("burst_released", 1)
	
	
# ON HIT ------------------------------------------------------------------------------------------


func on_hit_stray(hit_stray: KinematicBody2D):
	# namen: always full stack, tudi sprožanje čekiranja levelov, plejer ostane bel, preverjanje straysov na podnu
	
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			

	if hit_stray.current_state == hit_stray.States.DYING: # če je že v umiranju, samo kolajdaš
		end_move()
		return

	# preverim sosede
	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
	
	# naberem strayse za destrojat
	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
	var strays_to_destroy: Array = []
	strays_to_destroy.append(hit_stray)
	# na seznam za destroj
	if not hit_stray_neighbors.empty():
		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
#			if strays_to_destroy.size() < burst_speed_units_count or burst_speed_units_count == cocked_ghost_max_count:
#				strays_to_destroy.append(neighboring_stray)
#			else: 
#				break
			strays_to_destroy.append(neighboring_stray)

	# jih destrojam
	for stray in strays_to_destroy:
		var stray_index = strays_to_destroy.find(stray)
		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
		Global.hud.show_color_indicator(stray.stray_color) # če je scroller se returna na fuknciji
	
	
	end_move() # more bit za collision partikli zaradi smeri

	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov
	
	player_surrounded == false # če je središčni burst

#	if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
#		Global.game_manager.upgrade_stage()	
		
		
func on_hit_wall():

	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	# spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_speed)
	
	# yield(get_tree().create_timer(1), "timeout") # za dojet
	end_move()
	
