extends Node


export var strays_count: int = 100
export var game_time_limit: float = 1
export var black_pixel_points = 10
export var skill_change_points = - 3
export var cell_travel_points = - 1

export var pick_neighbour_mode = false

# states
var game_is_on: bool = false
var gametime_is_up: bool = false
var deathmode_on = false
var pause_on = false

# pixels
var spawned_player_index: int = 0
var spawned_stray_index: int = 0
var players_in_game: Array
var strays_in_game: Array
var new_player_stats: Dictionary
var new_game_stats: Dictionary

# tilemap
var available_floor_positions: Array # po signalu ob kreaciji tilemapa ... tukaj, da ga lahko grebam do zunaj

# color spliting	
var color_indicator_width: float = 12 # ročno setaj pravilno
onready var spectrum_rect: TextureRect = $Spectrum


onready var hud: Control = Global.hud
onready var tilemap_floor_cells: Array
onready var StrayPixel = preload("res://scenes/Pixel.tscn")
onready var PlayerPixel = preload("res://scenes/Pixel.tscn")
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var start_position: Position2D = $"../StartPosition"

# _temp ... pripnem spawnanega, potem se bo vleklo glede na kolizijo ... lahko tudi enumse uporabiš
# ni _temp ... je tarča kamere
var P1: Node2D
var P2: Node2D
var P1_name: String = "P1"
var P2_name: String = "P2"

var colors_to_pick: Array

func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		spawn_player_pixel()
#	if Input.is_action_just_pressed("no2"):
#		split_colors(strays_count/2)
#	if Input.is_action_just_pressed("no3"):
#		split_colors(strays_count)
	if Input.is_action_just_pressed("r"):
		end_game()


func _ready() -> void:
	
	Global.game_manager = self	
	Global.node_creation_parent = get_parent()
	Global.level_start_position = start_position
	
	randomize()
	
	# štartej igro
	animation_player.play("arena_in")
	hud.visible = false

	
func _process(delta: float) -> void:
	
	players_in_game = get_tree().get_nodes_in_group(Config.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Config.group_pixels)
	
	if Global.game_manager.players_in_game.empty():
		Global.camera_target = null


func spawn_player_pixel():
	
#	if not available_floor_positions.empty():
		
		spawned_player_index += 1
		
		# instance
		var new_player_pixel = PlayerPixel.instance()
		
		# random grid pozicija
#		var random_range = available_floor_positions.size()
#		var selected_cell_index: int = randi() % int(random_range) # + offset
#		new_player_pixel.global_position = available_floor_positions[selected_cell_index] # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji?
		
		new_player_pixel.global_position = start_position.global_position # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji
		new_player_pixel.pixel_color = Config.color_white
		
		# ta pixel je plejer in ne računalnik
		new_player_pixel.pixel_is_player = true
		new_player_pixel.add_to_group(Config.group_players)

		# ime
		var spawned_player_name = "P%s" % str(spawned_player_index)
		new_player_pixel.name = spawned_player_name
		
		#spawn
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# povežem
		new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
		
		# odstranim uporabljeno celico
#		available_floor_positions.remove(selected_cell_index)	
		
		# ustvarimo plejerjev profil in plejerja aktiviramo (hud mora vedet)
		new_player_stats = Profiles.default_player_stats.duplicate()
		new_player_stats["player_active"] = true
		
		# camera target
		Global.camera_target = new_player_pixel
		Global.player_camera.reset_camera_position()
		# _temp
		P1 = new_player_pixel	
		
		# premik kamere na štartu
		yield(get_tree().create_timer(1), "timeout")
		Global.player_camera.drag_margin_top = 0.2
		Global.player_camera.drag_margin_bottom = 0.2
		Global.player_camera.drag_margin_left = 0.3
		Global.player_camera.drag_margin_right = 0.3
		
		
func spawn_stray_pixel(stray_color):
	
#	if not available_floor_positions.empty():	
		
		spawned_stray_index += 1

		# instance
		var new_stray_pixel = StrayPixel.instance()
		
		# random grid pozicija
		var random_range = available_floor_positions.size()
		var selected_cell_index: int = randi() % int(random_range) # + offset
		new_stray_pixel.global_position = available_floor_positions[selected_cell_index] # + grid_cell_size/2
		
		# obarvajmo ga ...
		new_stray_pixel.pixel_color = stray_color
		new_stray_pixel.add_to_group(Config.group_pixels)
		
		#spawn
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		# connect
		new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
		
		# odstranim uporabljeno pozicijo
		available_floor_positions.remove(selected_cell_index)		
		
		# v hud 
		new_game_stats["stray_pixels"] += 1
	

