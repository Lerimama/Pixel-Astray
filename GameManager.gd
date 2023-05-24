extends Node


# states
var game_is_on: bool = false
var gametime_is_up: bool = false
var deathmode_on = false
var pause_on = false

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

#onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var tilemap_floor_cells: Array
onready var pixel: KinematicBody2D = $"../Pixel"
onready var StrayPixel = preload("res://scenes/Pixel.tscn")
onready var PlayerPixel = preload("res://scenes/Pixel.tscn")

# GUI
onready var scene_tree: = get_tree() # za pavzo
onready var hud: Control = $"../HudLayer/HudControl"

# _temp ... pripnem spawnanega, potem se bo vleklo glede na kolizijo
var P1
	
var strays_count: int = 14
var color_indicator_width: float = 12 # ročno setaj pravilno

var color_indicators: Array = []
onready var spectrum_rect: TextureRect = $Spectrum
#onready var indicator_holder: Control = $"../UI/HUD/HudControl/ColorSpectrum/IndicatorHolder"
onready var ColorIndicator: PackedScene = preload("res://scenes/ColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $"../HudLayer/HudControl/ColorSpectrumLite/IndicatorHolder"


func _ready() -> void:
	
	Global.game_manager = self	
	randomize()
	
	# štartej igro
#	animation_player.play("the_beginning")
#	hud.visible = false
#	pause_menu.visible = false
	pass


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		spawn_player_pixel("Moe")
	if Input.is_action_just_pressed("no2"):
		split_colors(strays_count/2)
	if Input.is_action_just_pressed("no3"):
		split_colors(strays_count)
	if Input.is_action_just_pressed("r"):
		restart_game()

	
func _process(delta: float) -> void:
#	print(pause_on)
	players_in_game = get_tree().get_nodes_in_group(Config.group_players)	# zaenkrat ne rabm
	strays_in_game = get_tree().get_nodes_in_group(Config.group_pixels)	# zaenkrat ne rabm


func spawn_player_pixel(player_name):
	
#	if not available_positions.empty():
		
		spawned_stray_index += 1
		
		# instance
		var new_player_pixel = PlayerPixel.instance()
		
		# žrebanje pozicije
		var selected_cell_index: int = Global.get_random_member_index(available_positions, 0)
		new_player_pixel.global_position = available_positions[selected_cell_index] # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji
		new_player_pixel.name = player_name
		
		# ta pixel je plejer
		new_player_pixel.pixel_is_player = true
		new_player_pixel.add_to_group(Config.group_players)
		
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


func spawn_stray_pixel(stray_color):
	
#	if not available_positions.empty():	
		
		spawned_stray_index += 1

		# instance
		var new_stray_pixel = StrayPixel.instance()
		# žrebanje pozicije
		var selected_cell_index: int = Global.get_random_member_index(available_positions, 0)
		new_stray_pixel.global_position = available_positions[selected_cell_index] + grid_cell_size/2 # ... ne rabim snepat ker se v pixlu na redi funkciji
		
		# obarvajmo ga ...
		new_stray_pixel.modulate = stray_color
		
		#spawn
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		# connect
		new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
		
		# odstranim uporabljeno pozicijo
		available_positions.remove(selected_cell_index)		
		
		# v hud 
		new_game_stats["stray_pixels"] += 1
	
	
func spawn_color_indicator(position_x,selected_color_position_y, selected_color):
	
	var new_color_indicator = ColorIndicator.instance()
	new_color_indicator.rect_position.x = position_x
	new_color_indicator.rect_position.y = selected_color_position_y
	new_color_indicator.color = selected_color
	indicator_holder.add_child(new_color_indicator)
	color_indicators.append(new_color_indicator)


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
		spawn_color_indicator(selected_color_position_x,selected_color_position_y, selected_color)				
		spawn_stray_pixel(selected_color)
		
		loop_count += 1


func erase_color_indicator(picked_pixel_color):
		
	for indicator in color_indicators:
		if indicator.color == picked_pixel_color:
#			indicator.queue_free()
#			color_indicators.erase(indicator)
			indicator.modulate = Color.black
			break


# GAME LOOP ----------------------------------------------------------------------------------


func start_game():
	
	hud.visible = true
	hud.modulate.a = 1
	
	# spawnam plejerja
	spawn_player_pixel("Moe")
	
	# pogrebamo profil statsov igre
	new_game_stats = Profiles.default_game_stats.duplicate()
	game_is_on = true

	
func end_game():
	
	hud.visible = false
	
#	return		
	
	# game ni štartan
	game_is_on = false
	deathmode_on =  false
	
	# zbrišem pixle
	if not strays_in_game.empty():
		for stray in strays_in_game:
			stray.queue_free()
	if color_indicators:
		for indicator in color_indicators:
			indicator.queue_free()
			color_indicators.erase(indicator)
#			erase_color_indicator(stray.modulate)
			
	if not players_in_game.empty():
		for player in players_in_game:
			player.queue_free()
	
	# statistika igre se restira ob reštartu, ko povleče podatke iz default profila
	# statistika plejerja se restira ob spawnanju plejerja, ko povleče podatke iz default profila

	spawned_stray_index = 0 
	
	
func restart_game():
	
	end_game()
	start_game()


	
# SIGNALI ----------------------------------------------------------------------------------


func _on_FloorMap_floor_completed(cells_global_positions, cell_size) -> void:

	available_positions = cells_global_positions 
	grid_cell_size = cell_size

export var black_pixel_points = 10
export var skill_change_points = - 3
export var cell_travel_points = - 1

func _on_stat_changed(stat_owner, changed_stat, new_stat_value):
	
#	printt("GM",stat_owner, changed_stat, new_stat_value)
	# napolni slovarje s statistko
	match changed_stat:
		
		"pixels_in_game": 
			
			if stat_owner.is_in_group(Config.group_players):
				new_game_stats["player_life"] += new_stat_value
				if new_game_stats["player_life"] > 0:
					spawn_player_pixel("Moe")
				
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
			
#		"player_life": 
#			new_game_stats["player_life"] += new_stat_value
#			if new_game_stats["player_life"] > 0:
#				spawn_player_pixel("Moe")
#
#			# reset player stats (nekatere) 
#			new_player_stats["cells_travelled"] = 0
#			new_player_stats["skill_change_count"] = 0
#			# pa picked color dej na črno
#
#			# če ni več lajfa
#			if new_game_stats["player_life"] <= 0:
##				printt("_temp", "GAME OVER")
#				pass
#		"black_pixels": 
#			new_game_stats["black_pixels"] += new_stat_value
#			new_game_stats["stray_pixels"] -= new_stat_value
#			# točke
#			new_game_stats["player_points"] += black_pixel_points
		
		
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
