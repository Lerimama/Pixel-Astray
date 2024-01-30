extends GameManager # default game manager


# premik straysov
var lines_scrolled_count: int = 0 # prištevam v stray_step()
#var all_lines_scrolled_count: int = 0
# spawnig round iz ? števila premikov ... se ureja v stray_step()
var lines_scroll_per_round: int = 7
var current_stray_spawning_round: int = 0 # prištevam na koncu spawna
var stray_spawning_rounds_per_stage: int = 1
# stage iz ? števila spawning rund ... točk ali česa drugega ... se ureja v set_stray_()
var current_stage: int = 0 # na štartu se kliče stage up
var stages_per_level: int = 3
# level iz ? števila spawnov
var current_level: int = 0 # na štartu se kliče level up
var levels_per_game: int = 2

# steps 
var stray_step_time: float = 0.2
var scrolling_pause_time: float = 0.5

func _ready() -> void:

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_scrolling.tscn")
	PlayerPixel = preload("res://game/pixel/player_scrolling.tscn")
	randomize()


func set_game(): 
	# namen: setam level indikatorje in strayse spawnam po štratu igre
	
	# kliče main.gd pred prikazom igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
#
#	set_fresh_level_indicators()
#	set_strays()
	
	yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda

	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu

	start_game()

	

func start_game():

	Global.hud.game_timer.start_timer()
	Global.sound_manager.play_music("game_music")

	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.set_physics_process(true)
	
	yield(get_tree().create_timer(2), "timeout") # čaka na hudov slide in
	game_on = true
	set_strays()
#	set_fresh_level_indicators()

	stray_step() # prvi step


func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if gameover_reason == GameoverReason.TIME:
		return
	if gameover_reason == GameoverReason.CLEANED:
		all_strays_died_alowed = true
		yield(self, "all_strays_died")
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.all_cleaned()
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	stop_game_elements()
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
	
# SETUP --------------------------------------------------------------------------------------


func set_game_view():

	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"

	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start

	# SCOLLER ... 1 ekran tudi v prmeru dveh plejerjev
	viewport_container_2.visible = false
	viewport_separator.visible = false
	# /

	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	Global.player1_camera.set_camera_limits()
	

func set_level_colors():
#func set_fresh_level_indicators():

	var spectrum_image: Image
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		level_indicator_color_offset = spectrum_texture_width / stages_per_level

	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, Profiles.current_color_scheme[1])
		gradient.set_color(1, Profiles.current_color_scheme[2])
		level_indicator_color_offset = 1.0 / stages_per_level

	var selected_color_position_x: float
	var current_color: Color
	var all_level_colors: Array = [] # za color indikatorje

	for stage in stages_per_level:
		if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
		all_level_colors.append(current_color)

	Global.hud.spawn_color_indicators(all_level_colors) # barve pokažem v hudu	
#	current_stray_spawning_round += 1

	
func set_players():
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.modulate = Global.color_white
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
		
		# players camera
		if spawned_player_index == 1:
			new_player_pixel.player_camera = Global.player1_camera
#			new_player_pixel.player_camera.camera_target = new_player_pixel
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
#			new_player_pixel.player_camera.camera_target = new_player_pixel

# SCROLLER

#func upgrade_stage():
#	pass
#func upgrade_level():
#	pass

func check_stage_and_level():
#	if current_progress_type == LevelProgressType.SPAWNING_ROUND:
	
#	printt("current_stray_spawning_round ", current_stray_spawning_round)
	# stage up
	if current_stage < stages_per_level and not current_stray_spawning_round == 1:
		match current_progress_type:
#			LevelProgressType.COLORS_PICKED:
#				if current_stray_spawning_round % stray_spawning_rounds_per_stage == 0 and not current_stray_spawning_round == 0:
#					Global.hud.update_indicator_on_stage_up(current_stage) # povdari indikator
#					current_stage += 1
#					printt ("current stage", current_stage)
			LevelProgressType.SPAWNING_ROUND:
				if current_stray_spawning_round % stray_spawning_rounds_per_stage == 0:# and not current_stray_spawning_round == 0:
					current_stage += 1
					printt ("current stage", current_stage)
					Global.hud.update_indicator_on_stage_up(current_stage) # povdari indikator
						
	# level up ... ob štartu
	else:
		
		# če ne presega max levelov
		if current_level <= levels_per_game:
			
			current_level += 1 # številka trenutnega levela 
			printt ("current level", current_level)
#			game_data["level"] = current_level # update v slovarju
			# poštimam level
