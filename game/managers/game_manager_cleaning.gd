extends GameManager


#var current_level: int = 1 # za eternal
var level_upgrade_in_progress: bool = false # ustavim klicanje naslednjih levelov
var current_enigma_name: String = "Null"# ime levele ... lahko številka

#var level_conditions: Dictionary
var first_respawn_time: float = 5
var respawn_wait_time: float
var respawn_strays_count: int
var level_points_limit: int

onready var respawn_timer: Timer = $"../RespawnTimer"

# neu
var universal_time: float = 0 # za merjenje trajanja raznih stvari ... debug

func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no2"):
		get_tree().call_group(Global.group_strays, "die_to_wall")
	if Input.is_action_pressed("no1"):
		upgrade_level()
	if Input.is_action_pressed("ui_accept"):
		Global.data_manager.read_solved_status_from_file(game_data)
		print("read")
	if Input.is_action_pressed("t"):
		Global.data_manager.write_solved_status_to_file(game_data)
		print("write")
#		for n in 50:
#			# random stray to wall
#			var random_stray_index: int = randi() % int(strays_in_game_count)
#			var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
#			random_stray.die_to_wall()
	
	
func _ready() -> void:

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_cleaning.tscn")
	PlayerPixel = preload("res://game/pixel/player_cleaning.tscn")
	
	randomize()
	
	# set_level_conditions on start
	if game_settings["eternal_mode"]:
#		var current_level_settings: Dictionary
#		if game_data["game"] == Profiles.Games.ETERNAL:
#			current_level_settings = Profiles.eternal_level_conditions[1]
#		elif game_data["game"] == Profiles.Games.ETERNAL_XL:
#			current_level_settings = Profiles.eternal_level_conditions[2]
#		# prepišem level slovar v game data slovar
#		for key in current_level_settings:
#			game_data[key] = current_level_settings[key]
		# setam level settings
		game_data["level"] = 1 # zmeraj začnem s prvim levelom
		respawn_wait_time = game_data["respawn_wait_time"]
		respawn_strays_count = game_data["respawn_strays_count"]
		level_points_limit = game_data["level_points_limit"]
#		current_level = game_data["level"]
	
	if game_data["game"] == Profiles.Games.ENIGMA:
#		current_level = 1
#		current_level = game_data["level"]
#		current_level = game_data["level"]
		var current_level_settings: Dictionary = Profiles.enigma_level_setting[game_data["level"]]
#		print ("cond", Profiles.enigma_level_conditions[current_level])
		for setting in current_level_settings:
#			printt ("key", key)
			game_data[setting] = current_level_settings[setting]
		print ("GD", game_data)
		
#		level_conditions = Profiles.enigma_level_conditions[current_level]
#		game_data["level"] = level_conditions["level_name"]	


#	# set_level_conditions on start
#	if game_settings["eternal_mode"]:
#		if game_data["game"] == Profiles.Games.ETERNAL:
#			level_conditions = Profiles.eternal_level_conditions[1]
#		elif game_data["game"] == Profiles.Games.ETERNAL_XL:
#			level_conditions = Profiles.eternal_level_conditions[2]
#		respawn_wait_time = level_conditions["respawn_wait_time"]
#		respawn_strays_count = level_conditions["respawn_strays_count"]
#		level_points_limit = level_conditions["level_points_limit"]
#	if game_data["game"] == Profiles.Games.ENIGMA:
##		current_level = game_data["level_number"]
#		current_level = game_data["level"]
#		level_conditions = Profiles.enigma_level_conditions[current_level]
##		game_data["level"] = level_conditions["level_name"]


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
		if Global.strays_on_screen.size() <= game_settings["show_position_indicators_stray_count"] and game_settings["position_indicators_mode"]:
			show_position_indicators = true
		else:
			show_position_indicators = false
	else:
		show_position_indicators = false
	
	
func start_game():
	# namen: turn to wall respawn štartrespawnanje straysov ... za eternal
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.open_tutorial()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game_music")
			
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.set_physics_process(true)
			
		game_on = true
		
		# start respawning
		if game_settings["eternal_mode"]:
			respawn_timer.start(first_respawn_time)


func set_tilemap():
	# namen: load enigma level tilemap
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	
	var tilemap_to_load_path: String
	if game_data["game"] == Profiles.Games.ENIGMA: # path vlečem iz level settings