func split_colors(color_count):
	
	color_count = clamp(color_count, 1, color_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
	# poberem sliko
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()
	
	# izračun razmaka med barvami
	var spectrum_texture_width = spectrum_rect.rect_size.x - (color_indicator_width + 1) # odštejem širino zadnje, da bo lep razmak in, da ne
	var color_skip_size = spectrum_texture_width / (color_count - 1) # razmak barv po spektru
	
	# nabiranje barv
	var selected_colors: Array = []
	var loop_count = 0
	for color in color_count:
		
		# pozicija pixla na sliki
		var selected_color_position_y = 0 # _temp
		var selected_color_position_x = loop_count * color_skip_size
		
		# zajem barve na lokaciji pixla
		var selected_color = spectrum_image.get_pixel(selected_color_position_x, 0)
		selected_colors.append(selected_color)
		
		# spawn indikatorja na poziciji
		hud.spawn_color_indicator(selected_color_position_x,selected_color_position_y, selected_color)				
		spawn_stray_pixel(selected_color)
		
		loop_count += 1


# GAME LOOP ----------------------------------------------------------------------------------


func start_game():
	
	# pogrebamo profil statsov igre
	new_game_stats = Profiles.default_game_stats.duplicate()
	
	# spawnam plejerja in pixle
	spawn_player_pixel()
	split_colors(strays_count)
	
	# štart igre
	hud.start_game_time = game_time_limit
	game_is_on = true
	hud.visible = true
	hud.modulate.a = 1

	
func end_game():
	
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(false)
	game_is_on = false
	deathmode_on =  false
	
	yield(get_tree().create_timer(1), "timeout")
	
	# gameover in podamo mu skor
	Global.gameover_menu.fade_in(new_game_stats["player_points"])
	
	# kamera target
	Global.camera_target = null
	
	# zbrišem pixle in indikatorje v hudu
	if not strays_in_game.empty():
		for stray in strays_in_game:
			stray.queue_free()
		hud.erase_all_indicators()
	
	# zbrišem plejerja		
	if not players_in_game.empty():
		for player in players_in_game:
			player.queue_free()
	
	hud.visible = false
	
	# game ni štartan
	
	# tarča kamere je null
	
	# statistika igre se restira ob reštartu, ko povleče podatke iz default profila
	# statistika plejerja se restira ob spawnanju plejerja, ko povleče podatke iz default profila

	spawned_stray_index = 0 
	spawned_player_index = 0

	
func restart_game():
	
	end_game()
	start_game()


	
# SIGNALI ----------------------------------------------------------------------------------


func _on_FloorMap_floor_completed(floor_cells_global_positions: Array) -> void:

	available_floor_positions = floor_cells_global_positions 


func _on_stat_changed(stat_owner, changed_stat, new_stat_value):
	
#	printt("GM",stat_owner, changed_stat, new_stat_value)
	# napolni slovarje s statistko
	match changed_stat:
		
		"pixels_in_game": 
			
			if stat_owner.is_in_group(Config.group_players):
				new_game_stats["player_life"] += new_stat_value
				if new_game_stats["player_life"] > 0:
					spawn_player_pixel()
				
				# reset player stats (nekatere) 
				new_player_stats["cells_travelled"] = 0
				new_player_stats["skill_change_count"] = 0
				
				# če ni več lajfa
				if new_game_stats["player_life"] <= 0:
					printt("_temp", "GAME OVER")
					
			if stat_owner.is_in_group(Config.group_pixels):
				new_game_stats["black_pixels"] -= new_stat_value
				new_game_stats["stray_pixels"] += new_stat_value
				# točke
				new_game_stats["player_points"] += black_pixel_points
	
		"cells_travelled": 
			new_player_stats["cells_travelled"] += new_stat_value
			# točke
			if new_game_stats["player_points"] > 0:
				new_game_stats["player_points"] += cell_travel_points
				
		"skill_change_count": 
			new_player_stats["skill_change_count"] += new_stat_value
			# točke
			if new_game_stats["player_points"] > 0:
				new_game_stats["player_points"] += skill_change_points
				
		
	# disable moving
	if new_game_stats["player_points"] <= 0:
#		print("CAN'T MOVE, no points")
		pass

	
func _on_QuitBtn_pressed() -> void:
#	yield(get_tree().create_timer(2), "timeout")
#	Global.switch_to_scene("res://scenes/arena/Arena.tscn")
	pass
	
	
func _on_RestartBtn_pressed() -> void:
#	yield(get_tree().create_timer(2), "timeout")
#	Global.switch_to_scene("res://scenes/arena/Home.tscn")
	pass

