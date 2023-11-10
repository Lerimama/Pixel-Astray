extends Node


enum GameoverReason {LIFE, TIME, CLEANED, WALL, ENERGY}
var current_gameover_reason

var game_on: bool = false
var colors_to_pick: Array # za hud nejbrhud pravila
var energy_drain_active: bool = false # za kontrolo črpanja energije

# cam shake
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	
var strays_spawn_loop: int = 0	

# spawning
var player_pixel: KinematicBody2D
var player_start_position = null  # pogreba iz tajlmepa
var spawned_player_index: int = 0
var spawned_stray_index: int = 0 
var players_in_game: Array = []
var strays_in_game: Array = [] # za spawnanje v rundah
var strays_in_game_count: int # za statistiko in GO

# tilemap signal data
var floor_positions: Array
var available_floor_positions: Array


onready var spectrum_rect: TextureRect = $Spectrum
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var default_level_tilemap: TileMap = $"../Tilemap"
onready var FloatingTag = preload("res://game/hud/floating_tag.tscn")
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")


# profiles
onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var player_settings: Dictionary = Profiles.player_settings # ga med igro ne spreminjaš
onready var player_stats: Dictionary = Profiles.default_player_stats.duplicate() # duplikat default profila, ker ga me igro spreminjaš

#onready var curr_game = Profiles.current_game
#onready var level_data: Dictionary = Profiles.default_level_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
#var curr_game = 


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1") and player_stats["player_energy"] > 1:
		player_stats["player_energy"] -= 10
		player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, player_settings["start_energy"])
	if Input.is_action_pressed("no2"):
		player_stats["player_energy"] += 10
	
	if Input.is_action_just_pressed("n"):
		if Global.sound_manager.game_music_set_to_off:
			return
		Global.sound_manager.skip_track()
	
	# music toggle
	if Input.is_action_just_pressed("m") and game_on: # tukaj damo samo na mute ... kar ni isto kot paused
		if Global.sound_manager.game_music_set_to_off:
			Global.sound_manager.game_music_set_to_off = false
			Global.sound_manager.play_music("game")
		else:
			Global.sound_manager.stop_music("game")
			Global.sound_manager.game_music_set_to_off = true

		
func _ready() -> void:
	
	Global.game_manager = self	
	randomize()
	
	# nafilam player stats po pravilih igre
	player_stats["player_energy"] = player_settings["start_energy"]
	player_stats["player_life"] = player_settings["start_life"]
	
	# temp ... na koncu malo drugače
	if game_data["game"] == Profiles.Games.TUTORIAL:
		set_tilemap()
#	set_tilemap()
	call_deferred("set_game") # deferamo, da se naloži tilemap
	
	
func _process(delta: float) -> void:
	
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	# tilemap
	Global.level_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	Global.level_tilemap.get_tiles()
	
	# player
	if game_data["game"] == Profiles.Games.TUTORIAL:
		player_settings["start_color"] = Global.color_white # more bit pred spawnom
		player_pixel = spawn_player()
		player_pixel.modulate.a = 0	
	else:
		player_pixel = spawn_player()
	player_stats["player_energy"] = player_settings["start_energy"]
	Global.camera_target = player_pixel
	
	yield(get_tree().create_timer(3), "timeout") # da se ekran prikaže
	
	# strays
	if game_data["game"] != Profiles.Games.TUTORIAL: 
		generate_strays()
		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda
		
	# hud HS
	if game_data["game"] != Profiles.Games.PRACTICE and game_data["game"] != Profiles.Games.TUTORIAL:
		var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_data["game"])
		game_data["highscore"] = current_highscore_line[0]
		game_data["highscore_owner"] = current_highscore_line[1]
	
	# zoom
	Global.main_camera.zoom_in()
	yield(Global.main_camera, "zoomed_in")
	
	# countdown
	if game_data["game"] != Profiles.Games.TUTORIAL:
		if Global.game_manager.game_settings["start_countdown_on"]:
			Global.start_countdown.start_countdown()
			yield(Global.start_countdown, "countdown_finished")	
	
	start_game()
	
	
func start_game():

	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.start() # enable panels
	else:
		player_pixel.set_physics_process(true)
		Global.hud.game_timer.start_timer() # skrit je v hudu
		Global.sound_manager.play_music("game")
	
	game_on = true
	
	
