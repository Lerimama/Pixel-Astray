extends Node
class_name GameManager


signal all_strays_spawned
signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var level_upgrade_in_progress: bool = false # ustavim klicanje naslednjih levelov
var current_level: int = 1 # napolne ga game_data["level"]
var level_goal_mode: bool = false
var throttler_msec_threshold: int = 5 # koliko msec je še na voljo v frejmu, ko raje premaknem na naslednji frame

# players
var spawned_player_index: int = 0
var start_players_count: int
var current_players_in_game: Array # nabira se v FP

# strays
var strays_shown_on_start: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int = 0 # za statistiko na hudu
var check_for_all_cleaned: bool = false # za omejevanje signala iz FP ... kdaj lahko reagira na 0 straysov v igri
var dont_turn_to_wall_positions: Array # za zaščito, da wall stray ne postane wall (ob robu igre recimo)
var show_position_indicators: bool = false # na začetku jih ne rabim gledat

# colors
var all_stray_colors: Array = [] # barve spawnanih (resnični color ... iste se pač podvajajo se) ... puca se ko stray umrje
var color_pool_colors: Array = []

# tilemap
var cell_size_x: int # napolne se na koncu setanju tilemapa
var player_start_positions: Array
var random_spawn_positions: Array
var required_spawn_positions: Array # vključuje tudi wall_spawn_positions
var wall_spawn_positions: Array
var free_floor_positions: Array # = [] # to so vse proste

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var create_strays_count: int = game_settings["create_strays_count"] # število se lahko popravi iz tilempa signala
onready var spawn_white_stray_part: float = game_settings["spawn_white_stray_part"]
onready var respawn_pause_time: float = game_settings["respawn_pause_time"]
onready var respawn_strays_count_range: Array = game_settings["respawn_strays_count_range"]
onready var StrayPixel: PackedScene = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel: PackedScene = preload("res://game/pixel/player.tscn")
onready var respawn_timer: Timer = $"../RespawnTimer"

# bugfixing
var FreePositionIndicator: PackedScene = preload("res://game/pixel/free_position_indicator.tscn")		
var free_position_indicators: Array


func _unhandled_input(event: InputEvent) -> void:

	# bugfixing
	#	if Input.is_action_just_pressed("no1"):
	#		game_over(GameoverReason.LIFE)
	#	if Input.is_action_just_pressed("no2"):
	#		game_over(GameoverReason.TIME)
	#	if Input.is_action_just_pressed("no3"):
	#		game_over(GameoverReason.CLEANED)
	#	if Input.is_action_just_pressed("l"):
	#		upgrade_level()	

	if Input.is_action_just_pressed("hint") and game_data["game"] == Profiles.Games.SWEEPER:
		Global.current_tilemap.solution_line.visible = not Global.current_tilemap.solution_line.visible
		
	
func _ready() -> void:

	Global.game_manager = self
	
	randomize()
	if game_data.has("level_goal_count"):
		# prvi level eraserja ima za cilj število spawnanih
		#		if game_data["game"] == Profiles.Games.SWEEPER:
		#			game_data["level_goal_count"] = create_strays_count
		level_goal_mode = true
	
	
	Global.allow_focus_sfx = false


func _process(delta: float) -> void:
	
	# če sem v fazi, ko lahko preverjam cleaned (po spawnu)
	#	if check_for_all_cleaned:
	#		# če ni nobene stene, me zanimajo samo prazni strajsi
	#		if strays_in_game_count == 0:
	#			check_for_all_cleaned = false
	#			emit_signal("all_strays_died")
	
	# position indicators
	if game_on and Global.strays_on_screen.size() < game_settings["position_indicators_show_limit"]:
		show_position_indicators = true
	else:
		show_position_indicators = false


# GAME SETUP --------------------------------------------------------------------------------------
	
			
func set_tilemap(): # kliče MAIN pred fade-in scene 01.
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
				
	if game_data["game"] == Profiles.Games.SWEEPER:
		game_data["tilemap_path"] = Profiles.sweeper_level_tilemap_paths[game_data["level"] - 1]
		
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	tilemap_to_release.free()
	
	# spawn new tilemap
	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
	var new_tilemap = GameTilemap.instance()
	Global.game_arena.add_child(new_tilemap) # direct child of root
	
	# povežem s signalom	
	Global.current_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	
	# grab tilemap tiles
	Global.current_tilemap.get_tiles()
	cell_size_x = Global.current_tilemap.cell_size.x 
			
	if game_data["game"] == Profiles.Games.SWEEPER:
		Global.current_tilemap.get_node("SolutionLine").hide()
		
	
