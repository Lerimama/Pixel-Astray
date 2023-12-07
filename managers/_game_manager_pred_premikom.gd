extends Node


signal all_strays_cleaned # signal za sebe, počaka, da se vsi kvefrijajo
signal winner_rewarded # signal za sebe, da počaka na animacije in nagrade

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var colors_to_pick: Array # za hud nejbrhud pravila
var energy_drain_active: bool = false # za kontrolo črpanja energije

# cam shake
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	
var strays_spawn_loop: int = 0	

# players
var p1: KinematicBody2D
var p2: KinematicBody2D
var spawned_player_index: int = 0
var player_start_positions: Array
var players_in_game: Array

# strays
var strays_in_game: Array = [] # za spawnanje v rundah in cleaned GO tajming
var strays_start_count: int # opredeli se on_tilemap_completed

# tilemap data
var floor_positions: Array
var random_spawn_positions: Array
var required_spawn_positions: Array

# profiles
#var p1_stats: Dictionary = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
#var p2_stats: Dictionary = Profiles.default_player_stats.duplicate()
onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš

onready var spectrum_rect: TextureRect = $Spectrum
#onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var default_tilemap: TileMap = $"../Tilemap"
onready var FloatingTag = preload("res://game/hud/floating_tag.tscn")
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")


func _ready() -> void:
	
	Global.node_creation_parent = get_parent() # arena je node creation parent
	Global.game_manager = self
	
	randomize()
	
	set_tilemap()
	call_deferred("set_game") # deferamo, da se naloži tilemap
	
	
func _process(delta: float) -> void:
	
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	
	if strays_in_game.size() == 0 and game_on:
		emit_signal("all_strays_cleaned")
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	# tilemap
	Global.game_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	Global.game_tilemap.get_tiles()
	
#	game_settings["player_start_color"] = Global.color_white # more bit pred spawnom
	set_players() # spawn, stats, camera, target
	for player in players_in_game:
		player.modulate.a = 0	
	
	yield(get_tree().create_timer(3), "timeout") # da se ekran prikaže
	
	# strays
	if game_data["game"] != Profiles.Games.TUTORIAL: 
		generate_strays()
		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda
		
	# HS
	if game_settings["manage_highscores"]:
		var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_data["game"])
		game_data["highscore"] = current_highscore_line[0]
		game_data["highscore_owner"] = current_highscore_line[1]
	
	# hud fejdin ... on kliče kamera zoom
	Global.hud.fade_in()
	yield(Global.hud, "hud_is_set")
		
	# start countdown
	if game_settings["start_countdown"]:
		Global.start_countdown.start_countdown()
		yield(Global.start_countdown, "countdown_finished")	
	
	start_game()
	
	
func start_game():
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.start()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game_music")
		for player in players_in_game:
			player.set_physics_process(true)
			player.animation_player.play("virgin_blink")
	
	game_on = true
	
	
func game_over(gameover_reason):
	
	game_on = false
	
	# ustavljanje elementov igre
	get_viewport().gui_disable_input = true	# in-gejm keyboard inputs
	Global.hud.game_timer.stop_timer() # ustavim tajmer
	Global.hud.popups.visible = false # skrijem morebitne popupe
	
	# ugasnem vse efekte, ki bi bili lahko neskončno slišni
	Global.sound_manager.stop_sfx("teleport")
	Global.sound_manager.stop_sfx("heartbeat")
	
	# plejerje pavziram v GO
	
	# open game-over ekran
	Global.gameover_menu.show_gameover(gameover_reason)
	
	
# PIXELS ----------------------------------------------------------------------------------


func set_players():
	
	# spawn
	for player_position in player_start_positions: # glavni param, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		var new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Global.game_tilemap.cell_size/2 # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.pixel_color = game_settings["player_start_color"]
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.node_creation_parent.add_child(new_player_pixel)
#		new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
		
		new_player_pixel.set_physics_process(false)
		players_in_game.append(new_player_pixel)
	
	# p1
	p1 = players_in_game[0]
#	p1.player_stats["player_energy"] = game_settings["player_start_energy"]
#	p1.player_stats["player_life"] = game_settings["player_start_life"]
	Global.p1_camera_target = p1 # tole gre lahko v plejerja
	p1.player_camera = Global.p1_camera
	
	# p2 
	if players_in_game.size() > 1:
		p2 = players_in_game[1]
#		p2_stats["player_energy"] = game_settings["player_start_energy"]
#		p2_stats["player_life"] = game_settings["player_start_life"]
		Global.p2_camera_target = p2 # tole gre lahko v plejerja
		p2.player_camera = Global.p2_camera
	

