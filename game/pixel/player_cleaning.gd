extends Player



# REBURST
# cock moč je vedno na polno 
# cock ghost število pove koliko reburstov je možno (max = neskončno burstov)
# po koliziji s straysom, je kratek čas ko s pritiskom v smeri ponoviš burst (brez napenjanja?) 
# zadetek > REBURSTING state, sproži timer
# reburst > BURSTING states, ustavi timer, odšteje število burstov
# rebursting zadetek > če je dovolj moči REBURSTING state, sproži timer, če ne end_move()
# burst sprožilka (alt) tudi izklopi REBURSTING

# neu

var reburst_count: int = 0 # resetira se s tajmerjem
var can_reburst: bool = false
var reburst_window_time: float = 5
#var reburst_limit: int = 3 # cocking count
#var reburst_speed: float = 1
#var reburst_cock_limit: int = 0
var reburst_speed_units_count: float = 0 # za prenos original hitrosti v naslednje rebursta
var reburst_max_cock_count: int = 1 # za kolk se napolni
onready var reburst_limit: int = Global.game_manager.game_settings["reburst_limit"] # cocking count
#onready var reburst_window_time: int = Global.game_manager.game_settings["reburst_window_time"] # cocking count
onready var rebursting_timer: Timer = $ReburstingTimer
var is_rebursting: bool = false # za regulacijo moči on hit stray
var reburst_power: int = 1 # če je max cock count je neskončna moč
#var reburst_hit_power: int = 0 # kolk jih destroya ... če je 0 gre po original pravilih moči
onready var reburst_hit_power: int = Global.game_manager.game_settings["reburst_hit_power"] # kolk jih destroya ... če je 0 gre po original pravilih moči

func idle_inputs():
#	namen: 
	
	if player_stats["player_energy"] > 1:
		var current_collider: Node2D = detect_collision_in_direction(direction)
		
		if not current_collider:
		# dokler ne zazna kolizije se premika zvezno ... is_action_pressed
			if can_reburst:
				rebursting_inputs()
			else:
				if Input.is_action_pressed(key_up):
					direction = Vector2.UP
					step()
					reburst_count = 0	
				elif Input.is_action_pressed(key_down):
					direction = Vector2.DOWN
					step()
					reburst_count = 0	
				elif Input.is_action_pressed(key_left):
					direction = Vector2.LEFT
					step()
					reburst_count = 0	
				elif Input.is_action_pressed(key_right):
					direction = Vector2.RIGHT
					step()
					reburst_count = 0	
		else:
		# ko zazna kolizijo postane skilled ali pa end move 
		# kontrole prevzame skilled_input
			if current_collider.is_in_group(Global.group_strays):
				current_state = States.SKILLED
				current_collider.current_state = current_collider.States.STATIC # ko ga premakneš postane MOVING
			elif current_collider.is_in_group(Global.group_wall):
				if current_collider.is_in_group(Global.group_tilemap):
					if current_collider.get_collision_tile_id(self, direction) == teleporting_wall_tile_id:
						current_state = States.SKILLED
					else: # druge stene
						end_move()
				else: # stray
					current_state = States.SKILLED	
			elif current_collider.is_in_group(Global.group_players):
				end_move()
			elif current_collider is StaticBody2D: # static body, 
				end_move()
	
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
			change_color_tween.kill()
			pixel_color = change_to_color
		burst_light_on()
		reburst_count = 0	


func end_move():
#	namen: reburst reset
	
	close_reburst_window()
	is_rebursting = false 
	
	# reset burst
	burst_speed = 0
	cocking_room = true
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
		
	# ugasnem lučke
	burst_light_off()
	skill_light_off()
	
	# reset ključnih vrednosti (če je v skill tweenu, se poštima)
	direction = Vector2.ZERO 
	collision_shape_ext.position = Vector2.ZERO
	
	# always
	global_position = Global.snap_to_nearest_grid(global_position) 
	current_state = States.IDLE # more bit na kocnu
		

