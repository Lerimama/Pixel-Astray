extends GameManager


var free_home_positions: Array # free home positions

# stepping
var line_step_in_progress: bool = false
var line_steps_since_spawn_round: int = 0 # prištevam v stray_step()

# spawn engine
var stray_spawning_round: int = 0 # prištevam na koncu spawna
var engine_stalled_checking_time: float = 2 # dobro da je večji od stepa ali respawn pavze
var strays_in_spawn_round: Array # da jim porinem začetek stepanja

onready var engine_stalled_timer: Timer = $"../EngineStalledTimer"
onready var line_step_pause_timer: Timer = $"../LineStepPauseTimer"
onready var line_steps_per_spawn_round: int = game_data["line_steps_per_spawn_round"]
onready var line_step_pause_time: float = game_data["line_step_pause_time"]
onready var spawn_round_range: Array = game_data["spawn_round_range"]


func _ready() -> void:
	# namen: ugasnem stray pos indikatorje tako da dam limito na 0

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_defender.tscn")
	PlayerPixel = preload("res://game/pixel/player_defender.tscn")
	
	randomize()
	
			
func set_game(): 
	# namen: namesto create_strays() je samo set_level_colors
	# namen: setam home pozicije

	# positions
	free_floor_positions = Global.current_tilemap.all_floor_tiles_global_positions.duplicate()
	#	home_positions = required_spawn_positions.duplicate()
	for free_pos in free_floor_positions:
		spawn_free_position_indicator(free_pos)
		
	# colors
	set_color_pool()

	if game_settings["show_game_instructions"]:
		yield(Global.hud, "players_ready")
	
	# animacije plejerja in straysov in zooma	
	current_players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	var signaling_player: KinematicBody2D
	for player in current_players_in_game:
		player.animation_player.play("lose_white_on_start")
		player.set_physics_process(true)