func set_game_view(): # kliče MAIN pred fade-in scene 02.
	
	Global.game_camera.position = Global.current_tilemap.camera_position_node.global_position	
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	Global.game_camera.set_camera_limits()

	# camera modes
	if game_settings["zoom_to_level_size"]:
		Global.game_camera.set_zoom_to_level_size()
	if game_settings["always_zoomed_in"]:
		Global.game_camera.zoom = Global.game_camera.zoom_end
	if game_data["game"] == Profiles.Games.ERASER_XS or game_data["game"] == Profiles.Games.ERASER_S:
		# mehkejše kamera za manjše ekrane
		Global.game_camera.smoothing_speed = 5		
	
		
func set_game(): # kliče MAIN po fade-in scene 05.
	 # še prej se kličejo... set_tilemap(), set_game_view(), create_players() # da je plejer viden že na fejdin

	# positions
	free_floor_positions = Global.current_tilemap.all_floor_tiles_global_positions.duplicate()
	for free_pos in free_floor_positions:
		spawn_free_position_indicator(free_pos)
	# colors 
	set_color_pool()
	
	# players ready?
	if game_settings["show_game_instructions"]:
		yield(Global.hud, "players_ready")
	
	Global.hud.slide_in() # pokaže countdown
	
	# player
	current_players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	var signaling_player: KinematicBody2D
	for player in current_players_in_game:
		player.animation_player.play("lose_white_on_start")
	#		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	#	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	# strays
	create_strays(create_strays_count)
	yield(self, "all_strays_spawned")
	
	# countdown
	if game_settings["start_countdown"]:
		Global.hud.start_countdown.start_countdown() # GM yielda za njegov signal
		yield(Global.hud.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	else:
		yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
	
	start_game()
	
	if game_data["game"] == Profiles.Games.SWEEPER: # če je prejse povozi
		game_settings["always_zoomed_in"] = true # setam zoom trenutni igri, da ni zooma na koncu


# GAME LOOP --------------------------------------------------------------------------------------


func start_game():
	
	# select music
	if game_data["game"] == Profiles.Games.CLEANER and Global.tutorial_gui.tutorial_on:
		Global.tutorial_gui.open_tutorial()
		Global.sound_manager.current_music_track_index = Profiles.tutorial_music_track_index
	else:
		Global.sound_manager.current_music_track_index = game_settings["game_music_track_index"]
	
	for player in current_players_in_game:
		if not game_settings ["zoom_to_level_size"]:
			Global.game_camera.camera_target = player
		player.set_physics_process(true)

	Global.sound_manager.play_music("game_music")
	Global.hud.game_timer.start_timer()
	
		
	game_on = true
	
	#	printt("on start",free_floor_positions.size())
	

func game_over(gameover_reason: int):
	
	if game_on: # preprečim double gameover
		
		game_on = false
		
		Global.hud.game_timer.stop_timer()
		
		if gameover_reason == GameoverReason.CLEANED:
			check_for_all_cleaned = true
			#		yield(self, "all_strays_died")
			var signaling_player: KinematicBody2D
			for player in current_players_in_game:
				player.on_screen_cleaned()
				signaling_player = player
			yield(signaling_player, "rewarded_on_cleaned")
		else:
			if game_data["game"] == Profiles.Games.CLEANER and Global.tutorial_gui.tutorial_on:
				Global.tutorial_gui.close_tutorial()
			yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
			
		stop_game_elements()
		get_tree().call_group(Global.group_players, "set_physics_process", false)
		
		Global.gameover_gui.open_gameover(gameover_reason)


func stop_game_elements():
	# včasih nujno
	
	if game_data["game"] == Profiles.Games.CLEANER and Global.tutorial_gui.tutorial_on:
		Global.tutorial_gui.close_tutorial()
	Global.hud.popups_out()
	for player in current_players_in_game:
		player.end_move()
		player.stop_sound("teleport")
		player.stop_sound("heartbeat")


# LEVELS --------------------------------------------------------------------------------------------	


func set_new_level(): 
	
	# in level spawn
	if game_settings["respawn_strays_count_range"][1] > 0:
		respawn_pause_time *= game_data["respawn_pause_time_factor"]
		respawn_pause_time = clamp(respawn_pause_time, game_settings["respawn_pause_time_low"], respawn_pause_time)
		respawn_strays_count_range[0] += game_data["respawn_strays_count_range_grow"][0]
		respawn_strays_count_range[1] += game_data["respawn_strays_count_range_grow"][1]
	# level start spawn
	if current_level == 2: # 2. level je prvi level ko se štarta zares
		create_strays_count = game_settings["create_strays_count"]
	else:
		create_strays_count += game_data["create_strays_count_grow"]
	# število spawnanih belih
	if game_data.has("spawn_white_stray_part_grow"):# and current_level == 2: # 1. level je 0, potem pa je konstanten
		spawn_white_stray_part += game_data["spawn_white_stray_part_grow"]
		spawn_white_stray_part = clamp(spawn_white_stray_part, 0, game_settings["spawn_white_stray_part_limit"])
	# level goal count
	if level_goal_mode:
		game_data["level_goal_count"] += game_data["level_goal_count_grow"]
	
	game_data["level"] = current_level


func upgrade_level(upgrade_on_cleaned: bool =  false):
	
#	if level_upgrade_in_progress or not game_on: # zazih game_on pogoj 
#		return
	if not level_upgrade_in_progress and game_on: # zazih game_on pogoj 
	
		level_upgrade_in_progress = true	
	
		randomize()
		
		respawn_timer.stop()
		
		# če je spucano, dobi player nagrado
		if upgrade_on_cleaned:
			for player in current_players_in_game:
				player.end_move()
				player.on_screen_cleaned()
		
		current_level += 1 # številka novega levela 
		set_color_pool()
		set_new_level() 
		Global.hud.level_popup_fade(current_level)
		Global.hud.spawn_color_indicators(get_level_colors())
		
		level_upgrade_in_progress = false
		
		if game_settings["respawn_strays_count_range"][1] > 0:
			respawn_timer.start(respawn_pause_time)
	
	
func get_level_colors():
	
	# level colors
	var level_indicator_colors: Array
	
	# prvi level ima barv toliko kot se jih spawna
	var level_colors_count: int
	if level_goal_mode:
		level_colors_count = game_data["level_goal_count"]# - prev_level_goal_count
	else:
		level_colors_count = create_strays_count
		
	var color_offset: int = floor(color_pool_colors.size() / level_colors_count)
	for goal_count in level_colors_count:
		var color_index: int = goal_count * color_offset
		level_indicator_colors.append(color_pool_colors[color_index])
	
	return level_indicator_colors
	
				
# PIXELS --------------------------------------------------------------------------------------------	
	
		
func create_players(): # kliče MAIN pred fade-in scene 04.
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.game_arena.add_child(new_player_pixel)
		
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
	# on start, cleaned in level upgrade
	
	if strays_to_spawn_count == 0:
		print ("Create strays spawn count is 0")
	else:
		var color_pool_split_size: int = floor(color_pool_colors.size() / strays_to_spawn_count)
		
		# positions
		var available_required_spawn_positions = required_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
		var available_random_spawn_positions = random_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
		
		var strays_set_to_spawn: Array = [] # naložim setingse za vsakega straysa, da jijh lahko spawnam z zamikom ... (stray_index, new_stray_color, selected_stray_position, turn_to_white)
		
		# set strays to spawn
		for stray_index in strays_to_spawn_count: 
			
			var new_stray_color_pool_index: int = stray_index * color_pool_split_size
			var new_stray_color: Color = color_pool_colors[new_stray_color_pool_index] # barva na lokaciji v spektrumu
			
			# spawn positions
			var current_spawn_positions: Array
			# če je level game in je level večji od 1, so na voljo vsa prazna tla ... če ne pozicije regulira tilemap
			if current_level > 1 and not game_data["game"] == Profiles.Games.SWEEPER: # leveli večji od prvega ... random respawn
				current_spawn_positions = free_floor_positions.duplicate()
			else:
				# najprej obvezne pozicije, potem random pozicije, ko so obvezne spraznjene
				if not available_required_spawn_positions.empty():
					# najprej bele pixle, potem barvne
					if not wall_spawn_positions.empty():
						current_spawn_positions = wall_spawn_positions
					else: 
						current_spawn_positions = available_required_spawn_positions
				elif not available_random_spawn_positions.empty():
					current_spawn_positions = available_random_spawn_positions
				
			# žrebanje random pozicije določenih spawn pozicij
			var random_range = current_spawn_positions.size()
			var selected_cell_index: int = randi() % int(random_range)		
			var selected_cell_position: Vector2 = current_spawn_positions[selected_cell_index]
			var selected_stray_position: Vector2 = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)
			
			# je white? ... če pozicija bela in, če je index večji od planiranega deleža belih
			var turn_to_white: bool = false
			if not game_data["game"] == Profiles.Games.THE_DUEL and not game_data["game"] == Profiles.Games.STALKER:
				var spawn_white_spawn_limit: int = strays_to_spawn_count - round(strays_to_spawn_count * spawn_white_stray_part)
				if wall_spawn_positions.has(selected_cell_position) or stray_index > spawn_white_spawn_limit: 
					turn_to_white = true
			
			# če je prazna spawnam, drugače preskočim spawn in odštejem število potrebnih za spavnanje (na koncu preverjam, da ni število spawnanih 0)
			if free_floor_positions.has(selected_cell_position):
				strays_set_to_spawn.append([stray_index, new_stray_color, selected_stray_position, turn_to_white])
				all_stray_colors.append(new_stray_color)
			else: # varovalka overspawn ... če je zasedena se ne spawna in takega streya ne spawnam več
				printt ("overspawn - on GM create") 
				strays_to_spawn_count -= 1

			# apdejtam tilemap pozicije ... če se ne spawna, moram pozicijo vseeno brisat, če ne se spawnajo vsi na to pozicijo
			wall_spawn_positions.erase(selected_cell_position)
			available_required_spawn_positions.erase(selected_cell_position)
			available_random_spawn_positions.erase(selected_cell_position)
		
		# spawn
		var throttler_start_msec = Time.get_ticks_msec()
		var spawned_strays_true_count: int = 0
		for set_stray in strays_set_to_spawn:
			var stray_index = set_stray[0]
			var new_stray_color = set_stray[1]
			var selected_stray_position = set_stray[2]
			var turn_to_white = set_stray[3]
			# trotlam?
			if game_settings["throttled_stray_spawn"]:	
				# merim čas od štarta funkcije
				var msec_taken = Time.get_ticks_msec() - throttler_start_msec
				if msec_taken < (round(1000 / Engine.get_frames_per_second()) - throttler_msec_threshold): # msec_per_frame - ...			
					spawned_strays_true_count += 1
					spawn_stray(stray_index, new_stray_color, selected_stray_position, turn_to_white)
				# ko je čas večji od dovoljenega, pavziram do naslednjega frejma in resetiram štartni čas
				else:
					var msec_to_next_frame: float = throttler_msec_threshold + 1
					var sec_to_next_frame: float = msec_to_next_frame / 1000.0
					yield(get_tree().create_timer(sec_to_next_frame), "timeout") # da se vsi straysi spawnajo
					throttler_start_msec = Time.get_ticks_msec()
					# printt("over frame_time on: %s" % "create_strays", (strays_set_to_spawn.size() - stray_index), msec_taken, round(1000 / Engine.get_frames_per_second()))
			else:
				spawned_strays_true_count += 1
				spawn_stray(stray_index, new_stray_color, selected_stray_position, turn_to_white)
		
		# ko trotlam preskakuje spawne, zato ponovim
		if spawned_strays_true_count < strays_to_spawn_count and not spawned_strays_true_count == 0:
			create_strays(strays_to_spawn_count - spawned_strays_true_count)
			# print("razlika %s" % (strays_to_spawn_count - spawned_strays_true_count))
			return
				
		if level_goal_mode:
			Global.hud.spawn_color_indicators(get_level_colors())
		else:	
			Global.hud.spawn_color_indicators(all_stray_colors) # barve pokažem v hudu		

		var show_strays_loop: int = 0
		strays_shown_on_start.clear()
		while strays_shown_on_start.size() < create_strays_count:
			show_strays_loop += 1
			show_strays_in_loop(show_strays_loop)
			yield(get_tree().create_timer(0.1), "timeout") # nujen zamik
		
		emit_signal("all_strays_spawned")


