extends Node
class_name GameManager


signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var level_upgrade_in_progress: bool = false # ustavim klicanje naslednjih levelov

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var start_players_count: int
var current_players_in_game: Array # nabira se v FP

# strays
var strays_shown_on_start: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int = 0 # za statistiko na hudu
var all_strays_died_alowed: bool = false # za omejevanje signala iz FP ... kdaj lahko reagira na 0 straysov v igri
var all_stray_colors: Array # barve na štartnem spawnu (iste kot v spektrumu)
var available_respawn_positions: Array # pozicije na voljo, ki se apdejtajo na vsak stray in player spawn ali usmrtitev 
var dont_turn_to_wall_positions: Array # za zaščito, da wall stray ne postane wall (ob robu igre recimo)
var show_position_indicators: bool = false # na začetku jih ne rabim gledat
var show_position_indicators_limit: int = 6
var first_respawn_time: float = 5

# tilemap data
var cell_size_x: int # napolne se na koncu setanju tilemapa
var random_spawn_positions: Array
var required_spawn_positions: Array # vključuje tudi wall_spawn_positions
var wall_spawn_positions: Array
var forbidden_stray_positions: Array

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var start_strays_spawn_count: int = game_settings["strays_start_count"] # število se lahko popravi iz tilempa signala
onready var spawn_white_stray_part: float = game_settings["spawn_white_stray_part"]
onready var respawn_wait_time: float # = game_data["respawn_wait_time"] ... ker je pogoj, moram napolnit na ready
onready var respawn_strays_count: int #  = game_data["respawn_strays_count"] ... ker je pogoj, moram napolnit na ready
onready var StrayPixel: PackedScene = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel: PackedScene = preload("res://game/pixel/player.tscn")
onready var respawn_timer: Timer = $"../RespawnTimer"


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no2"):
		get_tree().call_group(Global.group_strays, "die_to_wall")
	if Input.is_action_pressed("no1"):
		upgrade_level("cleaned")
	if Input.is_action_just_pressed("l"):
		for player in current_players_in_game:
			printt("player positions", player.global_position)
				
	if Input.is_action_just_pressed("h"):
		if game_data["game"] == Profiles.Games.SWEEPER:
			Global.current_tilemap.get_node("SolutionLine").visible = not Global.current_tilemap.get_node("SolutionLine").visible
		
	
func _ready() -> void:

	Global.game_manager = self
	randomize()
	
	# sweeper level settings
	if game_data["game"] == Profiles.Games.SWEEPER:
		var current_level_settings: Dictionary
		current_level_settings = Profiles.sweeper_level_setting[game_data["level"]]
		for setting in current_level_settings:
			game_data[setting] = current_level_settings[setting]

	if game_data.has("respawn_strays_count"):
		respawn_wait_time = game_data["respawn_wait_time"]
		respawn_strays_count = game_data["respawn_strays_count"]	


