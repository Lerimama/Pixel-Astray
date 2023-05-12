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
	
	Global.game_manager = self	


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		spawn_player_pixel("Moe")
	if Input.is_action_just_pressed("no2"):
		spawn_stray_pixel(1)
	if Input.is_action_just_pressed("no3"):
		spawn_stray_pixel(50)
	if Input.is_action_just_pressed("x"):
		start_game()
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
		
			
func spawn_stray_pixel(strays_amount):
	
	if not available_positions.empty():
		
		for stray in strays_amount:
		
			spawned_stray_index += 1
			
			# instance
			var new_stray_pixel = StrayPixel.instance()
			
			# določanje tipa
			var skills_dictionary: Dictionary = new_stray_pixel.States
			var selected_skill_index: int = Global.get_random_member_index(skills_dictionary, 1)
			new_stray_pixel.current_state = selected_skill_index # setget snapa pixel

			# žrebanje pozicije
			var selected_cell_index: int = Global.get_random_member_index(available_positions, 0)
			new_stray_pixel.global_position = available_positions[selected_cell_index] # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji
			
			#spawn
			Global.node_creation_parent.add_child(new_stray_pixel)
			
			# connect
			new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
			
			# odstranim uporabljeno celico
			available_positions.remove(selected_cell_index)		


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
	
#	printt("GM",stat_owner, changed_stat, new_stat_value)
#	var player_stats_to_change: Dictionary = game_stats[stat_owner_id]
	
	# napolni slovarje s statistko
	match changed_stat:
		
		# player stats
		"life": 
			new_player_stats["life"] += new_stat_value
			printt("LIFE: ", new_player_stats["life"])
		"points": 
			new_player_stats["points"] += new_stat_value
			printt("POINTS: ", new_player_stats["points"])
		"color_sum": 
			new_player_stats["points"] += new_stat_value
			printt("COLOR SUM: ", new_player_stats["color_sum"])
		"colors_picked": 
			new_player_stats["points"] += new_stat_value
			printt("COLORS PICKED: ", new_player_stats["colors_picked"])
		"color_change_count": 
			new_player_stats["color_change_count"] += new_stat_value
			printt("COLOR CHNG: ", new_player_stats["color_change_count"])
		# game stats ... nekatere se beležijo prek FP
		"colors_left": 
			new_game_stats["colors_left"] += new_stat_value
			printt("COLOR LEFT: ", new_game_stats["colors_left"])		
		"stray_pixels": 
			new_game_stats["stray_pixels"] += new_stat_value
			printt("STRAY PIXELS: ", new_game_stats["stray_pixels"])
		"black_pixels": 
			new_game_stats["black_pixels"] += new_stat_value
			printt("BLACK PIXELS: ", new_game_stats["black_pixels"])

