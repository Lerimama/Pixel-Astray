extends GameManager

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
	
	
func _ready() -> void:

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_cleaning.tscn")
	PlayerPixel = preload("res://game/pixel/player_cleaning.tscn")
	
	randomize()
	
	# set_new_level on start
	if game_settings["eternal_mode"]:
		game_data["level"] = 1 # zmeraj začnem s prvim levelom
		respawn_wait_time = game_settings["respawn_wait_time"]
		respawn_strays_count = game_settings["respawn_strays_count"]
		level_points_limit = game_data["level_points_limit"]
	
	if game_data["game"] == Profiles.Games.ENIGMA:
		var current_level_settings: Dictionary
		current_level_settings = Profiles.enigma_level_setting[game_data["level"]]
		for setting in current_level_settings:
			game_data[setting] = current_level_settings[setting]
		

func _process(delta: float) -> void:
	# namen: respawnanje straysov ... za eternal in upoštevanje wall straysov zaznavanju cleaned

	universal_time += delta
	
	var wall_strays_count: int
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
		if Global.strays_on_screen.size() <= game_settings["show_position_indicators_stray_count"] and game_settings["position_indicators_on"]:
			show_position_indicators = true
		else:
			show_position_indicators = false
	else:
		show_position_indicators = false
	
	
func start_game():
	# namen: turn to wall respawn štartrespawnanje straysov ... za eternal
	
	Global.hud.game_timer.start_timer()
	Global.sound_manager.play_music("game_music")
		
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.set_physics_process(true)
		
	game_on = true
	
	# start respawning
	if game_settings["respawn_mode"]:
#	if game_settings["eternal_mode"]:
		respawn_timer.start(first_respawn_time)


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
	else: #	ERASER_S, ERASER_M, ERASER_L, CLEANER_L, THE_DUEL, ENIGMA	
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
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		all_stray_colors.append(current_color)
		current_spawn_positions.remove(selected_cell_index) # odstranim pozicijo iz nabora za start spawn
		
		new_stray_pixel.show_stray()
			
	Global.hud.spawn_color_indicators(all_stray_colors) # barve pokažem v hudu		
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba


func respawn_stray(): # za eternal

	# odstranim pozicije plejerjev ... zazih
	for player in get_tree().get_nodes_in_group(Global.group_players):
		if available_respawn_positions.has(player.global_position):
			available_respawn_positions.erase(player.global_position)
	
	for n in respawn_strays_count:
	
		if available_respawn_positions.empty():
			return
		
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
	var all_strays_alive: Array # = get_tree().get_nodes_in_group(Global.group_strays)
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if not stray.current_state == stray.States.WALL:
			all_strays_alive.append(stray)
	
	#	var all_strays_alive: Array = get_tree().get_nodes_in_group(Global.group_strays)
	for stray in all_strays_alive:
		var stray_index: int = all_strays_alive.find(stray)# + 1
		stray.die(stray_index, all_strays_alive.size())


func turn_random_strays_to_wall(): # za eternal
	
	var wall_strays_alive: Array 
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		var stray_to_tile_position: Vector2 = stray.global_position + Vector2(cell_size_x/2, cell_size_x/2)
		if stray.current_state == stray.States.WALL and not dont_turn_to_wall_positions.has(stray_to_tile_position):
			wall_strays_alive.append(stray)
		else:
			printt ("turn", stray.global_position)
#		if dont_turn_to_wall_positions.has(stray_to_tile_position):
#	printt ("kva", dont_turn_to_wall_positions)
	printt ("kva", dont_turn_to_wall_positions.size(), wall_strays_alive.size())
	
	var strays_not_walls_count: int = get_tree().get_nodes_in_group(Global.group_strays).size() - wall_strays_alive.size()
				
	var random_stray_index: int = randi() % int(strays_not_walls_count)
	
	if get_tree().get_nodes_in_group(Global.group_strays).size() > random_stray_index: # error prevent
		var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
		random_stray.die_to_wall()
		return random_stray.stray_color
	else: # error
		print("Error - no color to turn to wall")
		return Color.white
	
	
# LEVELS --------------------------------------------------------------------------------------------	


func upgrade_level(): # za eternal
	
	if level_upgrade_in_progress:
		return
	
	randomize()
	
	level_upgrade_in_progress = true	
	
	game_data["level"] += 1 # številka novega levela 
	respawn_timer.stop()
	
	Global.hud.level_up_popup_in(game_data["level"])
	
	# set for new level
	set_new_level() 
	Global.hud.empty_color_indicators()
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	clean_strays_in_game() # puca vse v igri
	
	# strays cleaned
	all_strays_died_alowed = true
	yield(self, "all_strays_died") # ko so vsi iz igre grem naprej
	
	#	var curr_time = universal_time
	#	printt("upgrade start", curr_time)
	
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.all_cleaned()
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen	
	
	# start new level
	Global.hud.level_up_popup_out()
	level_upgrade_in_progress = false
	set_strays() 
	get_tree().call_group(Global.group_players, "set_physics_process", true)
	
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


func _change_strays_in_game_count(strays_count_change: int):
	# namen: vpelje upgrade level
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if game_settings["eternal_mode"]:
		var wall_strays_count: int
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.WALL:
				wall_strays_count += 1
		if strays_in_game_count == wall_strays_count or strays_in_game_count == 0: 
			upgrade_level()
	else:
		if strays_in_game_count == 0: # tutorial sam ve kdaj je gameover, eternal pa nima cleaned GO možnosti 
			game_over(GameoverReason.CLEANED)	


# SIGNALI --------------------------------------------------------------------------------------------	


func _on_RespawnTimer_timeout() -> void: # za eternal
	
	respawn_stray()
	respawn_timer.stop()
	respawn_timer.wait_time = respawn_wait_time
	respawn_timer.start()