#		signaling_player = player # da se zgodi na obeh plejerjih istočasno
#	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	# strays
	Global.hud.spawn_color_indicators(get_level_colors())	
	
	# gui		
	Global.hud.slide_in()
	if game_settings["start_countdown"]:
		yield(get_tree().create_timer(0.2), "timeout")
		Global.hud.start_countdown.start_countdown() # GM yielda za njegov signal
		yield(Global.hud.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	else:
		yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown

	start_game()
		
		
func start_game():
	
	Global.hud.game_timer.start_timer()
	
	Global.sound_manager.current_music_track_index = game_settings["game_music_track_index"]
	Global.sound_manager.play_music("game_music")
	
	for player in current_players_in_game:
		player.set_physics_process(true)
	
	game_on = true
	
	create_strays(create_strays_count)
	
	line_step()


func game_over(gameover_reason: int):
	# namen: samo TIME in LIFE, CLEANED je level ampak upgrade
	
	if game_on: # preprečim double gameover
		game_on = false
		
		Global.hud.game_timer.stop_timer()
		yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
		get_tree().call_group(Global.group_players, "set_physics_process", false)
		stop_game_elements()
		
		Global.gameover_gui.open_gameover(gameover_reason)


func create_players():
	# namen: podajanje dobljenih točk v GM
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# stats
		new_player_pixel.player_stats = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
		new_player_pixel.player_stats["player_energy"] = game_settings["player_start_energy"]
		new_player_pixel.player_stats["player_life"] = game_settings["player_start_life"]
		
		# povežem s hudom
		new_player_pixel.connect("stat_changed", Global.hud, "_on_stat_changed")
		new_player_pixel.emit_signal("stat_changed", new_player_pixel, new_player_pixel.player_stats) # štartno statistiko tako javim 
		
		# pregame setup
		new_player_pixel.set_physics_process(false)
		new_player_pixel.player_camera = Global.game_camera	


func create_strays(strays_to_spawn_count: int):
	# namen: no clampin, ker je lahko spawn 0
	# namen: v žrebanje vključim samo home spawn pozicije na voljo ... ni preverjanja vseh drugih mogočih pozicij
	# namen: skrijem ga, ker se pokaže šele pred prvim korakom
	
	# preverjama free home positions
	free_home_positions = required_spawn_positions.duplicate() # vsakič znova zajamemo vse in ji potem odštejemo trenutno zasedene ... 
	
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if free_home_positions.has(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
			free_home_positions.erase(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2))
	# preverjam za GO engine stalled
	if free_home_positions.empty():
		print("prazne home pozicije I")
		# sprožim tajmer, ki na koncu pozicije preveri še enkrat
		engine_stalled_timer.start(engine_stalled_checking_time)
	else:
		engine_stalled_timer.stop()
		
			
	for stray_index in strays_to_spawn_count:
		
		# žrebam barvo
		var random_selected_index: int = randi() % int(color_pool_colors.size())	
		var new_stray_color: Color = color_pool_colors[random_selected_index]		

		# če so pozicije na voljo spawnam	
		# spawn ... trotlam
		var throttler_start_msec = Time.get_ticks_msec()	
		var spawned_strays_true_count: int = 0	
		if not free_home_positions.empty(): 
			
			# random pozicija med možnimi
			var current_spawn_positions: Array = free_home_positions
			var selected_cell_index: int = randi() % int(current_spawn_positions.size())	
			var selected_cell_position = current_spawn_positions[selected_cell_index]
			var selected_stray_position = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
			
			# trotlam?
			if game_settings["throttled_stray_spawn"]:	
				var msec_taken = Time.get_ticks_msec() - throttler_start_msec
				if msec_taken < (round(1000 / Engine.get_frames_per_second()) - throttler_msec_threshold): # msec_per_frame - ...			
					spawned_strays_true_count += 1
					var spawned_stray = spawn_stray(stray_index, new_stray_color, selected_stray_position, false)
					strays_in_spawn_round.append(spawned_stray)
					all_stray_colors.append(new_stray_color)
					free_home_positions.erase(selected_stray_position)
				else:
					var msec_to_next_frame: float = throttler_msec_threshold + 1
					var sec_to_next_frame: float = msec_to_next_frame / 1000.0
					yield(get_tree().create_timer(sec_to_next_frame), "timeout") # da se vsi straysi spawnajo
					throttler_start_msec = Time.get_ticks_msec()
					# printt("over frame_time on: %s" % "stray line spawn")
			else:
				var spawned_stray = spawn_stray(stray_index, new_stray_color, selected_stray_position, false)
				# post spawn
				strays_in_spawn_round.append(spawned_stray)
				all_stray_colors.append(new_stray_color)
				free_home_positions.erase(selected_stray_position)
				
		# ko trotlam preskakuje spawne, zato ponovim
		if spawned_strays_true_count < strays_to_spawn_count and not spawned_strays_true_count == 0:
			create_strays(strays_to_spawn_count - spawned_strays_true_count)
			# print("razlika %s" % (strays_to_spawn_count - spawned_strays_true_count))
			return
						
	stray_spawning_round += 1
	
	
func upgrade_level(upgrade_on_cleaned: bool =  false):
	# namen: ni respawna

#	if level_upgrade_in_progress:
#		return
	if not level_upgrade_in_progress and game_on:
		
		level_upgrade_in_progress = true
	
		randomize()

		if upgrade_on_cleaned:
			for player in current_players_in_game:
				player.end_move()		
				player.on_screen_cleaned()

		current_level += 1 # številka novega levela 
		set_color_pool() # more bit pred yieldom in tudi, če so že spucani
		set_new_level() 
		Global.hud.level_popup_fade(current_level)
		Global.hud.spawn_color_indicators(get_level_colors())

		level_upgrade_in_progress = false		


func set_new_level():
	
	var prev_level_goal_count: int = game_data["level_goal_count"]
	game_data["level_goal_count"] += game_data["level_goal_count_grow"]
	line_steps_per_spawn_round *= game_data["line_steps_per_spawn_round_factor"]
	line_step_pause_time *= game_data["line_step_pause_time_factor"]
	line_step_pause_time = clamp (line_step_pause_time, 0.2, line_step_pause_time) # ne sem bit manjša od stray step hitrosti (cca 0.2)
	spawn_round_range[0] += game_data["spawn_round_range_grow"][0]
	spawn_round_range[1] += game_data["spawn_round_range_grow"][1]
	
	game_data["level"] = current_level


# EKSKLUZIVNO -----------------------------------------------------------------------------------------------------


func line_step():
	
	# če je upgrade in progres ne stepa, timer pa se reštarta in nadaljuje stepanje
	if not level_upgrade_in_progress:
				
		line_step_in_progress = true
				
		# random spawn count
		var stray_spawn_count_min: int = spawn_round_range[0]
		var stray_spawn_count_max: int = spawn_round_range[1]
		var random_spawn_count: int = randi() % stray_spawn_count_max + stray_spawn_count_min
		# odštejem kar je višje od max range, ker zamik zamakne tudi zgornjo mejo
		if random_spawn_count > stray_spawn_count_max: 
			random_spawn_count -= random_spawn_count - stray_spawn_count_max
		# če je spawn število večje od pozicij na voljo
		if random_spawn_count > free_home_positions.size():# spawna jih največ toliko kolikor jih lahko
			random_spawn_count = free_home_positions.size()
		
		# kličem step in tam preverim kolajderja 
		#		get_tree().call_group(Global.group_strays, "step")
		# step ... trotlam
		var throttler_start_msec = Time.get_ticks_msec()
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			var msec_taken = Time.get_ticks_msec() - throttler_start_msec
			if msec_taken < (round(1000 / Engine.get_frames_per_second()) - throttler_msec_threshold): # msec_per_frame - ...			
				stray.step()
			else:
				var msec_to_next_frame: float = throttler_msec_threshold + 1
				var sec_to_next_frame: float = msec_to_next_frame / 1000.0
				yield(get_tree().create_timer(sec_to_next_frame), "timeout") # da se vsi straysi spawnajo
				throttler_start_msec = Time.get_ticks_msec()
				# printt("over frame_time on: %s" % "stray line step")
		
		# spawnam noveo rundo, če je izpolnjen pogoj
		if line_steps_since_spawn_round == line_steps_per_spawn_round: # tukaj, da ne spawna če je konec
			call_deferred("create_strays", random_spawn_count)
			line_steps_since_spawn_round = 0
		
		line_steps_since_spawn_round += 1 # runda se šteje samo, če spawnam
	
		line_step_in_progress = false
	
	line_step_pause_timer.start(line_step_pause_time)

		
func play_stepping_sound(current_player_energy_part: float):

	if not Global.sound_manager.game_sfx_set_to_off:
		var random_step_index = randi() % $Sounds/Stepping.get_child_count()
		var selected_step_sound = $Sounds/Stepping.get_child(random_step_index)
		selected_step_sound.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
		selected_step_sound.play()


func _on_LineStepPauseTimer_timeout() -> void:
	line_step()


func _on_EngineStalledTimer_timeout() -> void:
	
	# če so pozicije še zmeraj prazne je stalled
	if free_home_positions.empty():
		print("prazne home pozicije II")
		game_over(GameoverReason.TIME)