#		tilemap_to_load_path = level_conditions["level_tilemap_path"]
#		tilemap_to_load_path = game_data["level_tilemap_path"]
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
	# namen: split colors ...  naredim gradient iz naklujčnih barv iz spektruma	
	
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	var current_level: int = game_data["level"]
	
	# COLORS
	
	# setam sliko spektruma (za šrebanje in prvi level)
	var spectrum_image: Image
	var spectrum_texture: Texture = spectrum_rect.texture
	spectrum_image = spectrum_texture.get_data()
	spectrum_image.lock()
	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	
	# get color scheme
	var color_split_offset: float
	# prvi level je pisan ... vsi naslednji imajo random gradient
	if current_level <= 1:
		color_split_offset = spectrum_texture_width / strays_to_spawn_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	else:
		# izžrebam barvi gradienta iz nastavljenega spektruma
		var new_color_scheme_colors: Array
		var new_color_scheme_split_size: float = spectrum_texture_width / strays_to_spawn_count
		
		# žrebam prvo barvo iz celotnega bazena barv 
		var random_split_index_1: int = randi() % int(strays_to_spawn_count)
		var random_color_position_x_1: float = random_split_index_1 * new_color_scheme_split_size # lokacija barve v spektrumu
		var random_color_1: Color = spectrum_image.get_pixel(random_color_position_x_1, 0) # barva na lokaciji v spektrumu
		# žrebam drugi index iz omejenega nabora indexov barv  
		var split_minimal_distance: int = 20
		var split_min: int = random_split_index_1 - split_minimal_distance
		var split_max: int = random_split_index_1 + split_minimal_distance	
		var available_random_splits: Array
		for n in strays_to_spawn_count:
			if n < split_min or n > split_max:
				available_random_splits.append(n)
		var random_split_index_2: int # ... potem random število uporabim za random index v vseh splitih
		if available_random_splits.empty(): # v primeru ko je distanca prevelika, je navadno žrebanje
			random_split_index_2 = randi() % int(strays_to_spawn_count)
		# žrebam drugo barvo iz bazena barv, ki so od prve oddaljene za  xx  split_minimal_distance 
		else: 
			var available_random_split_index: int = randi() % int(available_random_splits.size()) # med index števili na voljo izbere random število
			random_split_index_2 = available_random_splits[available_random_split_index] # ... potem random število uporabim za random index v vseh splitih
		
		var random_color_position_x_2: float = random_split_index_2 * new_color_scheme_split_size # lokacija barve v spektrumu
		var random_color_2: Color = spectrum_image.get_pixel(random_color_position_x_2, 0) # barva na lokaciji v spektrumu		
		
		new_color_scheme_colors = [random_color_1, random_color_2]
		
		#		for n in 2:
		#			var random_split_index: int = randi() % int(strays_to_spawn_count)
		#			var random_color_position_x: float = random_split_index * new_color_scheme_split_size # lokacija barve v spektrumu
		#			var random_color: Color = spectrum_image.get_pixel(random_color_position_x, 0) # barva na lokaciji v spektrumu
		#			new_color_scheme_colors.append(random_color)

		# setam gradient barvne sheme (node)
		var scheme_gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		scheme_gradient.set_color(0, new_color_scheme_colors[0])
		scheme_gradient.set_color(1, new_color_scheme_colors[1])	
		color_split_offset = 1.0 / strays_to_spawn_count
	
	# STRAYS
	
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	# pred novim spawnom, ga resetiram
	all_stray_colors = [] # za color indikatorje

	for stray_index in strays_to_spawn_count:
		
		# stray color
		var current_color: Color
		var selected_color_position_x: float = stray_index * color_split_offset # lokacija barve v spektrumu
		
		if current_level <= 1: # default_color_scheme
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
	
		# available spawn positions
		var current_spawn_positions: Array
		if current_level <= 1: # spawnanje po "navidilih tilemapa
			if not available_required_spawn_positions.empty(): # najprej obvezne
				current_spawn_positions = available_required_spawn_positions
			elif available_required_spawn_positions.empty(): # potem random
				current_spawn_positions = available_random_spawn_positions
			elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
				print ("No available spawn positions")
				return
		else: # spawnanje na vse available za respawn
			if not available_respawn_positions.empty():
				current_spawn_positions = available_respawn_positions
#			if not proces_respawn_positions.empty():
#				current_spawn_positions = proces_respawn_positions
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
		if stray.current_state == stray.States.WALL:
			wall_strays_alive.append(stray)
	
	var strays_not_walls_count: int = get_tree().get_nodes_in_group(Global.group_strays).size() - wall_strays_alive.size()
				
	var random_stray_index: int = randi() % int(strays_not_walls_count)
	
	if get_tree().get_nodes_in_group(Global.group_strays).size() > random_stray_index: # error prevent
		var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
		random_stray.die_to_wall()
		return random_stray.stray_color
	else: # error
		print("no color to turn to wall")
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
	
	var curr_time = universal_time
	printt("upgrade start", curr_time)
	
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
	respawn_timer.start(first_respawn_time)
	
	printt("upgrade time from cleaned", universal_time - curr_time)
	

func set_new_level(): 
	# samo za eternal
	
	if game_settings["eternal_mode"]:
#		if current_level > 0:
#		game_data["level"] += 1
#		game_data["level"] = current_level
		level_points_limit += game_data["level_points_limit_grow"]
		respawn_wait_time *= game_data["respawn_wait_time_factor"]
		respawn_strays_count = game_data["respawn_strays_count_grow"]
		# število spawnanih straysov
		start_strays_spawn_count += game_data["level_spawn_strays_count_grow"]
		if game_data["level"] == 2: # prvi level ko se štarta zares
			start_strays_spawn_count = game_data["strays_start_count"]


func _change_strays_in_game_count(strays_count_change: int):
	# namen: vpelje upgrade level
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		return
	elif game_settings["eternal_mode"]:
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
