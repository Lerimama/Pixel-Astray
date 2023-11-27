extends Node


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
var spawned_stray_index: int = 0 
var strays_in_game: Array = [] # za spawnanje v rundah
var strays_in_game_count: int # za statistiko in GO
var strays_start_count: int

# tilemap data
var floor_positions: Array
var available_floor_positions: Array
var additional_floor_positions: Array # xtra pozicije za kombo spawn

# profiles
var p1_stats: Dictionary = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
var p2_stats: Dictionary = Profiles.default_player_stats.duplicate()
onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš

onready var spectrum_rect: TextureRect = $Spectrum
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var default_tilemap: TileMap = $"../Tilemap"
onready var FloatingTag = preload("res://game/hud/floating_tag.tscn")
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")



func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1") and p1_stats["player_energy"] > 1:
		p1_stats["player_energy"] -= 10
		p1_stats["player_energy"] = clamp(p1_stats["player_energy"], 1, game_settings["player_start_energy"])
	if Input.is_action_pressed("no2") and p2_stats["player_energy"] > 1:
		p2_stats["player_energy"] -= 10
		p2_stats["player_energy"] = clamp(p2_stats["player_energy"], 1, game_settings["player_start_energy"])
	
		
func _ready() -> void:
	
	Global.node_creation_parent = get_parent() # arena je node creation parent
	Global.game_manager = self
	
	randomize()
	
	set_tilemap()
	call_deferred("set_game") # deferamo, da se naloži tilemap
	
	
func _process(delta: float) -> void:
	
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	
	# plejer se obnaša glede na energijo in jo more skos poznat
	if p1:
		p1.player_energy = p1_stats["player_energy"]
	if p2:
		p2.player_energy = p2_stats["player_energy"]
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	# tilemap
	Global.game_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	Global.game_tilemap.get_tiles()
	
	# players
	if game_data["game"] == Profiles.Games.TUTORIAL:
#		game_settings["player_start_color"] = Global.color_white # more bit pred spawnom
		set_players()
		p1.modulate.a = 0	
	else:
#		game_settings["player_start_color"] = Global.color_white # more bit pred spawnom
		set_players() # spawn, stats, camera, target
#		for player in players_in_game:
#			player.modulate.a = 0	
	
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
	if game_settings["start_game_countdown"]:
		Global.start_countdown.start_countdown()
		yield(Global.start_countdown, "countdown_finished")	
	
	start_game()
	
	
func start_game():
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.start()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game")
		for player in players_in_game:
			player.set_physics_process(true)
#			player.animation_player.play("virgin_blink")
	
	game_on = true
	
	
func game_over(gameover_reason):
	
	# ustavljanje elementov igre
	game_on = false
	get_viewport().gui_disable_input = true	# in-gejm keyboard inputs
	Global.hud.game_timer.stop_timer() # ustavim tajmer
	Global.hud.popups.visible = false # skrijem morebitne popupe
	
	# ugasnem vse efekte, ki bi bili lahko neskončno slišni
	Global.sound_manager.stop_sfx("teleport")
	Global.sound_manager.stop_sfx("heartbeat")
	
	# pavziram plejerja
	for player in players_in_game:
		player.set_physics_process(false)
	
	# open game-over ekran
	Global.gameover_menu.show_gameover(gameover_reason)
	
	
	
# SPAWNANJE ----------------------------------------------------------------------------------


func set_tilemap():
	
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
		new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
		new_player_pixel.set_physics_process(false)
		players_in_game.append(new_player_pixel)
	
	# p1
	p1 = players_in_game[0]
	p1_stats["player_energy"] = game_settings["player_start_energy"]
	p1_stats["player_life"] = game_settings["player_start_life"]
	Global.p1_camera_target = p1 # tole gre lahko v plejerja
	p1.player_camera = Global.p1_camera
	
	# p2 
	if players_in_game.size() > 1:
		p2 = players_in_game[1]
		p2_stats["player_energy"] = game_settings["player_start_energy"]
		p2_stats["player_life"] = game_settings["player_start_life"]
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
	var loop_count = 0
	
	for color in color_count:
		var selected_color_position_x = loop_count * color_skip_size # pozicija pixla na sliki
		var current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # zajem barve na lokaciji pixla
		spawn_stray(current_color)
		all_colors.append(current_color)
		loop_count += 1
		
	Global.hud.spawn_color_indicators(all_colors)				
	strays_in_game_count = spawned_stray_index # količina je enaka zadnjemu indexu