func on_hit_stray(hit_stray: KinematicBody2D):
#	namen: activate reburst
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			
	
	if hit_stray.current_state == hit_stray.States.DYING or hit_stray.current_state == hit_stray.States.WALL: # če je že v umiranju, samo kolajdaš
		end_move()
		return
	
	tween_color_change(hit_stray.stray_color)

	# preverim sosede
	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
	
	# naberem strayse za destrojat
	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
	reburst_speed_units_count = burst_speed_units_count # hitrost rebursta je enaka hitrosti original bursta
	if is_rebursting:
		if not reburst_hit_power == 0:
			burst_speed_units_count = reburst_hit_power
	var strays_to_destroy: Array = []
	strays_to_destroy.append(hit_stray)
	if not hit_stray_neighbors.empty():
		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
			if strays_to_destroy.size() < burst_speed_units_count or burst_speed_units_count == cocked_ghost_max_count:
				strays_to_destroy.append(neighboring_stray)
			else: break
	
	# jih destrojam
	for stray in strays_to_destroy:
		var stray_index = strays_to_destroy.find(stray)
		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije

	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov

	end_move()
	
	# reburst
	printt("reburst_count", reburst_count)
	if reburst_count < reburst_limit or reburst_limit == 0:
#		reburst_speed_units_count = 
		can_reburst = true
		rebursting_timer.start(reburst_window_time)
		reburst_count += 1
	else:
		# vpliva samo kadar odigram vse reburste, drugi reset je v stepanju
		close_reburst_window()
		reburst_count = 0


# ADDED ------------------------------------------------------------------


func rebursting_inputs():

	# cocking
	if Input.is_action_just_pressed(key_up):
			close_reburst_window()
			direction = Vector2.UP
			cock_reburst()
			#			can_reburst = false
			#			direction = Vector2.DOWN
	elif Input.is_action_just_pressed(key_down):
			close_reburst_window()
			direction = Vector2.DOWN
			cock_reburst()
			#			can_reburst = false
			#			direction = Vector2.UP
	elif Input.is_action_just_pressed(key_left):
			close_reburst_window()
			direction = Vector2.LEFT
			cock_reburst()
			#			can_reburst = false
			#			direction = Vector2.RIGHT
	elif Input.is_action_just_pressed(key_right):
			close_reburst_window()
			direction = Vector2.RIGHT
			cock_reburst()
			#			can_reburst = false
			#			direction = Vector2.LEFT

	
func cock_reburst():

	# prenos iz burst tipke ... ker tudi kao cocka
	if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
		change_color_tween.kill()
		pixel_color = change_to_color
	burst_light_on()
	
	var burst_direction = direction
	var cock_direction = - burst_direction
	
	# če je zraven pixla konča (potem postane skilled)
	if detect_collision_in_direction(burst_direction):
		stop_sound("burst_cocking")
		burst_light_off()
		end_move()
		return
	# če ni prostora, ne dela cockinga
	if detect_collision_in_direction(cock_direction):
		stop_sound("burst_cocking")
		release_reburst()
		burst_light_off()
	else:
	# če je prostor cocka
		for cock in reburst_max_cock_count:
			var new_cock_ghost = spawn_cock_ghost(cock_direction)
			cocked_ghosts.append(new_cock_ghost)	
			if not cocking_room:
				break
		release_reburst()
		burst_light_off()			


func release_reburst():
	
	current_state = States.RELEASING
	play_sound("burst_cocked")
	var cocked_ghost_fill_time: float = 0.01 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	var cocked_pause_time: float = 0.03 # pavza pred strelom
	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	reburst()
	
	
func reburst():

	is_rebursting = true
		
	var burst_direction = direction
	var backup_direction = - burst_direction
#	var current_ghost_count = 2
	var current_ghost_count = cocked_ghosts.size()
	
	# spawn stretch ghost
	var new_stretch_ghost = spawn_ghost(global_position)
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
	
	# release ghost 
	var strech_ghost_shrink_time: float = 0.2
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	
	# release pixel
	yield(get_tree().create_timer(strech_ghost_shrink_time), "timeout") # čaka na zgornji tween
	current_state = States.BURSTING
	
	burst_speed = reburst_speed_units_count * cock_ghost_speed_addon
	
	change_stat("burst_released", 1)


func close_reburst_window():
	
	can_reburst = false
	rebursting_timer.stop()
		
		
func _on_ReburstingTimer_timeout() -> void:
	close_reburst_window()

		