#			set_fresh_level_indicators() # ... premaknjeno v hud
			var color_scheme_name: String = "color_scheme_%s" % current_level
			Profiles.current_color_scheme = Profiles.game_color_schemes[color_scheme_name]
			Global.hud.empty_color_indicators() # novi indkatorji
			set_level_colors() 	
#			Global.hud.update_indicator_on_level_up(current_level) # novi indkatorji
			# poštimam prvi stage levela 
			current_stage = 1 # resetiram na prvi stage levela
			printt ("current stage", current_stage)
			Global.hud.update_indicator_on_stage_up(current_stage) # obarvaj prvega
#			current_stage += 1
		
			set_level_conditions()	
			
		# če presega max levele ... game over
		else:
			game_over(GameoverReason.TIME)
			return # da ne pride dp novega spawna


	
enum LevelProgressType {TIME, COLORS_PICKED, STRAYS_SPAWNED, SPAWNING_ROUND}
var current_progress_type: int = LevelProgressType.SPAWNING_ROUND		
var level_stray_step_pause: Dictionary = {
	1: 0.5,
	2: 0.45,
	3: 0.4,
	4: 0.35,
	5: 0.3,
	6: 0.25,
	7: 0.2,
	8: 0.15,
	9: 0.1,
	10: 0.05,
} 

	
func set_level_conditions():	
	game_data["strays_start_count"] = 14 # debug
	var strays_to_spawn: int = game_data["strays_start_count"]
	
	# level settings
	match current_level:
		1:
#			strays_to_spawn = game_data["strays_start_count"] / 3
			scrolling_pause_time = level_stray_step_pause[3]
		2:
#			strays_to_spawn = game_data["strays_start_count"] / 3
			scrolling_pause_time = level_stray_step_pause[3]
		3:
#			strays_to_spawn = game_data["strays_start_count"] / 3
			scrolling_pause_time = level_stray_step_pause[3]
		4:
#			strays_to_spawn = game_data["strays_start_count"] / 2
			scrolling_pause_time = level_stray_step_pause[4]
		5:
#			strays_to_spawn = game_data["strays_start_count"] / 2
			scrolling_pause_time = level_stray_step_pause[5]
		6:
#			strays_to_spawn = game_data["strays_start_count"] / 2
			scrolling_pause_time = level_stray_step_pause[6]
		7:
#			strays_to_spawn = game_data["strays_start_count"]
			scrolling_pause_time = level_stray_step_pause[7]
		8:
#			strays_to_spawn = game_data["strays_start_count"]
			scrolling_pause_time = level_stray_step_pause[8]


func set_strays(): # ob štartu pred vsako rundo respawna ... torej vrednosti setaš za trenutni level
	
	if not game_on:
		return
		
	current_stray_spawning_round += 1
		
	check_stage_and_level() # level stage logika
#	printt ("current level", current_level)
#	printt ("current stage", current_stage)
	
#	set_level_conditions()	
#	game_data["strays_start_count"] = 14
	
	spawn_strays(game_data["strays_start_count"]) # indikatorje moram poštimat pred spawnanjem straysov


func spawn_strays(strays_to_spawn_count: int):

	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			

	var spectrum_image: Image
	var color_offset: float
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		# razmak med barvami za strayse
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		color_offset = spectrum_texture_width / strays_to_spawn_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, Profiles.current_color_scheme[1])
		gradient.set_color(1, Profiles.current_color_scheme[2])
		# razmak med barvami za strayse
		color_offset = 1.0 / strays_to_spawn_count

	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"

	var all_colors: Array = [] # za color indikatorje

	for stray_index in strays_to_spawn_count:

		# barva
		var current_color: Color
		var selected_color_position_x: float
		if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu

		# možne spawn pozicije
		var current_spawn_positions: Array
		if not available_required_spawn_positions.empty(): # najprej obvezne
			current_spawn_positions = available_required_spawn_positions
		elif available_required_spawn_positions.empty(): # potem random
			current_spawn_positions = available_random_spawn_positions
		elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
			print ("No available spawn positions")
			return

		# random pozicija med možnimi
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position = current_spawn_positions[selected_cell_index]

		# spawn stray
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		# odstranim uporabljeno pozicijo
		new_stray_pixel.show_stray()
		current_spawn_positions.remove(selected_cell_index)


	self.strays_in_game_count = strays_to_spawn_count # setget sprememba


func stray_step():
	
	var stepping_direction: Vector2
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		
		stepping_direction = Vector2.DOWN
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.IDLE: 
				stray.step(stepping_direction)
		
		yield(get_tree().create_timer(scrolling_pause_time), "timeout")
		
		lines_scrolled_count += 1
		if lines_scrolled_count > lines_scroll_per_round:
			lines_scrolled_count = 0
			set_strays()
		
	if game_on:
		stray_step()