func spawn_stray(stray_color):
	
	# ne spawnay, če ni več pozicij
	if available_floor_positions.empty():
		print ("no available floor positions")
		return
	
	spawned_stray_index += 1 # prvi stray ma že številko 1
	
	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_stray_index)
	new_stray_pixel.pixel_color = stray_color
	
	# pozicija
	var random_range = available_floor_positions.size()
	var selected_cell_index: int = randi() % int(random_range) # + offset
	new_stray_pixel.global_position = available_floor_positions[selected_cell_index] + Global.game_tilemap.cell_size/2 # dodana adaptacija zaradi središča pixla
	new_stray_pixel.z_index = 2 # višje od plejerja
	
	#spawn
	Global.node_creation_parent.add_child(new_stray_pixel)
	# new_stray_pixel.global_position = Global.snap_to_nearest_grid(new_stray_pixel.global_position, Global.game_tilemap.floor_cells_global_positions)
	
	# odstranim uporabljeno pozicijo
	available_floor_positions.remove(selected_cell_index)
	
	# "selected + random spawn" ... dodam nove "random" pozicije
	if available_floor_positions.empty() and spawned_stray_index < strays_start_count: # če sem porabil že vse pozicije, straysi pa so še na voljo za spawnanje
		for added_position in additional_floor_positions:
			available_floor_positions.append(added_position)
	

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
					

func spawn_floating_tag(position: Vector2, value): # kliče ga GM
	
	if value == 0:
		return
		
	var cell_size_x: float = Global.game_tilemap.cell_size.x
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 3 # višje od straysa in playerja
	new_floating_tag.global_position = position - Vector2 (cell_size_x/2, cell_size_x + cell_size_x/2)
	if value < 0:
		new_floating_tag.modulate = Global.color_red
	Global.node_creation_parent.add_child(new_floating_tag)
	new_floating_tag.label.text = str(value)


# SIGNALI ----------------------------------------------------------------------------------


func _on_tilemap_completed(floor_cells_global_positions: Array, stray_cells_global_positions: Array, no_stray_cells_global_positions: Array, player_start_global_positions: Array) -> void:
	
	# STRAYS
	
	# random spawn, če ni stray pozicij
	if stray_cells_global_positions.empty():
		strays_start_count = game_data["strays_start_count"]
		available_floor_positions = floor_cells_global_positions.duplicate()
	# kombo spawn, če so stray pozicije in no-stray pozicije
	elif not stray_cells_global_positions.empty() and not no_stray_cells_global_positions.empty():
		strays_start_count = game_data["strays_start_count"]
		available_floor_positions = stray_cells_global_positions.duplicate()
		additional_floor_positions = floor_cells_global_positions.duplicate()
	# selected spawn, če so samo stray pozicije
	else:
		strays_start_count = stray_cells_global_positions.size()
		available_floor_positions = stray_cells_global_positions.duplicate()
	
	# odstranim no-stray pozicije
	for no_stray_position in no_stray_cells_global_positions: 
		available_floor_positions.erase(no_stray_position)
		additional_floor_positions.erase(no_stray_position)	
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if strays_start_count > available_floor_positions.size() + additional_floor_positions.size():
		print("to many strays to spawn: ", strays_start_count - (available_floor_positions.size() + additional_floor_positions.size()))
		strays_start_count = available_floor_positions.size() + additional_floor_positions.size()
	
	# PLAYER
	
	player_start_positions = player_start_global_positions
	
	# odstranim pozicija iz tstih na voljo za strayse
	for player_start_position in player_start_positions:
		if available_floor_positions.has(player_start_position):
			available_floor_positions.erase(player_start_position)
		if additional_floor_positions.has(player_start_position):
			additional_floor_positions.erase(player_start_position)
	
	# določim mono/multiplayer game
	if game_settings["start_players_count"] != player_start_positions.size():
		print ("Player positions not in sync:", game_settings["start_players_count"] , player_start_positions.size())
	
	
func _on_stat_changed(stat_owner, changed_stat, stat_change):
	
	var player_stats: Dictionary
	var opponent_player_stats: Dictionary # za 2 player game
	
	match stat_owner.name:
		"p1": 
			player_stats = p1_stats
			opponent_player_stats = p2_stats
		"p2": 
			player_stats = p2_stats
			opponent_player_stats = p1_stats
		
	match changed_stat:
		"hit_stray": # stat_change je array
			player_stats["colors_collected"] += 1
			strays_in_game_count -= 1
			var stray_count = stat_change[0]
			var stray_global_position = stat_change[1].global_position
			# score za edini oz. za prvega v vrsti
			if stray_count == 1:
				player_stats["player_points"] += game_settings["color_picked_points"]
				player_stats["player_energy"] += game_settings["color_picked_energy"]
				spawn_floating_tag(stray_global_position, game_settings["color_picked_points"]) 
				if game_data["game"] == Profiles.Games.TUTORIAL:
					Global.tutorial_gui.finish_bursting()
			# score za vsakega naslednega v vrsti 
			elif stray_count > 1:
				# odštejem, da se točke od prvega pixla ne podvajajo
				var points_for_seq_pixel = (game_settings["stacked_color_picked_points"] * stray_count) - game_settings["color_picked_points"] 
				var energy_for_seq_pixel = (game_settings["stacked_color_picked_energy"] * stray_count) - game_settings["color_picked_energy"]
				player_stats["player_points"] += points_for_seq_pixel
				player_stats["player_energy"] += energy_for_seq_pixel
				spawn_floating_tag(stray_global_position, points_for_seq_pixel) 
				if game_data["game"] == Profiles.Games.TUTORIAL and stray_count > 2:
					Global.tutorial_gui.finish_stacking()
			# cleaned
			if strays_in_game_count == 0:
				player_stats["player_points"] += game_settings["all_cleaned_points"]
				stat_owner.pixel_color = Color.white # become white again
				game_over(GameoverReason.CLEANED)
		"hit_wall":
			if game_settings["lose_life_on_hit"]: # resetiram energijo
				lose_life(player_stats, stat_owner)
			else: # zguba polovice energije in točk
				var points_to_lose = round(player_stats["player_points"] / 2)
				var energy_to_lose = round(player_stats["player_energy"] / 2)
				player_stats["player_points"] -= points_to_lose
				player_stats["player_energy"] -= energy_to_lose
				spawn_floating_tag(stat_owner.global_position, - points_to_lose) 
				stat_owner.revive()
		"hit_player":
			player_stats["player_energy"] += game_settings["color_picked_energy"]
			player_stats["colors_collected"] += opponent_player_stats["colors_collected"]
			spawn_floating_tag(stat_owner.global_position, (+ opponent_player_stats["colors_collected"]))
			var energy_to_gain = round(opponent_player_stats["player_energy"] / 2)
			player_stats["player_energy"] += energy_to_gain
		"hit_by_player":
			spawn_floating_tag(stat_owner.global_position, - player_stats["colors_collected"])
			player_stats["colors_collected"] = 0
			if game_settings["lose_life_on_hit"]:
				lose_life(player_stats, stat_owner)
			else:
				var energy_to_lose = round(player_stats["player_energy"] / 2)
				player_stats["player_energy"] -= energy_to_lose
				stat_owner.revive()
		"out_of_energy":
			lose_life(player_stats, stat_owner)
		"cells_traveled": 
			player_stats["cells_traveled"] += stat_change
			player_stats["player_energy"] += game_settings["cell_traveled_energy"]
			player_stats["player_points"] += game_settings["cell_traveled_points"]
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
			
	# klempanje
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, game_settings["player_max_energy"]) # pri 1 se že odšteva zadnji izdihljaj
	player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])	

		
func lose_life(loser_player_stats, life_loser):
	
	loser_player_stats["player_life"] -= 1

	if loser_player_stats["player_life"] < 1: # game-over, če je bil to zadnji lajf
		game_over(GameoverReason.LIFE)
	else: # če mam še lajfov
		life_loser.revive()
		if game_settings["reset_energy_on_lose_life"]: # da ne znižam energije, če je višja od "player_max_energy" ... zazih
			loser_player_stats["player_energy"] = game_settings["player_max_energy"]