func show_strays_in_loop(show_strays_loop: int): # spawn naenkrat

	var spawn_shake_power: float = 0.30
	var spawn_shake_time: float = 0.7
	var spawn_shake_decay: float = 0.2	
	Global.game_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	match show_strays_loop:
		1:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/10)
		2:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/8)
		3:
			strays_to_show_count = round(strays_in_game_count/4)
		4:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/2)
		5: # še preostale
			strays_to_show_count = strays_in_game_count - strays_shown_on_start.size()
	
	# stray fade-in
	var loop_count = 0
	for stray in get_tree().get_nodes_in_group(Global.group_strays): # nujno jih ponovno zajamem
		if strays_shown_on_start.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			break
		if loop_count >= strays_to_show_count:
			stray.show_stray()
			strays_shown_on_start.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže


func respawn_strays(spawn_in_stack: bool = true):
	
	# določim število spawnanih
	var respawn_strays_count: int = randi() % respawn_strays_count_range[1] - respawn_strays_count_range[1] # razlika med spodnjo in zgornjo mejo
	respawn_strays_count += respawn_strays_count_range[1] # izbrano število dvignem za višino spodnje meje
	
	var available_stack_cell_positions: Array = [] # pozicije sosednje pravkar spawnanim straysom
	
	var current_spawned_strays_count: int = 0 # varovalk za preverjanje uspešnosti
	
	# spawn ... trotlam
	var throttler_start_msec = Time.get_ticks_msec()
	for stray_index in respawn_strays_count:
		var msec_taken = Time.get_ticks_msec() - throttler_start_msec
		if msec_taken < (round(1000 / Engine.get_frames_per_second()) - throttler_msec_threshold): # msec_per_frame - ...			
			# če ni praznih pozicij ne spawnam ... zazih
			if free_floor_positions.empty():
				pass
			else:
				# select color
				var random_color_index: int = randi() % int(color_pool_colors.size())		
				var spawned_stray_color: Color = color_pool_colors[random_color_index]
				
				# izbrišem stack pozicije, če niso med praznimi (v prvem koraku so sosednje poz prazne
				for stack_cell_position in available_stack_cell_positions:
					if not available_stack_cell_positions.has(stack_cell_position):
						available_stack_cell_positions.erase(stack_cell_position)
				# pozicije
				var selected_stray_position: Vector2

				var selected_cell_position: Vector2
				# prva random pozicija
				if available_stack_cell_positions.empty() or not spawn_in_stack:
					var random_position_index: int = randi() % int(free_floor_positions.size())		
					selected_cell_position = free_floor_positions[random_position_index]
					selected_stray_position = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)
				# stacked random pozicija
				else:
					var random_stack_position_index: int = randi() % int(available_stack_cell_positions.size())		
					selected_cell_position = available_stack_cell_positions[random_stack_position_index]
					selected_stray_position = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)
				
				# pridobim sosednje pozicije trenutne pozicije
				var current_cell_position: Vector2 = selected_cell_position
				var cell_in_check: Vector2
				for y in 3:
					for x in 3:
						cell_in_check = current_cell_position + Vector2(x - 1, y - 1) * cell_size_x
						# če ni izvorna celica in je del (praznih) tal, jo dodam me sosednje pozicije
						if not cell_in_check == current_cell_position and free_floor_positions.has(cell_in_check):
							if not available_stack_cell_positions.has(cell_in_check): # da se ne podvaja
								available_stack_cell_positions.append(cell_in_check)	
				# to white?	
				var turn_to_white: bool = false
				var spawn_white_spawn_limit: int = respawn_strays_count - round(respawn_strays_count * spawn_white_stray_part)
				if stray_index > spawn_white_spawn_limit: 
					turn_to_white = true
				
				if free_floor_positions.has(selected_cell_position):
					# spawn
					var spawned_stray = spawn_stray(stray_index, spawned_stray_color, selected_stray_position, turn_to_white)
					current_spawned_strays_count += 1
					spawned_stray.call_deferred("show_stray")
					yield(get_tree().create_timer(0.1), "timeout")	
		else:
			var msec_to_next_frame: float = throttler_msec_threshold + 1
			var sec_to_next_frame: float = msec_to_next_frame / 1000.0
			throttler_start_msec = Time.get_ticks_msec()
			# printt("over frame_time on: %s" % "respawn_strays")

	# če se ne ne spawna nobeden, takoj probaj še enkrat
	if current_spawned_strays_count == 0:
		print("Error! 0 spawnanih, na respawn. Probam takoj še enkrat ...")
		respawn_strays(spawn_in_stack)