func game_over():
	
	# ustavljanje elementov igre
	game_on = false
	get_viewport().gui_disable_input = true	# in-gejm keyboard inputs
	Global.hud.game_timer.stop_timer() # ustavim tajmer
	Global.hud.popups.visible = false # skrijem morebitne popupe
	
	# ugasnem vse efekte, ki bi bili lahko neskončno slišni
	Global.sound_manager.stop_sfx("teleport")
	Global.sound_manager.stop_sfx("skilled")
	Global.sound_manager.stop_sfx("last_breath")
	
	# pavziram plejerja
	player_pixel.set_physics_process(false)
	
	# malo časa za show-off
	yield(get_tree().create_timer(2), "timeout")
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.animation_player.play("tutorial_end")
	
	# YIELD 0 ... čaka na konec zoomoutam
	var camera_zoomed_out = Global.main_camera.zoom_out() # hud gre ven
	yield(Global.main_camera, "zoomed_out")

	Global.sound_manager.stop_music("game_on_game-over")
	Global.hud.visible = false # zazih
	
	var player_points = player_stats["player_points"]
	
	# Gameover fejdin
	if game_data["game"] == Profiles.Games.TUTORIAL or game_data["game"] == Profiles.Games.PRACTICE:
		Global.gameover_menu.fade_in_new()
	else:
		# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
		var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, game_data["game"]) # yielda 2 za name_input je v tej funkciji
		if not score_is_ranking:
			Global.gameover_menu.fade_in_new()																																																							
		else:
			Global.gameover_menu.fade_in_highscore()
	
			
#	var current_level = game_data["level"]
#	if game_data["level"] == Profiles.Games.TUTORIAL:
#		Global.gameover_menu.fade_in_tutorial()
#	elif game_data["level"] == Profiles.Games.PRACTICE:
#		Global.gameover_menu.fade_in_practice()
#	else:
#		# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
#		var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, current_level) # yielda 2 za name_input je v tej funkciji
#		if not score_is_ranking:
#			Global.gameover_menu.fade_in()																																																							
#		else:
#			Global.gameover_menu.fade_in_highscore()
	
	# HS manage
#	if game_data["level"] != Profiles.Games.PRACTICE or game_data["level"] != Profiles.Games.TUTORIAL:
#		# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
#		# ker kličem funkcijo v variablo more počakat, da se funkcija izvede do returna
#		var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, current_level) # yielda 2 za name_input je v tej funkciji
#		if not score_is_ranking:
#			Global.gameover_menu.fade_in(game_over_reason)																																																							
#		else:
#			Global.gameover_menu.fade_in_empty(game_over_reason)
#	else:
#			Global.gameover_menu.fade_in_practice(game_over_reason)
	
	
# SPAWNANJE ----------------------------------------------------------------------------------


func set_tilemap():
	
	var tilemap_to_release: TileMap = default_level_tilemap
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
		

func spawn_player():
	
	var spawn_position = player_start_position
	spawned_player_index += 1
	
	var new_player_pixel = PlayerPixel.instance()
	new_player_pixel.name = "P%s" % str(spawned_player_index)
	new_player_pixel.global_position = spawn_position # ... ne rabim snepat ker se v pixlu na ready funkciji
	new_player_pixel.pixel_color = player_settings["start_color"]
	new_player_pixel.z_index = 2 # višje od straysa
	Global.node_creation_parent.add_child(new_player_pixel)
	
	new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
	new_player_pixel.set_physics_process(false)
	
	return new_player_pixel


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
	var color_count: int = game_data["strays_start_count"] 
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
	var loop_count = 0
	for color in color_count:
		
		# pozicija pixla na sliki
		var selected_color_position_x = loop_count * color_skip_size
		
		# zajem barve na lokaciji pixla
		var current_color = spectrum_image.get_pixel(selected_color_position_x, 0)
		spawn_stray(current_color)
		all_colors.append(current_color)
		
		loop_count += 1		
	
	Global.hud.spawn_color_indicators(all_colors)				
	strays_in_game_count = spawned_stray_index # količina je enaka zadnjemu indexu


func spawn_stray(stray_color):
	
	# ne spawnay, če ni več pozicij
	if available_floor_positions.empty():
		return
	
	spawned_stray_index += 1

	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_stray_index)
	new_stray_pixel.pixel_color = stray_color
	
	# random grid pozicija
	var random_range = available_floor_positions.size()
	var selected_cell_index: int = randi() % int(random_range) # + offset
	new_stray_pixel.global_position = available_floor_positions[selected_cell_index] # + grid_cell_size/2
	new_stray_pixel.z_index = 1
	
	#spawn
	Global.node_creation_parent.add_child(new_stray_pixel)
	new_stray_pixel.global_position = Global.snap_to_nearest_grid(new_stray_pixel.global_position, Global.level_tilemap.floor_cells_global_positions)
	
	# connect
	new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
	
	# odstranim uporabljeno pozicijo
	available_floor_positions.remove(selected_cell_index)
	

func show_strays():
	
	Global.main_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	
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
					

func spawn_floating_tag(position: Vector2, value): # kliče ga GM
	
	if value == 0:
		return
		
	var cell_size_x: float = Global.level_tilemap.cell_size.x
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 3 # višje od straysa in playerja
	new_floating_tag.global_position = position - Vector2 (cell_size_x/2, cell_size_x + cell_size_x/2)
	if value < 0:
		new_floating_tag.modulate = Global.color_red
	Global.node_creation_parent.add_child(new_floating_tag)
	new_floating_tag.label.text = str(value)


# SIGNALI ----------------------------------------------------------------------------------


