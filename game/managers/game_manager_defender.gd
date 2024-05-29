extends GameManager # default game manager


# stepping
var line_step_in_progress: bool = false
var line_steps_count: int = 0 # prištevam v stray_step()
var line_steps_per_spawn_round: int #  = 1 # se vleče game data
var line_step_pause_time: float # = 0 # pavza med stepi

# stage and level
var current_stage: int = 0 # na štartu se kliče stage up
var stages_per_level: int
var current_level: int = 0 # na štartu se kliče level up
var levels_per_game: int = 1

# spawn engine
var current_stray_spawning_round: int = 0 # prištevam na koncu spawna
var available_home_spawn_positions: Array
var spawn_round_range: Array
var total_spawn_round_positions_count: int = 20 # določeno v tilemapu ... 20 x na linijo
var engine_stalled_checking_time: float = 2 # dobro da je večji od stepa ali respawn pavze

onready var engine_stalled_timer: Timer = $"../EngineStalledTimer"
onready var line_step_pause_timer: Timer = $"../LineStepPauseTimer"


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("l"):
		upgrade_level("regular")	

			
func _ready() -> void:
	# namen: ugasnem stray pos indikatorje tako da dam limito na 0

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_defender.tscn")
	PlayerPixel = preload("res://game/pixel/player_defender.tscn")
	
	randomize()
	
	show_position_indicators_limit = 0		
	
	
func _process(delta: float) -> void:
	# namen: kličem stray step, čekiram zasedenost home spawn pozicij in kličem GO
	# namen: ni preverjanja avail respawn pozicij in GO
	
	if game_on:
		if not line_step_in_progress:
			new_line_step()

		
func set_game(): 
	# namen: setam level indikatorje in strayse spawnam po štratu igre
	
	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in current_players_in_game:
		player.animation_player.play("lose_white_on_start")
#		player.animation_player.play_backwards("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda
	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	start_game()
	yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
	Global.current_tilemap.background_room.hide()
	

func start_game():
	
	Global.hud.game_timer.start_timer()
	
	Global.sound_manager.currently_playing_track_index = game_settings["game_track_index"]
	Global.sound_manager.play_music("game_music")
	
	for player in current_players_in_game:
		player.set_physics_process(true)
	
	yield(get_tree().create_timer(2), "timeout") # čaka na hudov slide in
	game_on = true
	
	upgrade_level("regular")
	
	spawn_strays(start_strays_spawn_count)


func game_over(gameover_reason: int):
	# namen: samo TIME in LIFE, CLEANED je level ampak upgrade
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	stop_game_elements()
	Global.current_tilemap.background_room.show()
	Global.gameover_gui.open_gameover(gameover_reason)
		
		
# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	# namem: dodam povezavo s signalom  iz aree	
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	tilemap_to_release.free()
	
	# spawn new tilemap
	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
	var new_tilemap = GameTilemap.instance()
	Global.node_creation_parent.add_child(new_tilemap) # direct child of root
	
	# povežem s signalom	
	Global.current_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	
	# grab tilemap tiles
	Global.current_tilemap.get_tiles()
	cell_size_x = Global.current_tilemap.cell_size.x 


func set_game_view():
	#namen: ... tudi fiksirana kamera
	
	Global.game_camera.position = Global.current_tilemap.camera_position_node.global_position
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()

	
func set_players():
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

# STRAYS -----------------------------------------------------------------------------


