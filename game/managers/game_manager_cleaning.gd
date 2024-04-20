extends GameManager


var current_level: int = 1 # za classic

var strays_wall_count: int = 0 # za pravilno brisanje in beleženje, resetiram na 0 na vsak novi level

onready var turn_to_wall_timer: Timer = $"../TurnToWallTimer"
onready	var level_conditions: Dictionary = Profiles.classic_level_conditions[Profiles.Games.CLASSIC]
onready var turn_to_wall_time: float = level_conditions["turn_to_wall_time"]
onready var turn_to_wall_strays_count: int = level_conditions["turn_to_wall_strays_count"]
onready var level_points_limit: int = level_conditions["level_points_limit"]
onready var strays_spawn_count: int #  = level_conditions["level_points_limit"]


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no2"):
		get_tree().call_group(Global.group_strays, "die_to_wall")
	if Input.is_action_pressed("no1"):
		upgrade_level()
		
	if Input.is_action_pressed("ui_accept"):
		for n in 1:
			# random stray to wall
			var random_stray_index: int = randi() % int(strays_in_game_count)
			var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
			random_stray.die_to_wall()
			
	
func _ready() -> void:

	Global.game_manager = self
	
	StrayPixel = preload("res://game/pixel/stray_cleaning.tscn")
	PlayerPixel = preload("res://game/pixel/player_cleaning.tscn")
	
	randomize()


func _process(delta: float) -> void:
	# namen: respawnanje straysov ... za classic in upoštevanje wall straysov zaznavanju cleaned
	
	# če sem v fazi, ko lahko preverjam cleaned (po spawnu)
	printt("COUNT", strays_in_game_count, all_strays_died_alowed)
	if all_strays_died_alowed:
		print("GO")
		# če ni nobene stene, me zanimajo samo prazni strajsi
		if strays_in_game_count == 0:
			all_strays_died_alowed = false
			emit_signal("all_strays_died")
		# če so v igri samo še straysi, ki so stene
		elif strays_in_game_count == strays_wall_count:
	#	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
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
	# namen: turn to wall respawn štartrespawnanje straysov ... za classic
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.open_tutorial()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game_music")
			
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.set_physics_process(true)
			
		game_on = true
		
		# turn to wall
		var first_turn_to_wall_time: float = 1
#		all_strays_died_alowed = true
#		turn_to_wall_timer.start(first_turn_to_wall_time)

		
func turn_random_strays_to_wall():
	
	for count in turn_to_wall_strays_count:
		# random stray to wall
		printt("strays_in_game_count", strays_in_game_count)
		printt("group_count", get_tree().get_nodes_in_group(Global.group_strays).size())
		var random_stray_index: int = randi() % int(strays_in_game_count)
		if get_tree().get_nodes_in_group(Global.group_strays).size() > random_stray_index:
			var random_stray: KinematicBody2D = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_index]
			if game_settings["stray_to_wall_mode"]:
				random_stray.die_to_wall()
				yield(get_tree().create_timer(1), "timeout")
			Global.game_manager.respawn_stray(random_stray.stray_color)	
	
	
func spawn_strays(strays_to_spawn_count: int):
	# namen: split colors ...  naredim gradient iz naklujčnih barv iz spektruma	
	
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
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
		for n in 2:
			var random_split_index: int = randi() % int(strays_to_spawn_count)
			var random_color_position_x: float = random_split_index * new_color_scheme_split_size # lokacija barve v spektrumu
			var random_color: Color = spectrum_image.get_pixel(random_color_position_x, 0) # barva na lokaciji v spektrumu
			new_color_scheme_colors.append(random_color)
			printt ("color",new_color_scheme_colors)
		# setam gradient barvne sheme (node)
		var scheme_gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		scheme_gradient.set_color(0, new_color_scheme_colors[0])
		scheme_gradient.set_color(1, new_color_scheme_colors[1])	
		
		color_split_offset = 1.0 / strays_to_spawn_count
	
	# spawn strays
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var all_colors: Array = [] # za color indikatorje

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
			else:
				print ("No available spawn positions")
				return
		
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
		
		all_colors.append(current_color)
		current_spawn_positions.remove(selected_cell_index) # odstranim pozicijo iz nabora za start spawn
		update_available_respawn_positions("remove", new_stray_pixel.global_position) # odstranim pozicijo iz nabora za respawn
		
		new_stray_pixel.show_stray()
			
	Global.hud.spawn_color_indicators(all_colors) # barve pokažem v hudu		
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba


func set_level_conditions(): # za classic
	
	if current_level > 0:
		level_points_limit += level_conditions["level_points_limit"]
		turn_to_wall_time /= level_conditions["turn_to_wall_time_div"]
		turn_to_wall_strays_count = level_conditions["turn_to_wall_strays_count_factor"]
		# spawn strays count
		strays_spawn_count += level_conditions["strays_spawn_count_grow"]
		game_data["strays_start_count"] = strays_spawn_count
		printt("new level", current_level)
	
	
func upgrade_level(): # za classic
	# levelov je neskončno, samo hitrost se veča

	current_level += 1 # številka novega levela 
	
	set_level_conditions() 
	Global.hud.empty_color_indicators()
	turn_to_wall_timer.stop()
	Global.hud.level_up_popup_in(current_level)
	strays_wall_count = 0
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	clean_strays_in_game() # puca vse v igri
	
	all_strays_died_alowed = true
	yield(self, "all_strays_died") # ko so vsi iz igre grem naprej
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.all_cleaned()
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	set_strays() 
	Global.hud.level_up_popup_out()
	get_tree().call_group(Global.group_players, "set_physics_process", true)

	turn_to_wall_timer.stop()

#	yield(get_tree().create_timer(1), "timeout") # za dojet
	var first_turn_to_wall_time: float = 1
	turn_to_wall_timer.start(first_turn_to_wall_time)


func clean_strays_in_game(): # za classic
	
	# vsi straysi
	var all_strays_alive: Array = get_tree().get_nodes_in_group(Global.group_strays)
	# dodam še tiste, ki so stena
	for wall_object in get_tree().get_nodes_in_group(Global.group_wall):
		if wall_object is Stray:
			all_strays_alive.append(wall_object)
	
	for stray in all_strays_alive:
		var stray_index: int = all_strays_alive.find(stray)
		var all_strays_alive_count: int = all_strays_alive.size()
		stray.die(stray_index, all_strays_alive_count)
	printt("all_strays_alive", all_strays_alive.size())
	
	# javim število, ki se bo pucalo ... to pomeni, da se tudi teli štejejo v spucane od plejerja
#	self.strays_in_game_count = - all_strays_alive.size() # setget sprememba
#	all_strays_died_alowed = true # javi signal, ko so vsi spucani 

	return true

	
func respawn_stray(spawned_stray_color: Color): # za classic
	
	if available_respawn_positions.empty():
		# turn all to wall?
		return
	print("spawn")
	
	
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
	
	# odstranim uporabljeno pozicijo
	update_available_respawn_positions("remove", new_stray_pixel.global_position)
	printt("spawn", new_stray_pixel.global_position)
	new_stray_pixel.show_stray()

	self.strays_in_game_count = 1 # setget sprememba	


func _change_strays_in_game_count(strays_count_change: int):
	# namen: vpelje upgrade level
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		return
	elif game_data["game"] == Profiles.Games.CLASSIC:
		if strays_in_game_count == 0 or strays_in_game_count == strays_wall_count: # tutorial sam ve kdaj je gameover, klasika pa nima cleaned modela 
			Global.game_manager.upgrade_level()
	else:
		if strays_in_game_count == 0: # tutorial sam ve kdaj je gameover, klasika pa nima cleaned modela 
			game_over(GameoverReason.CLEANED)	

func _on_TurnToWallTimer_timeout() -> void:
	
	turn_random_strays_to_wall()
	turn_to_wall_timer.start(turn_to_wall_time)
