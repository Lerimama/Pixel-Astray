## KAJ DOGAJA
## - spawna plejerje in druge entitete v areni
## - spawna levele
## - uravnava potek igre (uvaljevlja pravila)
## - je centralna baza za vso statistiko igre
## - povezava med igro in HUDom

extends Node


# stats
var game_started: bool = false

# pixels
var spawned_player_index: int = 0 # zaenkrat ga ne rabim nekjer, se pa vseeno beleži
var spawned_stray_index: int = 0 # zaenkrat ga ne rabim nekjer, se pa vseeno beleži
var players_in_game: Array
var strays_in_game: Array
var new_player_stats: Dictionary
var new_game_stats: Dictionary

# tilemap
var available_positions: Array = [] # definiran tukaj, da ga lahko grebam do zunaj
var grid_cell_size: Vector2 # definiran tukaj, da ga lahko grebam do zunaj

onready var tilemap_floor_cells: Array
onready var pixel: KinematicBody2D = $"../Pixel"
onready var StrayPixel = preload("res://scenes/StrayPixel.tscn")
onready var PlayerPixel = preload("res://scenes/Pixel.tscn")

# _temp ... pripnem spawnanega, potem se bo vleklo glede na kolizijo
var P1
	

func _ready() -> void:
	randomize()
	Global.game_manager = self	


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		spawn_player_pixel("Moe")
	if Input.is_action_just_pressed("no2"):
		spawn_stray_pixel(1)
	if Input.is_action_just_pressed("no3"):
		spawn_stray_pixel(9)
#	if Input.is_action_just_pressed("x"):
#		start_game()
	if Input.is_action_just_pressed("r"):
		restart_game()
	if Input.is_action_just_released("ui_cancel"):	
		end_game()


func _process(delta: float) -> void:
	
	players_in_game = get_tree().get_nodes_in_group(Config.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Config.group_strays)	


func spawn_player_pixel(player_name):
	
	if not available_positions.empty():
		
		spawned_stray_index += 1
		
		# instance
		var new_player_pixel = PlayerPixel.instance()
		
		# žrebanje pozicije
		var selected_cell_index: int = Global.get_random_member_index(available_positions, 0)
		new_player_pixel.global_position = available_positions[selected_cell_index] # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji
		new_player_pixel.name = player_name
		
		#spawn
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# connect
		new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
		
		# odstranim uporabljeno celico
		available_positions.remove(selected_cell_index)	
		
		# ustvarimo plejerjev profil in plejerja aktiviramo (hud mora vedet)
		new_player_stats = Profiles.default_player_stats.duplicate()
#		player_active = true
		
		# _temp
		P1 = new_player_pixel	
		
var random_split_ad_factor = 0.1 # skrbi da je prilagojeno na številorazrezov

func split_colors(strays_count):
	
	# delim število straysov s številom komponent ... ker kličem funkcijo za vsako barvno komponento posebej
	var split_count = strays_count / 3
	
	# določim razpon vrednosti barve
	var split_color_value = color_spectrum / split_count
	var split_colors_random: Array = []
	
	# dodam "random" dodatek, ki je v razmerju s številom splitov
	var random_split_ad = (color_spectrum / split_count) * random_split_ad_factor
	# za vsak split
	for split in split_count:
		# randomiziraš
		var random_color_value = split_color_value + random_split_ad
		random_split_ad += random_split_ad
		
		# random vrednost zapišeš v array
		split_colors_random.append(random_color_value)
		printt("random_split_ad", random_split_ad)
	
	# resetiram randomize
	random_split_ad = (color_spectrum / split_count) * random_split_ad_factor
#		# določi obseg števil iz množice 255
#		var split_range = 255 / split_count
#
#		# določim lokacijo obsega v množici
#
#		split_index =
#
#
#	var new_color_r = 255 
#	var new_color_g
#	var new_color_b
#
#	# delim na število delov
#
	# dodam random števila v nekem obsegu + -
	
	return split_colors_random
	
	
var color_spectrum = 255.0	
func spawn_stray_pixel(strays_amount):
	