func spawn_strays(strays_to_spawn_count: int):
	# namen: no clampin, ker je lahko spawn 0
	# namen: v žrebanje vključim samo home spawn pozicije na voljo ... ni preverjanja vseh drugih mogočih pozicij
	# namen: vsak spawn vključuje tudi show_stray()
	# namen: preverjam GO

	for stray_index in strays_to_spawn_count:
		
		# žrebam barvo
		var random_color_range = all_stray_colors.size()
		var random_selected_index: int = randi() % int(random_color_range) # + 1		
		var random_selected_color: Color = all_stray_colors[random_selected_index]		
		
		if not available_home_spawn_positions.empty(): 
			# možne spawn pozicije
			var current_spawn_positions: Array = available_home_spawn_positions
			# random pozicija med možnimi
			var random_range = current_spawn_positions.size()
			var selected_cell_index: int = randi() % int(random_range)# + 1		
			var selected_position = current_spawn_positions[selected_cell_index]
			# spawn stray
			var new_stray_pixel = StrayPixel.instance()
			new_stray_pixel.name = "S%s" % str(stray_index)
			new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
			new_stray_pixel.z_index = 2 # višje od plejerja
			new_stray_pixel.stray_color = random_selected_color
			#		Global.node_creation_parent.add_child(new_stray_pixel)
			Global.node_creation_parent.call_deferred("add_child", new_stray_pixel)
			
			# odstranim uporabljeno pozicije in barve dodam v števec
			available_home_spawn_positions.erase(selected_position)
			#		new_stray_pixel.show_stray()
			new_stray_pixel.call_deferred("show_stray")		
			self.strays_in_game_count = 1 # setget sprememba
			
	current_stray_spawning_round += 1


func new_line_step():
	
	# preverjama available positions
	available_home_spawn_positions = random_spawn_positions.duplicate() # vsakič znova zajamemo vse in ji potem odštejemo trenutno zasedene ... 
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if available_home_spawn_positions.has(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
			available_home_spawn_positions.erase(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2))
	# preverjam za GO engin stalled
	if available_home_spawn_positions.empty():
		print("prazne pozicije I")
		# sprožim tajmer, ki na koncu pozicije preveri še enkrat
		engine_stalled_timer.start(engine_stalled_checking_time)
	else:
		engine_stalled_timer.stop() # zazih
			
	line_step_in_progress = true
			
	var stepping_direction: Vector2
	
	# random spawn count
	var stray_spawn_count_min: int = spawn_round_range[0]
	var stray_spawn_count_max: int = spawn_round_range[1]
	var random_spawn_count: int = randi() % stray_spawn_count_max + stray_spawn_count_min
	# odštejem kar je višje od max range, ker zamik zamakne tudi zgornjo mejo
	if random_spawn_count > stray_spawn_count_max: 
		random_spawn_count -= random_spawn_count - stray_spawn_count_max
	# če je spawn število večje od pozicij na voljo
	if random_spawn_count > available_home_spawn_positions.size():# and not available_home_spawn_positions.empty():
		random_spawn_count = available_home_spawn_positions.size()
		
	if not level_upgrade_in_progress:
		stepping_direction = Vector2.DOWN # kasneje se seta glede na  izvorno stray straysa
		# kdo stepa, kličem step in preverim kolajderja 
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			stray.call_deferred("step", stepping_direction)
		# Global.sound_manager.play_sfx("stray_step") # ulomek je za pitch zvoka
		if line_steps_count % line_steps_per_spawn_round == 0: # tukaj, da ne spawna če je konec
			spawn_strays(random_spawn_count)
	
	line_step_pause_timer.start(line_step_pause_time)
	

		
func play_stepping_sound(current_player_energy_part: float):

	if Global.sound_manager.game_sfx_set_to_off:
		return		

	var random_step_index = randi() % $Sounds/Stepping.get_child_count()
	var selected_step_sound = $Sounds/Stepping.get_child(random_step_index)
	selected_step_sound.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
	selected_step_sound.play()
	
		
# LEVELING --------------------------------------------------------------------------------------


func upgrade_stage():
	# kliče stray na die
	
	# stage up na vsak klic ... tudi ob apgrejdanju level
	current_stage += 1
	Global.hud.update_indicator_on_stage_up(current_stage) # povdari indikator
	
	# če je dosežen level se izvede tudi upgrade levela (ima pavzo)
	if current_stage == stages_per_level:
		upgrade_level("regular")