func _process(delta: float) -> void:
	# all strays and players
	current_players_in_game = get_tree().get_nodes_in_group(Global.group_players)

	# če sem v fazi, ko lahko preverjam cleaned (po spawnu)
	if all_strays_died_alowed:
		# če ni nobene stene, me zanimajo samo prazni strajsi
		if strays_in_game_count == 0:
			all_strays_died_alowed = false
			emit_signal("all_strays_died")
	
	# skos apdejtam pozicije na voljo
	available_respawn_positions = Global.current_tilemap.floor_global_positions.duplicate() # vsa tla
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if available_respawn_positions.has(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
			available_respawn_positions.erase(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2))
	for player in current_players_in_game:
		if available_respawn_positions.has(player.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
			available_respawn_positions.erase(player.global_position - Vector2(cell_size_x/2, cell_size_x/2))

	# position indicators
	if game_on:
		if Global.strays_on_screen.size() < show_position_indicators_limit:
			show_position_indicators = true
		else:
			show_position_indicators = false
	else:
		show_position_indicators = false


# GAME SETUP --------------------------------------------------------------------------------------
	
	
func set_tilemap():
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	
	var tilemap_to_load_path: String
	if game_data["game"] == Profiles.Games.SWEEPER: # path vlečem iz level settings
		tilemap_to_load_path = game_data["tilemap_path"]
	else:
		tilemap_to_load_path = game_data["tilemap_path"]
		
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
	
	Global.game_camera.position = Global.current_tilemap.camera_position_node.global_position	
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	Global.game_camera.set_camera_limits()

	if game_settings["zoom_to_level_size"]:
		Global.game_camera.set_zoom_to_level_size()
	
	
func set_game(): 
	
	# kliče main.gd po prikazom igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	if game_settings["show_game_instructions"]:
		yield(Global.hud, "players_ready")
	
	# animacije plejerja in straysov in zooma	
	var signaling_player: KinematicBody2D
	for player in current_players_in_game:
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	yield(get_tree().create_timer(0.3), "timeout")
	set_strays()
	yield(get_tree().create_timer(0.7), "timeout")
	Global.hud.slide_in()
	if game_settings["start_countdown"]:
		yield(get_tree().create_timer(0.2), "timeout")
		Global.start_countdown.start_countdown() # GM yielda za njegov signal
		yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	else:
		yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
	
	start_game()
	Global.current_tilemap.background_room.hide()
	

func set_new_level(): 
	
	# in level spawn
	if game_data.has("respawn_wait_time_factor"):
		respawn_wait_time *= game_data["respawn_wait_time_factor"]
		respawn_strays_count = game_data["respawn_strays_count_grow"]
	# level goal count
	var higher_player_score: int = 0
	for player in current_players_in_game:
		if player.player_stats["player_points"] > higher_player_score:
			higher_player_score = player.player_stats["player_points"]
	if game_data.has("level_goal_count_grow"):
		game_data["level_goal_count"] += higher_player_score + game_data["level_goal_count_grow"]
	# level start spawn
	start_strays_spawn_count += game_data["strays_start_count_grow"]
	if game_data["level"] == 2: # 2. level je prvi level ko se štarta zares
		start_strays_spawn_count = game_settings["strays_start_count"]
	# število spawnanih belih
	if game_data.has("spawn_white_stray_part_factor"):
		spawn_white_stray_part += game_data["spawn_white_stray_part_factor"]
	#	spawn_white_stray_part =  clamp(spawn_white_stray_part, 0, 0.5) # največ 50 posto, da jih možno


# GAME LOOP --------------------------------------------------------------------------------------


func start_game():
	
	Global.hud.game_timer.start_timer()
	Global.sound_manager.currently_playing_track_index = game_settings["game_track_index"]
	Global.sound_manager.play_music("game_music")
	
	for player in current_players_in_game:
		if not game_settings ["zoom_to_level_size"]:
			Global.game_camera.camera_target = player
		player.set_physics_process(true)
		
	game_on = true
	
	# start respawning
	if game_data.has("respawn_strays_count"):
		if game_data["respawn_strays_count"] > 0 and not game_data["respawn_wait_time"] == 0:
			respawn_timer.start(first_respawn_time)


func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	# cleaner in handler respawn na cleaned namesto GO 
	if game_settings["new_strays_on_cleaned"]: # uniq kombinacija respawn on cleaned
		if gameover_reason == GameoverReason.CLEANED:
			all_strays_died_alowed = true
			yield(self, "all_strays_died")
			var signaling_player: KinematicBody2D
			for player in current_players_in_game:
				player.on_screen_cleaned()
				player.set_physics_process(false)
				signaling_player = player
			#yield(signaling_player, "rewarded_on_cleaned")
			Global.hud.empty_color_indicators()
			game_on = true
			set_strays()
			get_tree().call_group(Global.group_players, "set_physics_process", true)
	else:
		Global.hud.game_timer.stop_timer()
		if gameover_reason == GameoverReason.CLEANED:
			all_strays_died_alowed = true
			yield(self, "all_strays_died")
			var signaling_player: KinematicBody2D
			for player in current_players_in_game:
				player.on_screen_cleaned()
				signaling_player = player
			yield(signaling_player, "rewarded_on_cleaned")
		else: # samo pavza
			yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
			
		get_tree().call_group(Global.group_players, "set_physics_process", false)
		stop_game_elements()
		Global.current_tilemap.background_room.show()
		Global.gameover_gui.open_gameover(gameover_reason)


func stop_game_elements():
	# včasih nujno
	
	Global.hud.popups_out()
	for player in current_players_in_game:
		player.end_move()
		player.stop_sound("teleport")
		player.stop_sound("heartbeat")

			
# PLAYERS --------------------------------------------------------------------------------------------	
	
		
func set_players():
	
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
		
		
# STRAYS --------------------------------------------------------------------------------------------	


func set_strays():
	
	if random_spawn_positions.empty() and required_spawn_positions.empty(): 
		print("no positions on set_strays()")
		return
	if available_respawn_positions.empty():
		print("no respawn positions on set_strays()")
		return
		
	strays_shown_on_start.clear() # resetiram
	
	spawn_strays(start_strays_spawn_count) # var je za tutorial
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int = 0
	while strays_shown_on_start.size() < start_strays_spawn_count:
		show_strays_loop += 1 # zazih
		show_strays_on_start(show_strays_loop)


func spawn_strays(strays_to_spawn_count: int):
	# on start, cleaned in level upgrade
	
	var current_level: int
	if game_data.has("level"): 
		current_level = game_data["level"]
	else:
		current_level = 0
	
	# colors
	var all_colors_available: Array
	if game_data.has("level") and not game_data["game"] == Profiles.Games.SWEEPER: # multi level game
		if current_level <= 1:
			all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
		else:
			all_colors_available = Global.get_random_gradient_colors(strays_to_spawn_count)
	else:
		if Profiles.use_custom_color_theme:
			var color_split_offset: float = 1.0 / strays_to_spawn_count
			for stray_count in strays_to_spawn_count:
				var color = Global.game_color_theme_gradient.interpolate(stray_count * color_split_offset) # barva na lokaciji v spektrumu
				all_colors_available.append(color)	
		else:
			all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
	
	all_stray_colors = [] # vsakič resetiramo ... za color indikatorje
	
	# positions
	var available_required_spawn_positions = required_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions # .duplicate() # dupliciram, da ostanejo "shranjene"
	
	# spawn
	for stray_index in strays_to_spawn_count:
		
		var current_color: Color = all_colors_available[stray_index] # barva na lokaciji v spektrumu
		
		# spawn positions
		var current_spawn_positions: Array
		if current_level <= 1 or game_data["game"] == Profiles.Games.SWEEPER:
			 # najprej obvezne pozicije
			if not available_required_spawn_positions.empty():
				# najprej bele pixle
				if not wall_spawn_positions.empty():
					current_spawn_positions = wall_spawn_positions
				else: # potem ostale 
					current_spawn_positions = available_required_spawn_positions
			# random pozicije, ko so obvezne spraznjene
			elif not available_random_spawn_positions.empty():
				current_spawn_positions = available_random_spawn_positions
		else: # leveli večji od prvega ... random respawn
			current_spawn_positions = available_respawn_positions
			
		# žrebanje random position
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_cell_position: Vector2 = current_spawn_positions[selected_cell_index]
		var selected_stray_position: Vector2 = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)
		
		# je pozicija zasedena
		var selected_stray_position_is_free: bool = true
		for player in current_players_in_game:
			if player.global_position == selected_stray_position:
				selected_stray_position_is_free = false
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.global_position == selected_stray_position:
				selected_stray_position_is_free = false
		# če je prazna
		if selected_stray_position_is_free:
			# spawn
			var new_stray_pixel = StrayPixel.instance()
			new_stray_pixel.name = "S%s" % str(stray_index)
			new_stray_pixel.stray_color = current_color
			new_stray_pixel.global_position = selected_stray_position # dodana adaptacija zaradi središča pixla
			new_stray_pixel.z_index = 2 # višje od plejerja
			Global.node_creation_parent.call_deferred("add_child", new_stray_pixel)
			
			# post spawn
			all_stray_colors.append(current_color) # dodam barvo
			if wall_spawn_positions.has(selected_cell_position): 
				new_stray_pixel.current_state = new_stray_pixel.States.WALL
			else: # barvni
				var spawn_white_start_limit: int = strays_to_spawn_count - round(strays_to_spawn_count * spawn_white_stray_part)
				if stray_index > spawn_white_start_limit:
					new_stray_pixel.current_state = new_stray_pixel.States.WALL
		
			wall_spawn_positions.erase(selected_cell_position)
			available_required_spawn_positions.erase(selected_cell_position)
			available_random_spawn_positions.erase(selected_cell_position)
		
		else: # če je zasedena se ne spawna, moram pozicijo vseeno brisat, če ne se spawnajo vsi na to pozicijo
			strays_to_spawn_count -= 1
			wall_spawn_positions.erase(selected_cell_position)
			available_required_spawn_positions.erase(selected_cell_position)
			available_random_spawn_positions.erase(selected_cell_position)
	
	# varovalka, če se noben ne spawna, grem še enkrat čez cel postopek ... možno samo ko naj se spawna 1
	if strays_to_spawn_count == 0:
		printt("Real spawn count = ", strays_to_spawn_count, ". Naredim še en krog spawnanja.")
		set_strays()
		return
		
	Global.hud.spawn_color_indicators(all_stray_colors) # barve pokažem v hudu		
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba


func show_strays_on_start(show_strays_loop: int):

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
	

func respawn_strays():
	# only in game
	
	for stray_index in respawn_strays_count:
	
		if available_respawn_positions.empty():
			return
			
		# odstranim pozicije plejerjev ... zazih
		for player in current_players_in_game:
			if available_respawn_positions.has(player.global_position):
				available_respawn_positions.erase(player.global_position)
				
		# get color
		var spawned_stray_color: Color
		if game_settings["random_stray_to_white"]:
			spawned_stray_color = turn_random_strays_to_white()
			yield(get_tree().create_timer(1), "timeout") # da se ne spawna, ko še ni wall
			
		# random color
		else:
			var random_color_index: int = randi() % int(all_stray_colors.size())		
			spawned_stray_color = all_stray_colors[random_color_index]
		
		# random position
		var random_range = available_respawn_positions.size()
		var selected_position_index: int = randi() % int(random_range)		
		var selected_position = available_respawn_positions[selected_position_index]

		# spawn stray
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(strays_in_game_count)
		new_stray_pixel.stray_color = spawned_stray_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.call_deferred("add_child", new_stray_pixel)
		new_stray_pixel.call_deferred("show_stray")
		
		Global.hud.spawn_color_indicators([spawned_stray_color]) # barve pokažem v hudu		
		self.strays_in_game_count = 1 # setget sprememba	
	
	
func clean_strays_in_game():
	
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_index: int = get_tree().get_nodes_in_group(Global.group_strays).find(stray)
		stray.die(stray_index, get_tree().get_nodes_in_group(Global.group_strays).size())
	
	all_strays_died_alowed = true


func turn_random_strays_to_white():
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty():
		return
		
	var wall_strays_alive: Array 
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_to_tile_position: Vector2 = stray.global_position + Vector2(cell_size_x/2, cell_size_x/2)
		if stray.current_state == stray.States.WALL and not dont_turn_to_wall_positions.has(stray_to_tile_position):
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

	
func stop_stray_spawning():
	random_spawn_positions.clear()


# LEVELS --------------------------------------------------------------------------------------------	


func upgrade_level(level_upgrade_reason: String): # cleaner
	
	if level_upgrade_in_progress:
		return
	level_upgrade_in_progress = true	
	randomize()
	
	game_data["level"] += 1 # številka novega levela 
	respawn_timer.stop()
	Global.hud.level_up_popup_inout(game_data["level"])
	#Global.hud.level_up_popup_in(game_data["level"])
	
	for player in current_players_in_game:
		player.end_move()
		if level_upgrade_reason == "cleaned":
			player.on_screen_cleaned()
			
	#get_tree().call_group(Global.group_players, "set_physics_process", false)
	Global.hud.empty_color_indicators()
	set_new_level() 
	#if not get_tree().get_nodes_in_group(Global.group_strays).empty():
	#	clean_strays_in_game() # puca vse v igri
	#	yield(self, "all_strays_died") # ko so vsi iz igre grem naprej
	
	# new level
	#Global.hud.level_up_popup_out()
	set_strays() 
	#get_tree().call_group(Global.group_players, "set_physics_process", true)
	
	level_upgrade_in_progress = false
	
	if game_data.has("respawn_strays_count"):
		if game_data["respawn_strays_count"] > 0 and not game_data["respawn_wait_time"] == 0:
			respawn_timer.start(first_respawn_time)
	
	