func spawn_stray(stray_index: int, stray_color: Color, stray_position: Vector2, is_white: bool):
	
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "S%s" % str(stray_index)
	new_stray_pixel.stray_color = stray_color
	new_stray_pixel.global_position = stray_position # dodana adaptacija zaradi središča pixla
	new_stray_pixel.z_index = 2 # višje od plejerja
	#	Global.game_arena.call_deferred("add_child", new_stray_pixel)
	Global.game_arena.add_child(new_stray_pixel)
	
	if is_white: 
		new_stray_pixel.current_state = new_stray_pixel.States.WALL
	
	return new_stray_pixel

			
func clean_strays_in_game():
	
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_index: int = get_tree().get_nodes_in_group(Global.group_strays).find(stray)
		stray.die(stray_index, get_tree().get_nodes_in_group(Global.group_strays).size())
	
	check_for_all_cleaned = true


func turn_random_stray_to_white():
	

		
	var wall_strays_alive: Array 
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_to_tile_position: Vector2 = stray.global_position + Vector2(cell_size_x/2, cell_size_x/2)
		if stray.current_state == stray.States.WALL:
			wall_strays_alive.append(stray)
	var strays_not_walls_count: int = get_tree().get_nodes_in_group(Global.group_strays).size() - wall_strays_alive.size()
	
	var random_stray_index: int = randi() % int(strays_not_walls_count)
	if get_tree().get_nodes_in_group(Global.group_strays).size() > random_stray_index: # error prevent
		var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
		random_stray.die_to_wall()
		return random_stray.stray_color
	else: # error
		print("Error - no color to turn to wall")
		return Color.white