func upgrade_level(level_upgrade_reason: String):
	# namen: zaporedje, respawn ven, set strays ven, ker jih spawna s stepanjem

	if level_upgrade_in_progress:
		return
	level_upgrade_in_progress = true
	randomize()

	current_level += 1 # številka novega levela 
	current_stage = 0 # ker se šteje pobite strayse je na začetku 0
	line_steps_count = 0

	if current_level > 1:
		#reset players
		Global.hud.level_up_popup_inout(current_level)
#		Global.hud.level_up_popup_in(current_level)
		for player in current_players_in_game:
			player.end_move()		
			if level_upgrade_reason == "cleaned":
				player.on_screen_cleaned()
		Global.hud.empty_color_indicators() # novi indkatorji
#		get_tree().call_group(Global.group_players, "set_physics_process", false)
		set_new_level() 
		set_level_colors() # more bit pred yieldom in tudi, če so že spucani
#		if not get_tree().get_nodes_in_group(Global.group_strays).empty():
#			clean_strays_in_game() # puca vse v igri
#		yield(self, "all_strays_died") # ko so vsi iz igre grem naprej

		# new level
#		Global.hud.level_up_popup_out()
#		get_tree().call_group(Global.group_players, "set_physics_process", true)	
	else:
		set_new_level() 
		set_level_colors()

	level_upgrade_in_progress = false		


func set_new_level():
	
	# prvi level vzame že zapisane		
	if current_level == 1:
		line_steps_per_spawn_round = game_data["line_steps_per_spawn_round"]
		stages_per_level = game_data["stages_per_level"]
		line_step_pause_time = game_data["line_step_pause_time"]
		spawn_round_range = game_data["spawn_round_range"]
		
	# vsak naslednji level updata nastavitve prejšnjega levela
	elif current_level > 1:
		stages_per_level += stages_per_level + game_data["stages_per_level_grow"]
		line_step_pause_time *= game_data["line_step_pause_time_factor"]
		line_step_pause_time = clamp (line_step_pause_time, 0.2, line_step_pause_time) # ne sem bit manjša od stray step hitrosti (cca 0.2)
		spawn_round_range[0] *= game_data["spawn_round_range_factor"][0]
		spawn_round_range[1] *= game_data["spawn_round_range_factor"][1]
	
	game_data["level"] = current_level


func set_level_colors():
	# barve pedenam ločeno od spawnanja straysov, ker pripadajo stagetu
	# umetno setan nabor barv iz katerega se jemlje barve za spawnanje
	# za stage indikatorje razdelim umetno setan nabor barv na delov kot je stagetov
	
	# naberi barve
	var all_stray_colors_count: int = 100
	all_stray_colors = [] # reset
	if current_level <= 1: # na začetku je pisana tema
		all_stray_colors = Global.get_spectrum_colors(all_stray_colors_count)
	else:
		all_stray_colors = Global.get_random_gradient_colors(all_stray_colors_count)
	
	# izbor barv za stage indikatorje
	var stage_indicator_colors: Array
	for stage_count in stages_per_level:
		var color_offest_per_stage: float = all_stray_colors_count / stages_per_level
		var stage_color_index: int = stage_count * color_offest_per_stage
		if stage_color_index > all_stray_colors.size() - 1:
			stage_color_index = all_stray_colors.size() - 1
		stage_indicator_colors.append(all_stray_colors[stage_color_index])

	Global.hud.spawn_color_indicators(stage_indicator_colors) # barve pokažem v hudu	
		


func _on_LineStepPauseTimer_timeout() -> void:
	line_step_in_progress = false


func _on_EngineStalledTimer_timeout() -> void:
	
	# če so pozicije še zmeraj prazne je stalled
	if available_home_spawn_positions.empty():
		print("prazne pozicije II")
		game_over(GameoverReason.TIME)