#	strays_amount = 50
#	var available_red_values: Array = split_colors(strays_amount)
#	var available_blue_colors: Array = split_colors(strays_amount)
#	var available_green_colors: Array = split_colors(strays_amount)
#	printt("available_red_values", available_red_values) # setget snapa pixel
	
	
	if not available_positions.empty():
		
		var color_component_index = 1 # za dolčanje katero RGB spreminjamo
		
		for color in 3: # 3 barv so v RGB
			# najprej rdeče barve
			for stray in strays_amount / 3:
				spawned_stray_index += 1
				
				# instance
				var new_stray_pixel = StrayPixel.instance()
				# žrebanje pozicije
				var selected_cell_index: int = Global.get_random_member_index(available_positions, 0)
				new_stray_pixel.global_position = available_positions[selected_cell_index] + grid_cell_size/2 # ... ne rabim snepat ker se v pixlu na redi funkciji
				#spawn
				Global.node_creation_parent.add_child(new_stray_pixel)
				# connect
				new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
				# odstranim uporabljeno pozicijo
				available_positions.remove(selected_cell_index)		
				# v hud 
				new_game_stats["stray_pixels"] += 1


				# BARVANJE PIXLA
				
				var available_red_values: Array = split_colors(strays_amount)
				
				
				# random barva iz arraya barv
				var random_red_value_index = randi() % available_red_values.size()
				var random_red_value = available_red_values[random_red_value_index]
				var random_red_value_float: float = random_red_value / color_spectrum
				
				
				# obarvaj pixel
				var random_pixel_color: Color = Color(random_red_value_float, 0, 0)
				
				match color_component_index:
					1:
						random_pixel_color = Color(random_red_value_float, 0, 0)
					2:
						random_pixel_color = Color(0, random_red_value_float, 0)
					3:
						random_pixel_color = Color(0, 0, 1)
				
				color_component_index += 1
				if color_component_index > 3:
					color_component_index = 1	
				
				new_stray_pixel.modulate = random_pixel_color

			
			
			


func start_game():
	
	# spawnam plejerja
	spawn_player_pixel("Moe")
	
	# pogrebamo profil statsov igre
	new_game_stats = Profiles.default_game_stats.duplicate()
	game_started = true

	
func end_game():
		
	# game ni štartan
	game_started = false
	
	# zbrišem pixle
	if not strays_in_game.empty():
		for stray in strays_in_game:
			stray.queue_free()
			
	if not players_in_game.empty():
		for player in players_in_game:
			player.queue_free()
	
	# statistika igre se restira ob reštartu, ko povleče podatke iz default profila
	# statistika plejerja se restira ob spawnanju plejerja, ko povleče podatke iz default profila

	spawned_stray_index = 0 
	
	
func restart_game():
	
	end_game()
	start_game()
	

func _on_FloorMap_floor_completed(cells_global_positions, cell_size) -> void:

	available_positions = cells_global_positions 
	grid_cell_size = cell_size

	
func _on_stat_changed(stat_owner, changed_stat, new_stat_value):
# ne setaš tipa parametrov, ker je lahko v različnih oblikah (index, string, float, ...)
	
	printt("GM",stat_owner, changed_stat, new_stat_value)
	
	var black_pixel_points = 10
	var skill_change_points = - 3
	var cell_travel_points = - 1
	
	# napolni slovarje s statistko
	match changed_stat:
	
		
		# player stats
		"life": 
			new_player_stats["life"] += new_stat_value
			if new_player_stats["life"] > 0:
				spawn_player_pixel("Moe")
			printt("LIFE: ", new_player_stats["life"])
			
			# reset player stats (nekatere) 
			new_player_stats["cells_travelled"] = 0
			new_player_stats["skill_change_count"] = 0
			# pa picked color dej na črno
			
			# če ni več lajfa
			if new_player_stats["life"] <= 0:
				printt("_temp", "GAME OVER")
				pass
	
		"cells_travelled": 
			new_player_stats["cells_travelled"] += new_stat_value
			printt("CELLS TRAVELLED: ", new_player_stats["cells_travelled"])
			# točke
			if new_player_stats["points"] > 0:
				new_player_stats["points"] += cell_travel_points
				
		"skill_change_count": 
			new_player_stats["skill_change_count"] += new_stat_value
			printt("COLOR CHNG: ", new_player_stats["skill_change_count"])
			# točke
			if new_player_stats["points"] > 0:
				new_player_stats["points"] += skill_change_points
			
		"black_pixels": 
			new_game_stats["black_pixels"] += new_stat_value
			new_game_stats["stray_pixels"] -= new_stat_value
			printt("BLACK PIXELS: ", new_game_stats["black_pixels"])
			# točke
			new_player_stats["points"] += black_pixel_points
		
		
		# game stats ... nekatere se beležijo prek FP
#		"stray_pixels": 
#			new_game_stats["stray_pixels"] += new_stat_value
#			printt("STRAY PIXELS: ", new_game_stats["stray_pixels"])
#		"points": 
#			new_player_stats["points"] += new_stat_value
#			printt("POINTS: ", new_player_stats["points"])
		
	# disable moving
	if new_player_stats["points"] <= 0:
		print("CAN'T MOVE")
		
