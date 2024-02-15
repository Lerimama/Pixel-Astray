extends Player


func on_hit_stray(hit_stray: KinematicBody2D):
	# namen: full burst power
	# namen: ob prve zadetku je game over (samo en posus za uničenje vseh)
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			
	
	if hit_stray.current_state == hit_stray.States.DYING or hit_stray.current_state == hit_stray.States.WALL: # če je že v umiranju, samo kolajdaš
	# if hit_stray.current_state == hit_stray.States.DYING: # če je že v umiranju, samo kolajdaš
		end_move()
		return
	
	tween_color_change(hit_stray.stray_color)

	# preverim sosede
	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
	# naberem strayse za destrojat
	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
	var strays_to_destroy: Array = []
	strays_to_destroy.append(hit_stray)
	if not hit_stray_neighbors.empty():
		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
			strays_to_destroy.append(neighboring_stray)
	
	# jih destrojam
	for stray in strays_to_destroy:
		var stray_index = strays_to_destroy.find(stray)
		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
		Global.hud.show_color_indicator(stray.stray_color) # če je scroller se returna na fuknciji
	
	end_move() # more bit za collision partikli zaradi smeri
	
	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov	
	
	# GO - so spucani vsi?
	if not Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:
		if strays_to_destroy.size() < Global.game_manager.strays_in_game_count:
			yield(get_tree().create_timer(3), "timeout") # pavza za pucanje zadetih
			Global.game_manager.game_over(Global.game_manager.GameoverReason.LIFE)
		else:
			Global.game_manager.game_over(Global.game_manager.GameoverReason.CLEANED)
		
		
func on_hit_wall():
	# namen: dodam ciljno steno (GO)
	
	# if goal wall hit
	var goal_wall_id = 7
	var current_collider: Node = detect_collision_in_direction(direction)
	if current_collider.is_in_group(Global.group_tilemap):
		if current_collider.get_collision_tile_id(self, direction) == goal_wall_id:
			Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
			spawn_collision_particles()
			shake_player_camera(burst_speed)
			end_move()
			Global.game_manager.game_over(Global.game_manager.GameoverReason.CLEANED)
			return
	
	# če ne je standardni zadetek
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_speed)
	
	got_hit = true # da heartbeat animacija ne povozi die animacije
	
	if player_stats["player_energy"] <= 1: # more bit pred statistiko
		stop_heart()
	
	
	change_stat("hit_wall", 1) # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
	
	die() # vedno sledi statistiki


#func on_hit_stray(hit_stray: KinematicBody2D):
#
#	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
#	play_sound("hit_stray")	
#	spawn_collision_particles()
#	shake_player_camera(burst_speed)			
#
#	if hit_stray.current_state == hit_stray.States.DYING or hit_stray.current_state == hit_stray.States.WALL: # če je že v umiranju, samo kolajdaš
#	# if hit_stray.current_state == hit_stray.States.DYING: # če je že v umiranju, samo kolajdaš
#		end_move()
#		return
#
#	tween_color_change(hit_stray.stray_color)
#
#	# preverim sosede
#	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
#	# naberem strayse za destrojat
#	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
#	var strays_to_destroy: Array = []
#	strays_to_destroy.append(hit_stray)
#	if not hit_stray_neighbors.empty():
#		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
#			if strays_to_destroy.size() < burst_speed_units_count or burst_speed_units_count == cocked_ghost_max_count:
#				strays_to_destroy.append(neighboring_stray)
#			else: break
#
#	# jih destrojam
#	for stray in strays_to_destroy:
#		var stray_index = strays_to_destroy.find(stray)
#		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
#		Global.hud.show_color_indicator(stray.stray_color) # če je scroller se returna na fuknciji
#
#	end_move() # more bit za collision partikli zaradi smeri
#
#	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov
