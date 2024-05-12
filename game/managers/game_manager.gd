extends Node
class_name GameManager


signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var show_position_indicators: bool = false # na začetku jih ne rabim gledat

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var start_players_count: int

# strays
var strays_shown: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int = 0 # za statistiko na hudu
var all_strays_died_alowed: bool = false # za omejevanje signala iz FP ... kdaj lahko reagira na 0 straysov v igri
var all_stray_colors: Array # barve na štartnem spawnu (site kot v spektrumu)
var available_respawn_positions: Array # pozicije na voljo, ki se apdejtajo na vsak stray in player spawn ali usmrtitev 
var dont_turn_to_wall_positions: Array # za zaščito, da wall stray ne postane wall (ob robu igre recimo)
var show_position_indicators_stray_count: int = 5

# tilemap data
var cell_size_x: int # napolne se na koncu setanju tilemapa
var random_spawn_positions: Array
var required_spawn_positions: Array
var wall_stray_positions: Array

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var start_strays_spawn_count: int = game_settings["strays_start_count"] # število se lahko popravi iz tilempa signala
onready var StrayPixel: PackedScene = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel: PackedScene = preload("res://game/pixel/player.tscn")

# neu
var level_upgrade_in_progress: bool = false # ustavim klicanje naslednjih levelov
var current_enigma_name: String = "Null"# ime levele ... lahko številka
var first_respawn_time: float = 5
var level_points_limit: int

onready var respawn_timer: Timer = $"../RespawnTimer"
onready var respawn_wait_time: float = game_settings["respawn_wait_time"]
onready var respawn_strays_count: int = game_settings["respawn_strays_count"]

# debug
var universal_time: float = 0 # za merjenje trajanja raznih stvari


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no2"):
		get_tree().call_group(Global.group_strays, "die_to_wall")
	if Input.is_action_pressed("no1"):
		upgrade_level()
	if Input.is_action_just_pressed("l"):
		upgrade_level()	
	
	
func _ready() -> void:

	Global.game_manager = self
	
	randomize()
	
	# set_new_level on start
	if game_settings["eternal_mode"]:
		game_data["level"] = 1 # zmeraj začnem s prvim levelom
		respawn_wait_time = game_settings["respawn_wait_time"]
		level_points_limit = game_data["level_points_limit"]
	
	if game_data["game"] == Profiles.Games.ENIGMA:
		var current_level_settings: Dictionary
		current_level_settings = Profiles.enigma_level_setting[game_data["level"]]
		for setting in current_level_settings:
			game_data[setting] = current_level_settings[setting]
		

func _process(delta: float) -> void:
	# namen: respawnanje straysov ... za eternal in upoštevanje wall straysov zaznavanju cleaned

	universal_time += delta
	
	var wall_strays_count: int = 0
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if stray.current_state == stray.States.WALL:
			wall_strays_count += 1
	# če sem v fazi, ko lahko preverjam cleaned (po spawnu)
	if all_strays_died_alowed:
		# če ni nobene stene, me zanimajo samo prazni strajsi
		if strays_in_game_count == 0:
			all_strays_died_alowed = false
			emit_signal("all_strays_died")
		# če so v igri samo še straysi, ki so stene
		elif strays_in_game_count == wall_strays_count:
			all_strays_died_alowed = false
			emit_signal("all_strays_died")
	
	# position indicators
	if game_on:
		if Global.strays_on_screen.size() <= show_position_indicators_stray_count and game_settings["position_indicators_on"]:
			show_position_indicators = true
		else:
			show_position_indicators = false
	else:
		show_position_indicators = false


func set_game(): 
	
	# kliče main.gd pred prikazom igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.animation_player.play("lose_white_on_start")
#			player.animation_player.play_backwards("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	set_strays()
	yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda	
	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	start_game()
	yield(get_tree().create_timer(Global.hud.hud_in_out_time), "timeout") # da se res prizumira, če ni game start countdown
	Global.current_tilemap.background_room.hide()
	
	
func start_game():
	# namen: turn to wall respawn štartrespawnanje straysov ... za eternal

	
	Global.hud.game_timer.start_timer()
	Global.sound_manager.play_music("game_music")
	
	for player in get_tree().get_nodes_in_group(Global.group_players):
		if not game_settings ["zoom_to_level_size"]:
			Global.game_camera.camera_target = player
		player.set_physics_process(true)
		
	game_on = true
	
	# start respawning
	if game_settings["respawn_mode"] and not game_settings["respawn_wait_time"] == 0:
		respawn_timer.start(first_respawn_time)


func game_over(gameover_reason: int):
	
	# respawn na cleaned namesto GO
	if gameover_reason == GameoverReason.CLEANED:
		if game_settings["respawn_mode"] and game_settings["respawn_wait_time"] == 0: # respawn on cleaned
			all_strays_died_alowed = true
			yield(self, "all_strays_died")
			var signaling_player: KinematicBody2D
			for player in get_tree().get_nodes_in_group(Global.group_players):
				player.screen_cleaned()
				player.set_physics_process(false)
				signaling_player = player # da se zgodi na obeh plejerjih istočasno
			respawn_strays()
			get_tree().call_group(Global.group_players, "set_physics_process", true)
			return
			
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if gameover_reason == GameoverReason.CLEANED:
		all_strays_died_alowed = true
		yield(self, "all_strays_died")
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.screen_cleaned()
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
		yield(signaling_player, "rewarded_on_cleaned") # počakam, da je nagrajen
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	yield(get_tree().create_timer(1), "timeout") # za dojet
	stop_game_elements()
	Global.current_tilemap.background_room.show()
	Global.gameover_menu.open_gameover(gameover_reason)


func stop_game_elements():
	
	# včasih nujno
	Global.hud.popups_out()
	for player in get_tree().get_nodes_in_group(Global.group_players):
		#		while not player.cocked_ghosts.empty():
		#			var ghost = player.cocked_ghosts.pop_back()
		#			ghost.queue_free()
		player.stop_sound("teleport")
		player.stop_sound("heartbeat")
#	for stray in get_tree().get_nodes_in_group(Global.group_strays):
#		stray.current_state = stray.States.STATIC


# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	# namen: load enigma level tilemap
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	
	var tilemap_to_load_path: String
	if game_data["game"] == Profiles.Games.ENIGMA: # path vlečem iz level settings
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
			
		
func set_strays():
	
	spawn_strays(start_strays_spawn_count)
	
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int = 0
	while strays_shown.size() < start_strays_spawn_count:
		show_strays_loop += 1 # zazih
		show_strays_on_start(show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout")
	
	strays_shown.clear() # resetiram, da je mogoč in-game spawn


# STRAYS --------------------------------------------------------------------------------------------	


func spawn_strays(strays_to_spawn_count: int):
	# namen: gradient iz naključnih barv iz spektruma	
	
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
	var current_level: int
	if game_data.has("level"): 
		current_level = game_data["level"]
	else:
		current_level = 0
	
	# colors
	var all_colors_available: Array
	if game_settings["eternal_mode"]: # CLEANER_S, CLEANER_M, SCROLLER
		if current_level <= 1:
			all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
		else:
			all_colors_available = Global.get_random_gradient_colors(strays_to_spawn_count)
	else: #	CLASSIC_S, CLASSIC_M, CLASSIC_L, CLEANER_L, THE_DUEL, ENIGMA	
		if Profiles.use_custom_color_theme:
			var color_split_offset: float = 1.0 / strays_to_spawn_count
			for stray_count in strays_to_spawn_count:
				var color = Global.game_color_theme_gradient.interpolate(stray_count * color_split_offset) # barva na lokaciji v spektrumu
				all_colors_available.append(color)	
		else:
			all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
	all_stray_colors = [] # reset ... za color indikatorje
	
	# positions
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	# spawn
	for stray_index in strays_to_spawn_count:
		var current_color: Color = all_colors_available[stray_index] # barva na lokaciji v spektrumu
		# available spawn positions
		var current_spawn_positions: Array
		if current_level <= 1 or game_data["game"] == Profiles.Games.ENIGMA: # vse igre razen enigme ineterenal imajo level 0
			if not available_required_spawn_positions.empty(): # najprej obvezne
				current_spawn_positions = available_required_spawn_positions
			elif available_required_spawn_positions.empty(): # potem random
				current_spawn_positions = available_random_spawn_positions
			elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
				return
		else: # spawnanje na vse available za respawn
			if not available_respawn_positions.empty():
				current_spawn_positions = available_respawn_positions
			else:
				print ("No available spawn positions")
				return
		
		# odstranim pozicije plejerjev ... zazih
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if current_spawn_positions.has(player.global_position):
				current_spawn_positions.erase(player.global_position)

		# žrebanje random position
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position: Vector2 = current_spawn_positions[selected_cell_index]
			
		# spawn
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		# wal stray
		var random_from_100: int = randi() % 100
		if random_from_100 < game_settings["stray_wall_spawn_possibilty"]:
			new_stray_pixel.current_state = new_stray_pixel.States.WALL
			new_stray_pixel.stray_color = Global.color_wall_pixel
		else:
			new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		all_stray_colors.append(current_color)
		current_spawn_positions.remove(selected_cell_index) # odstranim pozicijo iz nabora za start spawn
	
			
		new_stray_pixel.show_stray()
			
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
			strays_to_show_count = strays_in_game_count - strays_shown.size()
	
	# stray fade-in
	var spawned_strays = get_tree().get_nodes_in_group(Global.group_strays)
	var loop_count = 0
	for stray in spawned_strays:
		if not strays_shown.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			stray.show_stray()
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break
	

func respawn_strays(): # za eternal

	for stray_index in respawn_strays_count:
	
		if available_respawn_positions.empty():
			return
			
		# odstranim pozicije plejerjev ... zazih
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if available_respawn_positions.has(player.global_position):
				available_respawn_positions.erase(player.global_position)
				
		# get color
		var spawned_stray_color: Color
		# stray to wall color
		if game_settings["turn_stray_to_wall"] and not get_tree().get_nodes_in_group(Global.group_strays).empty():
			spawned_stray_color = turn_random_strays_to_wall()
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
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		new_stray_pixel.show_stray()

		self.strays_in_game_count = 1 # setget sprememba	
	
	
func clean_strays_in_game(): # za eternal
	
	# vsi straysi, ki niso wall
	var all_strays_alive: Array = get_tree().get_nodes_in_group(Global.group_strays)
	#	for stray in get_tree().get_nodes_in_group(Global.group_strays):
	#		if not stray.current_state == stray.States.WALL:
	#			all_strays_alive.append(stray)
	
	for stray in all_strays_alive:
		var stray_index: int = all_strays_alive.find(stray)# + 1
		stray.die(stray_index, all_strays_alive.size())
	
	all_strays_died_alowed = true


func turn_random_strays_to_wall(): # za eternal
	
	var wall_strays_alive: Array 
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_to_tile_position: Vector2 = stray.global_position + Vector2(cell_size_x/2, cell_size_x/2)
		if stray.current_state == stray.States.WALL and not dont_turn_to_wall_positions.has(stray_to_tile_position):
			wall_strays_alive.append(stray)
		else:
			pass
	var strays_not_walls_count: int = get_tree().get_nodes_in_group(Global.group_strays).size() - wall_strays_alive.size()
				
	var random_stray_index: int = randi() % int(strays_not_walls_count)
	
	if get_tree().get_nodes_in_group(Global.group_strays).size() > random_stray_index: # error prevent
		var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
		random_stray.die_to_wall()
		return random_stray.stray_color
	else: # error
		print("Error - no color to turn to wall")
		return Color.white
	

func _change_strays_in_game_count(strays_count_change: int):
	# namen: vpelje upgrade level
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if game_settings["eternal_mode"]:
		var wall_strays_count: int = 0
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.WALL:
				wall_strays_count += 1
		if strays_in_game_count == wall_strays_count or strays_in_game_count == 0: 
			upgrade_level()
	else:
		if strays_in_game_count == 0: 
			game_over(GameoverReason.CLEANED)	

	
func stop_stray_spawning():
	random_spawn_positions.clear()


# LEVELS --------------------------------------------------------------------------------------------	


func upgrade_level(): # za eternal
	
	if level_upgrade_in_progress:
		return
	
	randomize()
	
	level_upgrade_in_progress = true	
	
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.current_state = player.States.IDLE
		while not player.cocked_ghosts.empty():
			var ghost = player.cocked_ghosts.pop_back()
			ghost.queue_free()
			
	game_data["level"] += 1 # številka novega levela 
	respawn_timer.stop()
	
	Global.hud.level_up_popup_in(game_data["level"])
	
	# set for new level
	set_new_level() 
	Global.hud.empty_color_indicators()
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	clean_strays_in_game() # puca vse v igri
	
	# strays cleaned
	yield(self, "all_strays_died") # ko so vsi iz igre grem naprej
	
	#	var curr_time = universal_time
	#	printt("upgrade start", curr_time)
	
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.screen_cleaned()
		#		player.set_physics_process(false)
#		signaling_player = player # da se zgodi na obeh plejerjih istočasno
#	yield(signaling_player, "rewarded_on_cleaned") # počakam, da je nagrajen	
	
	# start new level
	Global.hud.level_up_popup_out()
	level_upgrade_in_progress = false
	set_strays() 
#	get_tree().call_group(Global.group_players, "set_physics_process", true)
	
	if game_settings["respawn_mode"]:
		respawn_timer.start(first_respawn_time)
	

func set_new_level(): 
	# samo za eternal
	
	if game_settings["eternal_mode"]:
		# kateri score je višji
		level_points_limit += level_points_limit + game_data["level_points_limit_grow"]
		respawn_wait_time *= game_data["respawn_wait_time_factor"]
		respawn_strays_count = game_data["respawn_strays_count_grow"]
		# število spawnanih straysov
		start_strays_spawn_count += game_data["level_strays_spawn_count_grow"]
		if game_data["level"] == 2: # 2. level je prvi level ko se štarta zares
			start_strays_spawn_count = game_settings["strays_start_count"]

	
# SIGNALI --------------------------------------------------------------------------------------------	


func _on_RespawnTimer_timeout() -> void: # za eternal
	
	respawn_strays()
	respawn_timer.stop()
	respawn_timer.wait_time = respawn_wait_time
	respawn_timer.start()


func _on_tilemap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array, wall_stray_global_positions: Array) -> void:
	
	# opredelim tipe pozicij
	player_start_positions = player_cells_positions
	random_spawn_positions = random_spawn_floor_positions
	required_spawn_positions = stray_cells_positions
	wall_stray_global_positions = wall_stray_positions
	
	# start strays count setup
	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
		start_strays_spawn_count = required_spawn_positions.size()
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if start_strays_spawn_count > random_spawn_positions.size() + required_spawn_positions.size():
		start_strays_spawn_count = random_spawn_positions.size()/2 + required_spawn_positions.size()

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range) + 1
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
	
	# grab respawn positions
	available_respawn_positions = Global.current_tilemap.floor_global_positions.duplicate()
	dont_turn_to_wall_positions = no_stray_cells_positions
