extends Player

# enigma
var enigma_move_started: bool = false # ob cockanju se začne poteza (konča se v steni ali na koncu reburstanja, kadar resetam reburst_count)
var enigma_start_strays_count: int = 0 # število straysow pred movetom
var enigma_cleaned_strays_count: int = 0 # beleži vse uničene v času enigma move

# reburst
var is_rebursting: bool = false # za regulacijo moči on hit stray
var reburst_count: int = 0 # resetira se s tajmerjem
var can_reburst: bool = false
var reburst_speed_units_count: float = 0 # za prenos original hitrosti v naslednje rebursta
var reburst_max_cock_count: int = 1 # za kolk se nakoka (samo vizualni efekt)
var reburst_reward__count: int = 1 # za kolk se nakoka (samo vizualni efekt)

onready var rebursting_timer: Timer = $ReburstingTimer
onready var reburst_window_time: int = 2.1 # Global.game_manager.game_settings["reburst_window_time"] # cocking count
onready var reburst_count_limit: int = Global.game_manager.game_settings["reburst_count_limit"] # cocking count
onready var reburst_hit_power: int = Global.game_manager.game_settings["reburst_hit_power"] # kolk jih destroya ... če je 0 gre po original pravilih moči


func idle_inputs():
	# namen: rebursting_inputs reburst_count reset ... za reburst
	# namen: enigma finish (kery_burst, direction key)
	
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
					if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
						finish_enigma_move()
				elif Input.is_action_pressed(key_down):
					direction = Vector2.DOWN
					step()
					reburst_count = 0
					if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
						finish_enigma_move()
				elif Input.is_action_pressed(key_left):
					direction = Vector2.LEFT
					step()
					reburst_count = 0
					if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
						finish_enigma_move()
				elif Input.is_action_pressed(key_right):
					direction = Vector2.RIGHT
					step()
					reburst_count = 0
					if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
						finish_enigma_move()
				
		else:
		# ko zazna kolizijo postane skilled ali pa end move 
		# kontrole prevzame skilled_input
			if current_collider.is_in_group(Global.group_strays):
				if not current_collider.current_state == current_collider.States.WALL:
					current_collider.current_state = current_collider.States.STATIC # ko ga premakneš postane MOVING
				current_state = States.SKILLED
			elif current_collider.is_in_group(Global.group_tilemap):
				if current_collider.get_collision_tile_id(self, direction) == teleporting_wall_tile_id:
					current_state = States.SKILLED
				else: # druge stene
					end_move()
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
		if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
			enigma_move_started = true	
			enigma_start_strays_count = Global.game_manager.strays_in_game_count
			
		
func end_move():
	# namen: reburst reset, odstranim burst_light_off()
	
	close_reburst_window()
	is_rebursting = false 
	
	# reset burst
	burst_speed = 0
	cocking_room = true
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
		
	# ugasnem lučke
	#	burst_light_off()
	skill_light_off()
	
	# reset ključnih vrednosti (če je v skill tweenu, se poštima)
	direction = Vector2.ZERO 
	collision_shape_ext.position = Vector2.ZERO
	
	# always
	global_position = Global.snap_to_nearest_grid(global_position) 
	current_state = States.IDLE # more bit na kocnu
		

func on_hit_stray(hit_stray: KinematicBody2D):
	# namen: activate reburst, enigma cleaned count
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			
	
	# reburst nagrada
	var reward_limit: int = Global.game_manager.game_settings["reburst_reward_limit"]
	if reward_limit > 0:
		var count_till_reward: int = reburst_count % reward_limit
		if count_till_reward <= 0 and not reburst_count == 0:
			Global.sound_manager.play_sfx("reburst_reward")
			change_stat("reburst_reward", 1)
			
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
		if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
			enigma_cleaned_strays_count += 1

	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov

	end_move()
	
	# reburst
	if reburst_count < reburst_count_limit or reburst_count_limit == 0:
		can_reburst = true
		burst_light_on()	
		rebursting_timer.stop() # ... zazih
		rebursting_timer.start(reburst_window_time)
	else:
		# vpliva samo kadar odigram vse reburste, drugi reset je v stepanju
		close_reburst_window()
		reburst_count = 0
		if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
			finish_enigma_move()


func spawn_cock_ghost(cocking_direction: Vector2):
	# namen: cock ghost alpha
	
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
	
	
# REBURST ------------------------------------------------------------------


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
	
	var burst_direction = direction
	var cock_direction = - burst_direction
	
	# če je zraven pixla konča (potem postane skilled)
	if detect_collision_in_direction(burst_direction):
		stop_sound("burst_cocking")
		end_move()
		burst_light_off()
		return
	# če ni prostora, ne dela cockinga
	if detect_collision_in_direction(cock_direction):
		stop_sound("burst_cocking")
		release_reburst()
	else:
	# če je prostor cocka
		for cock in reburst_max_cock_count:
			var new_cock_ghost = spawn_cock_ghost(cock_direction)
			cocked_ghosts.append(new_cock_ghost)	
			if not cocking_room:
				break
		release_reburst()


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

	reburst_count += 1
			
	var burst_direction = direction
	var backup_direction = - burst_direction
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
	# se resetira na vsak reburst in drugo 
	can_reburst = false
	rebursting_timer.stop()
	burst_light_off()
		
		
func _on_ReburstingTimer_timeout() -> void:
	
	# če je enigma je čas naskončen
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
		return
	
	# čas zamujen ... ne moreš več reburstat
	# resetira vse
	close_reburst_window()
	reburst_count = 0
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:	
		finish_enigma_move()
	

	
# ENIGMA ------------------------------------------------------------------
	
	
func finish_enigma_move():
	
	# ček for succes
	if enigma_move_started:
		enigma_move_started = false
		# če je količina uničenih enaka količini na ekranu
		if enigma_cleaned_strays_count < enigma_start_strays_count:
			Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
		else:
			pass # to naredi GM po defaultu
