extends Player_class

		
func on_hit_wall():
	# namen: dodam ciljnega straysa
	
	# if goal hit
	print(detect_collision_in_direction(direction))
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