# UTILITY ------------------------------------------------------------------------------------
	

func is_floor_position_free(position_in_check: Vector2):
	# pozicija mora biti že snepana
	
	var position_in_check_on_grid = position_in_check - Vector2(cell_size_x/2, cell_size_x/2)
	
	if free_floor_positions.has(position_in_check_on_grid):
		return true
	else: 
		return false
	
	
func remove_from_free_floor_positions(position_to_remove: Vector2):
	# pozicija mora biti že snepana
	
	var position_to_remove_on_grid = position_to_remove - Vector2(cell_size_x/2, cell_size_x/2)
	
	if free_floor_positions.has(position_to_remove_on_grid):
		free_floor_positions.erase(position_to_remove_on_grid)
	
	 # bugfixing ... izbrišem indikator na poziciji, če je freepos prižgan
	if Global.game_arena.free_positions_grid.visible:
		for indicator in free_position_indicators:
			if indicator.rect_position == position_to_remove_on_grid:
				indicator.queue_free()	
				free_position_indicators.erase(indicator)
	
	
func add_to_free_floor_positions(position_to_add: Vector2):
	
	var position_to_add_on_grid = position_to_add - Vector2(cell_size_x/2, cell_size_x/2)
	
	# dodam med free, če je pozicija med original tlemi in, še ni dodana med free
	if Global.current_tilemap.all_floor_tiles_global_positions.has(position_to_add_on_grid) and not free_floor_positions.has(position_to_add_on_grid):
		free_floor_positions.append(position_to_add_on_grid)
		# bugfixing ... dodam indikator na poziciji, če je freepos prižgan
		if Global.game_arena.free_positions_grid.visible: # bugfixing
			spawn_free_position_indicator(position_to_add_on_grid)