func _on_tilemap_completed(floor_cells_global_positions: Array, stray_cells_global_positions: Array, no_stray_cells_global_positions: Array, player_start_global_position: Vector2) -> void:
	
	# strays
	if stray_cells_global_positions.empty(): # če ni stray pozicij
		available_floor_positions = floor_cells_global_positions.duplicate()
		# odstranim "no stray" pozicije ... ne dela ... :(
		# available_floor_positions.erase(no_stray_cells_global_positions)
	else: # če so stray pozicije
		game_data["strays_start_count"] = stray_cells_global_positions.size()
		available_floor_positions = stray_cells_global_positions.duplicate()
	
	# player
	player_start_position = player_start_global_position
	if available_floor_positions.has(player_start_position): # takoj odstranim celico rezervirano za plejerja
		available_floor_positions.erase(player_start_position)


func _on_stat_changed(stat_owner, changed_stat, stat_change):
	
#	if game_data["level"] == Profiles.Games.TUTORIAL:	
#		on_tutorial_stat_changed(stat_owner, changed_stat, stat_change)
#		return
		
	match changed_stat:
		# from stray
		"skilled":
			if not energy_drain_active:
				energy_drain_active = true
				player_stats["player_energy"] += game_settings["skilled_energy_drain"]
				# 1 je najnižja, ker tam se že odšteva zadnji izdihljaj
				player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, player_settings["start_energy"]) 
				
				yield(get_tree().create_timer(game_settings["skilled_energy_drain_speed"]), "timeout")
				energy_drain_active = false
								
		"stray_hit":
			player_stats["colors_collected"] += 1
			strays_in_game_count -= 1
			
			# score za edini oz. za prvega v vrsti
			if stat_change == 1:
				player_stats["player_points"] += game_settings["color_picked_points"]
				player_stats["player_energy"] += game_settings["color_picked_energy"]
				spawn_floating_tag(stat_owner.global_position, game_settings["color_picked_points"]) 
				
				if game_data["game"] == Profiles.Games.TUTORIAL:
					Global.tutorial_gui.finish_bursting()
			# score za vsakega naslednega v vrsti 
			elif stat_change > 1:
				# odštejem, da se točke od prvega pixla ne podvajajo
				var points_for_seq_pixel = (game_settings["stacked_color_picked_points"] * stat_change) - game_settings["color_picked_points"] 
				var energy_for_seq_pixel = (game_settings["stacked_color_picked_energy"] * stat_change) - game_settings["color_picked_energy"]
				player_stats["player_points"] += points_for_seq_pixel
				player_stats["player_energy"] += energy_for_seq_pixel
				spawn_floating_tag(stat_owner.global_position, points_for_seq_pixel) 
				if game_data["game"] == Profiles.Games.TUTORIAL and stat_change > 2:
					Global.tutorial_gui.finish_stacking()
			# cleaned
			if strays_in_game_count == 0:
				player_stats["player_points"] += game_settings["all_cleaned_points"]
				# become white again
				player_pixel.pixel_color = Color.white
				current_gameover_reason = GameoverReason.CLEANED
				game_over()
		# from player
		"wall_hit":
			if game_settings["lose_life_on_wall"]:
				lose_life(stat_owner, stat_change)
			else: # zguba polovice energije in točk
				var half_player_points = round(player_stats["player_points"] / 2)
				var half_player_energy = round(player_stats["player_energy"] / 2)
				player_stats["player_points"] -= half_player_points
				player_stats["player_energy"] -= half_player_energy
				spawn_floating_tag(stat_owner.global_position, - half_player_points) 
				stat_owner.revive()
		"out_of_breath":
			lose_life(stat_owner, stat_change)
		"cells_travelled": 
			player_stats["cells_travelled"] += stat_change
			player_stats["player_energy"] += game_settings["cell_travelled_energy"]
			player_stats["player_points"] += game_settings["cell_travelled_points"]
		"skill_used": # stat_change uporabim za prepoznavanje skilla ... 0 = push, 1 = pull, 2 = teleport
			player_stats["skill_count"] += 1
			player_stats["player_energy"] += game_settings["skill_used_energy"]
			player_stats["player_points"] += game_settings["skill_used_points"]
			if game_data["game"] == Profiles.Games.TUTORIAL:
				match stat_change:
					0:
						Global.tutorial_gui.push_done()
					1:
						Global.tutorial_gui.pull_done()
					2:
						Global.tutorial_gui.teleport_done()			
		"burst_released": 
			player_stats["burst_count"] += 1 # tukaj se kot valju poda burst power
			
	# na koncu koraka poskrbim za klempanje ... 1 je najnižja, ker tam se že odšteva zadnji izdihljaj
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, player_settings["start_energy"]) 
	player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])	

		
func lose_life(life_loser, life_to_lose_amount):
	
	player_stats["player_life"] -= life_to_lose_amount
	

	if player_stats["player_life"] < 1: # game-over, če je bil to zadnji lajf
		current_gameover_reason = GameoverReason.LIFE
		game_over()
	else: # če mam še lajfov
		life_loser.revive()
		# resetiram energijo
		if player_stats["player_energy"] < player_settings["start_energy"]: # da ne znižam energije, če je višja od "start_energy" ... zazih
			player_stats["player_energy"] = player_settings["start_energy"]