func generate_strays():
	
	split_stray_colors()
	show_strays()
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	strays_spawn_loop = 0 # zazih
	
	
func split_stray_colors():
	
	# split colors
	var color_count: int = strays_start_count
	color_count = clamp(color_count, 1, color_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
	# poberem sliko
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()
	
	# izračun razmaka med barvami
	var spectrum_texture_width = spectrum_rect.rect_size.x
	var color_skip_size = spectrum_texture_width / color_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	
	# nabiranje barv za vsak pixel
	var all_colors: Array = []
	
	
	var spawned_stray_index: int = 1
	
	for color in color_count:
		# lokacija barve v spektrumu
		var selected_color_position_x = (spawned_stray_index - 1) * color_skip_size # -1, da začne z 0, če ne "out of bounds" error
		# barva na lokaciji v spektrumu
		var current_color = spectrum_image.get_pixel(selected_color_position_x, 0)  
		all_colors.append(current_color)
		# spawn stray 
		spawn_stray(current_color, spawned_stray_index)
		spawned_stray_index += 1
		
	Global.hud.spawn_color_indicators(all_colors)				


func spawn_stray(stray_color, stray_index):
	
	# izbor spawn pozicije 
	var available_positions: Array
	if not required_spawn_positions.empty(): # najprej obvezne
		available_positions = required_spawn_positions
	elif required_spawn_positions.empty(): # potem random
		available_positions = random_spawn_positions
	elif random_spawn_positions.empty() and required_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
		print ("No available spawn positions")
		return
	
	# randomizacija	
	var random_range = available_positions.size()
	var selected_cell_index: int = randi() % int(random_range)
	
	# spawn
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "S%s" % str(stray_index)
	new_stray_pixel.pixel_color = stray_color
	new_stray_pixel.global_position = available_positions[selected_cell_index] + Global.game_tilemap.cell_size/2 # dodana adaptacija zaradi središča pixla
	new_stray_pixel.z_index = 2 # višje od plejerja
	Global.node_creation_parent.add_child(new_stray_pixel)
	
	# odstranim uporabljeno pozicijo
	available_positions.remove(selected_cell_index) # ker ni duplikat array, se briše
	

func show_strays():
	
	Global.p1_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	if p2:
		Global.p2_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
		
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	strays_spawn_loop += 1
	if strays_spawn_loop > 4:
		return
	
	var strays_shown: Array = []
	match strays_spawn_loop:
		1: # polovica
			Global.sound_manager.play_sfx("thunder_strike")
			# Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game.size()/2)
		2: # četrtina
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game.size()/4)
		3: # osmina
			strays_to_show_count = round(strays_in_game.size()/8)
		4: # še preostale
			strays_to_show_count = strays_in_game.size() - strays_shown.size()
	
	# fade-in za vsak stray v igri ... med še ne pokazanimi (strays_to_show)
	var loop_count = 0
	for stray in strays_in_game:
		# če stray še ni pokazan ga pokažem in dodam med pokazane
		if not strays_shown.has(stray):# and loop_count < strays_count_to_reveal:
			stray.fade_in()	
			strays_shown.append(stray)
			loop_count += 1 # šterjem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break


# TILEMAP ----------------------------------------------------------------------------------


func set_tilemap():
	
#	var tilemap_to_release: TileMap = Global.game_tilemap
	var tilemap_to_release: TileMap = default_tilemap
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	call_deferred("_free_tilemap", tilemap_to_release, tilemap_to_load_path)
	

func _free_tilemap(tilemap_to_release, tilemap_to_load_path):
	tilemap_to_release.free()
	spawn_new_tilemap(tilemap_to_load_path)


func spawn_new_tilemap(tilemap_path):

	var tilemap_resource = ResourceLoader.load(tilemap_path)
	var tilemap_parent = Global.node_creation_parent
	
	var new_tilemap = tilemap_resource.instance()
	tilemap_parent.add_child(new_tilemap) # direct child of root


# SIGNALI ----------------------------------------------------------------------------------


func _on_tilemap_completed(floor_cells_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array) -> void:
	
	# opredelim tipe pozicij
	random_spawn_positions = floor_cells_positions
	required_spawn_positions = stray_cells_positions
	player_start_positions = player_cells_positions
	
	# dodam vse pozicije v floor pozicije
	floor_positions = floor_cells_positions.duplicate() # dupliciram, da ni "praznine", ko je stray uničen
	floor_positions.append_array(required_spawn_positions)
	floor_positions.append_array(no_stray_cells_positions)
	floor_positions.append_array(player_start_positions)
	
	# start strays count setup
	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
		strays_start_count = required_spawn_positions.size()
	else:	
		strays_start_count = game_data["strays_start_count"]
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if strays_start_count > random_spawn_positions.size() + required_spawn_positions.size():
		print("to many strays to spawn: ", strays_start_count - (random_spawn_positions.size() + required_spawn_positions.size()))
		strays_start_count = random_spawn_positions.size() + required_spawn_positions.size()
		print(strays_start_count, " strays spawned")

	# opoozorim na neskladje glede št. playerjev
	if game_settings["start_players_count"] != player_start_positions.size():
		print ("player positions not in sync:", game_settings["start_players_count"] , player_start_positions.size())

	
	
	
	