func spawn_free_position_indicator(spawn_position: Vector2):
	
	var new_free_position_indicator = FreePositionIndicator.instance()
	new_free_position_indicator.rect_global_position = spawn_position
	Global.game_arena.free_positions_grid.add_child(new_free_position_indicator)
	free_position_indicators.append(new_free_position_indicator)


func set_color_pool():
	# setam kolor pool iz katerega se potem setajo barve v indikatorjih in straysih (spawn in respawn) 
	
	var colors_wanted_count: int = game_settings["color_pool_colors_count"]
	
	# če spawnam več straysov kot je color pool, se pool poveča
	if colors_wanted_count <= game_settings["create_strays_count"]:
		colors_wanted_count = game_settings["create_strays_count"] + 1
	
	color_pool_colors = [] # reset
	
	# level goal game ima vedno original tema v prvem levelu, potem pa random brave
	if level_goal_mode:
		if current_level <= 1:
			color_pool_colors = Global.get_spectrum_colors(colors_wanted_count) # prvi level je original ... vsi naslednji imajo random gradient
		else:
			color_pool_colors = Global.get_random_gradient_colors(colors_wanted_count)
	# ostale imajo samo original temo ali custom temo
	else:
		if Profiles.use_default_color_theme:
			color_pool_colors = Global.get_spectrum_colors(colors_wanted_count) # prvi level je original ... vsi naslednji imajo random gradient
		else:
			var color_split_offset: float = 1.0 / colors_wanted_count
			for color_count in colors_wanted_count:
				var color = Global.game_color_theme_gradient.interpolate(color_count * color_split_offset) # barva na lokaciji v spektrumu
				color_pool_colors.append(color)		