func _change_strays_in_game_count(strays_count_change: int):
	# šteje nove in uničene
	
	strays_in_game_count += strays_count_change # strays_count_change je lahko - ali +
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	# skupno število spucanih (za hud)
	if strays_count_change < 0:
		strays_cleaned_count += abs(strays_count_change) 
	
	# če je CLEANED
	if strays_in_game_count == 0:
		if game_data["game"] == Profiles.Games.ERASER or game_data["game"] == Profiles.Games.HANDLER or game_data["game"] == Profiles.Games.DEFENDER:
			upgrade_level("cleaned")
		else:
			game_over(GameoverReason.CLEANED)						
	# če ni CLEANED in je HANDLER
	elif game_data["game"] == Profiles.Games.HANDLER:
		# preverim, če so ostali samo beli ... game over
		var wall_strays_count: int = 0
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.WALL:
				wall_strays_count += 1
		if wall_strays_count == strays_in_game_count:
			game_over(GameoverReason.TIME)		

	
# SIGNALI --------------------------------------------------------------------------------------------	


func _on_RespawnTimer_timeout() -> void:
	respawn_strays()
	respawn_timer.stop()
	respawn_timer.wait_time = respawn_wait_time
	respawn_timer.start()


func _on_tilemap_completed(stray_random_positions: Array, stray_positions: Array, stray_wall_positions: Array, no_stray_positions: Array, player_positions: Array) -> void:
	
	# stray spawn pozicije
	random_spawn_positions = stray_random_positions # celice tal pred procesiranjem tilemapa
	required_spawn_positions = stray_positions # ima tudi wall_spawn_positions
	wall_spawn_positions = stray_wall_positions
	forbidden_stray_positions = no_stray_positions
	# strays spawn count 
	# če so samo "required", je število straysov enako "required"
	# če so "required" in "random", je število straysov kot je določeno v settingsih, najprej spawna "required", potem "random"
	# najprej spawna "required", potem še random
	if not required_spawn_positions.empty() and forbidden_stray_positions.empty():
		start_strays_spawn_count = required_spawn_positions.size()
	# preventam preveč straysov (več kot je možnih pozicij)
	if start_strays_spawn_count > random_spawn_positions.size() + required_spawn_positions.size():
		start_strays_spawn_count = random_spawn_positions.size()/2 + required_spawn_positions.size()
	
	# player pozicije
	player_start_positions = player_positions
	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range) + 1
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	# all floor po procesiranju
	available_respawn_positions = Global.current_tilemap.floor_global_positions.duplicate() # vsa tla
	dont_turn_to_wall_positions = forbidden_stray_positions