func on_stray_die(stray_out: KinematicBody2D):
	
	var stray_out_color = stray_out.stray_color
	all_stray_colors.erase(stray_out_color)
	
	# če je dosežen cilj levela apgrejdam level, če prikažem stage indikator in ga zbrišem iz barv
	if level_goal_mode:
		Global.hud.all_color_indicators.pop_front().modulate.a = 1 # remove zato, dani errorja
		if Global.hud.all_color_indicators.empty():
			upgrade_level()
	else: 
		# če ni edina taka barva med trenutnimi strejsi, je ne skrijem
		var same_color_stray_count: int = 0
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.stray_color == stray_out_color:
				same_color_stray_count += 1
				if same_color_stray_count > 1:
					return
		Global.hud.indicate_color_collected(stray_out_color)	
		
		
func _change_strays_in_game_count(strays_count_change: int):
	# šteje nove in uničene
	
	strays_in_game_count += strays_count_change # strays_count_change je lahko - ali +
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	#	printt("_change_strays_in_game_count", strays_in_game_count)
	
	# skupno število spucanih (za hud)
	if strays_count_change < 0:
		strays_cleaned_count += abs(strays_count_change) 
	
	# če je CLEANED upgrejdam level, ali pa kličem GO cleaned
	if strays_in_game_count == 0 and game_on:
		if level_goal_mode:
			upgrade_level(true)
		elif game_data["game"] == Profiles.Games.THE_DUEL:
			respawn_strays_count_range = [20,60]
			respawn_strays(true)
		else:
			game_over(GameoverReason.CLEANED)						
	
		
# SIGNALI --------------------------------------------------------------------------------------------	
	

func _on_RespawnTimer_timeout() -> void:
	respawn_strays()
	respawn_timer.stop()
	respawn_timer.wait_time = respawn_pause_time
	respawn_timer.start()


func _on_tilemap_completed(stray_random_positions: Array, stray_positions: Array, stray_wall_positions: Array, no_stray_positions: Array, player_positions: Array) -> void:
	
	# stray spawn pozicije
	random_spawn_positions = stray_random_positions # celice tal pred procesiranjem tilemapa
	required_spawn_positions = stray_positions # ima tudi wall_spawn_positions
	wall_spawn_positions = stray_wall_positions
	
	# strays spawn count ... najprej spawna "required", potem "random"
	# če samo "required", je stray_count = "required", če tudi "random", stray_count kot je v settingsih
	if not required_spawn_positions.empty() and no_stray_positions.empty(): 
		create_strays_count = required_spawn_positions.size()
	# preventam preveč straysov (več kot je možnih pozicij)
	if create_strays_count > random_spawn_positions.size() + required_spawn_positions.size():
		create_strays_count = random_spawn_positions.size()/2 + required_spawn_positions.size()
	
	# player pozicije
	player_start_positions = player_positions
	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range) + 1
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
