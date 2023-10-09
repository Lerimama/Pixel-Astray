extends Node


# states
var game_on: bool = false
var deathmode_active = false

# cam shake
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	
var strays_spawn_loop: int = 0	

# spawning
var player_start_position = null  # pogreba iz tajlmepa
var spawned_player_index: int = 0
var spawned_stray_index: int = 0
var players_in_game: Array = []
var strays_in_game: Array = []

var floor_positions: Array # po signalu ob kreaciji tilemapa ... tukaj, da ga lahko grebam do zunaj
var available_floor_positions: Array # dplikat floor_positions za spawnanje pixlov

var colors_to_pick: Array # za hud nejbrhud pravila
var energy_drain_active: bool = false # za kontrolo črpanja energije

# stats
onready var player_stats: Dictionary = Profiles.default_player_stats.duplicate() # duplikat default profila
onready var game_stats: Dictionary = Profiles.default_level_stats.duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var stray_pixels_count: int = Profiles.default_level_stats["stray_pixels_count"]
onready var game_rules: Dictionary = Profiles.game_rules # ker ga med ne spreminjaš

onready var spectrum_rect: TextureRect = $Spectrum
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

onready var FloatingTag = preload("res://game/hud/floating_tag.tscn")
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1") and player_stats["player_energy"] > 1:
		player_stats["player_energy"] -= 10
		player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, game_rules["player_max_energy"]) # 1 je najnižja, ker tam se že odšteva zadnji izdihljaj
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
	
	if game_rules["randomize_stray_spawning"]:
		print("rand")
		randomize()
	
	# štartej igro
	yield(get_tree().create_timer(0.1), "timeout") # blink igre, da se ziher vse naloži
	
	player_stats["player_energy"] = game_rules["player_start_energy"]
	
	set_game()
	
	
func _process(delta: float) -> void:
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)

	
# GAME LOOP --------------------------------------------------------------------------------------------------------------------------------


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
			strays_to_show_count = round(strays_in_game.size()/2)
		2: # četrtina
			strays_to_show_count = round(strays_in_game.size()/4)
		3: # osmina
			strays_to_show_count = round(strays_in_game.size()/8)
		4: # še preostale
			strays_to_show_count = strays_in_game.size() - strays_shown.size()
	
	
	# fade-in za vsak stray v igri ... med še ne pokazanimi (strays_to_show)
	var loop_count = 0
	for stray in strays_in_game:
		# če stray še ni pokazan ga pokažem in dodam me pokazane
		if not strays_shown.has(stray):# and loop_count < strays_count_to_reveal:
			stray.fade_in()	
			strays_shown.append(stray)
			loop_count += 1 # šterjem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break
					

func set_game(): 
# setam ves data igre
	
	yield(get_tree().create_timer(2), "timeout")
	
	split_stray_colors()
	spawn_player()
			
	# show strays
	yield(get_tree().create_timer(0.5), "timeout")
	show_strays() # 1 ...v metodi šteje število "klicev" ... tam se določa spawn število na vsak krog
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays() # 2 ...
	show_strays()
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays()
	
	if not players_in_game.empty():
		for player in players_in_game:
			player.visible = true
			player.set_physics_process(false)
	
	strays_spawn_loop = 0
	
	# HS za spremljat med igro
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_stats["level_no"])
	game_stats["highscore"] = current_highscore_line[0]
	game_stats["highscore_owner"] = current_highscore_line[1]
	
	yield(get_tree().create_timer(2), "timeout")
	
	Global.main_camera.zoom_in()
	# YIELD ... čaka da game_countdown odšteje
	print ("GM start - YIELD")
	# Global.game_countdown.start_countdown() ... zdej je na kameri
	yield(Global.game_countdown, "countdown_finished")	
	
	# RESUME
	print ("GM start - RESUME")
	
	start_game()

	
func start_game():
	Global.sound_manager.play_music("game")
	game_on = true
	# aktiviram plejerja in tajmer
	Global.hud.game_timer.start_timer() # tajmer pobere čas igre in tip štetja iz profila
	
#	for stray in strays_in_game: # tole je že tukaj, ker ima nakljiučne pavze in drugače predolgo traya
#		stray.current_stray_state = stray.StrayState.WANDERING
		
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(true)
	
	
func game_over(game_over_reason: String):
	
	# ustavljanje elementov igre
	game_on = false
	deathmode_active =  false
	# in-gejm keyboard inputs
	get_viewport().gui_disable_input = true
	# ustavim tajmer	
	Global.hud.game_timer.stop_timer()
	# pavziram plejerja
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(false)
	# ugasnem vse efekte, ki bi bili lahko neskončno slišni
	Global.sound_manager.stop_sfx("teleport")
	Global.sound_manager.stop_sfx("skilled")
	Global.sound_manager.stop_sfx("last_breath")
	# skrijem morebitne popupe
	Global.hud.popups.visible = false
	
	# YIELD 0 ... čaka na konec zoomoutamm
	var camera_zoomed_out = Global.main_camera.zoom_out() # hud gre ven
	
	yield(Global.main_camera, "zoomed_out")

	Global.sound_manager.stop_music("game_on_game-over")
	Global.hud.visible = false # zazih
	
	var player_points = player_stats["player_points"]
	var current_level = game_stats["level_no"]
	
	# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
	# ker kličem funkcijo v variablo more počakat, da se funkcija izvede do returna
	var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, current_level) # yielda 2 za name input je v tej funkciji
	if not score_is_ranking:
		Global.gameover_menu.fade_in(game_over_reason)																																																							
	else:
		Global.gameover_menu.fade_in_empty(game_over_reason)
	

# SPAWNANJE --------------------------------------------------------------------------------------------------------------------------------


func spawn_player():
	
	var spawn_position = player_start_position
	spawned_player_index += 1
	
	var new_player_pixel = PlayerPixel.instance()
	new_player_pixel.name = "P%s" % str(spawned_player_index)
	new_player_pixel.global_position = spawn_position # ... ne rabim snepat ker se v pixlu na redi funkciji
	new_player_pixel.visible = false
	Global.node_creation_parent.add_child(new_player_pixel)
	
	new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
	
	Global.camera_target = new_player_pixel


func split_stray_colors():
	
	# split colors
	var color_count: int = stray_pixels_count 
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
	
#	if not Profiles.game_rules["colors_collecting_mode"]:
	Global.hud.spawn_color_indicators(all_colors)				


func spawn_stray(stray_color):
	
	spawned_stray_index += 1

	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_stray_index)
	new_stray_pixel.pixel_color = stray_color
	
	# random grid pozicija
	var random_range = available_floor_positions.size()
	var selected_cell_index: int = randi() % int(random_range) # + offset
	new_stray_pixel.global_position = available_floor_positions[selected_cell_index]
	 # + grid_cell_size/2
	new_stray_pixel.z_index = 1
	
	#spawn
	Global.node_creation_parent.add_child(new_stray_pixel)
	new_stray_pixel.global_position = Global.snap_to_nearest_grid(new_stray_pixel.global_position, Global.level_tilemap.floor_cells_global_positions)
	
	# connect
	new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
	
	# odstranim uporabljeno pozicijo
	available_floor_positions.remove(selected_cell_index)
	

func spawn_floating_tag(position: Vector2, value): # kliče ga GM
	
	var cell_size_x: float = Global.level_tilemap.cell_size.x
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 2
	new_floating_tag.global_position = position - Vector2 (cell_size_x/2, cell_size_x + cell_size_x/2)
	if value < 0:
		new_floating_tag.modulate = Global.color_red
	Global.node_creation_parent.add_child(new_floating_tag)
	new_floating_tag.label.text = str(value)

	
# SIGNALI ----------------------------------------------------------------------------------


func _on_TileMap_floor_completed(floor_cells_global_positions: Array, player_start_global_position: Vector2) -> void:

	floor_positions = floor_cells_global_positions 
	available_floor_positions = floor_positions.duplicate()
	player_start_position = player_start_global_position
	
	# takoj odstranim celico rezervirano za plejerja
	if available_floor_positions.has(player_start_position):
		available_floor_positions.erase(player_start_position)
	else:
		print("ne najdem pozicije plejerja")


func _on_stat_changed(stat_owner, changed_stat, stat_change):
	
	match changed_stat:
		# from stray
		"skilled":
			if not energy_drain_active:
				energy_drain_active = true
				player_stats["player_energy"] += game_rules["skilled_energy_drain"]
				player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, game_rules["player_max_energy"]) # 1 je najnižja, ker tam se že odšteva zadnji izdihljaj
				yield(get_tree().create_timer(Profiles.game_rules["skilled_energy_drain_speed"]), "timeout")
				energy_drain_active = false
		"stray_hit":
			# hud statistika stray pixlov
			game_stats["off_pixels_count"] += 1
			game_stats["stray_pixels_count"] -= 1
			# stats za prvi pixel 
			if stat_change == 1:
				player_stats["player_points"] += game_rules["color_picked_points"]
				player_stats["player_energy"] += game_rules["color_picked_energy"]
				spawn_floating_tag(stat_owner.global_position, game_rules["color_picked_points"]) 
			# stats za vsakega naslednega v vrsti 
			elif stat_change > 1:
				var points_for_seq_pixel = (game_rules["additional_color_picked_points"] * stat_change) - game_rules["color_picked_points"] # odštejem, da se točke od prvega pixla ne podvajajo
				var energy_for_seq_pixel = (game_rules["additional_color_picked_energy"] * stat_change) - game_rules["color_picked_energy"]
				player_stats["player_points"] += points_for_seq_pixel
				player_stats["player_energy"] += energy_for_seq_pixel
				spawn_floating_tag(stat_owner.global_position, points_for_seq_pixel) 
			
			if game_stats["stray_pixels_count"] == 0:
				game_over(Global.reason_cleaned)
			
		# from player
		"wall_hit":
			if game_rules["loose_life_on"]:
				loose_life(stat_owner, stat_change)
			else:
				spawn_floating_tag(stat_owner.global_position, game_rules["wall_hit_points"]) 
				player_stats["player_points"] += game_rules["wall_hit_points"]
				player_stats["player_energy"] += game_rules["wall_hit_energy"]
				yield(get_tree().create_timer(game_rules["dead_time"]), "timeout")
				stat_owner.revive()
		"out_of_breath":
			if game_rules["loose_life_on"]:
				loose_life(stat_owner, stat_change)
			else:
				yield(get_tree().create_timer(game_rules["dead_time"]), "timeout")
				stat_owner.revive()
		"cells_travelled": 
			player_stats["cells_travelled"] += stat_change
			player_stats["player_energy"] += game_rules["cell_travelled_energy"]
			player_stats["player_points"] += game_rules["cell_travelled_points"]
		"skill_used": 
			player_stats["skill_count"] += stat_change
			player_stats["player_energy"] += game_rules["skill_used_energy"]
			player_stats["player_points"] += game_rules["skill_used_points"]
		"burst_released": 
			player_stats["burst_count"] += 1 # tukaj se kot valju poda burst power
			
	# na koncu poskrbim za klempanje
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, game_rules["player_max_energy"]) # 1 je najnižja, ker tam se že odšteva zadnji izdihljaj
	player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])	
	
		
func loose_life(life_looser, life_to_loose_amount):
	
	player_stats["player_life"] -= life_to_loose_amount
	
	# game-over, če je bil to zadnji lajf
	if player_stats["player_life"] < 1:
		game_over(Global.reason_life)
	
	else: # če mam še lajfov
		yield(get_tree().create_timer(game_rules["dead_time"]), "timeout")
		life_looser.revive()
		# resetiram energijo, če je tako določeno
		if game_rules["revive_energy_reset"]:
			# da ne znižam energije, če je višja od "star_energy" ... zazih v bistvu	
			if player_stats["player_energy"] < game_rules["player_start_energy"]: 
				player_stats["player_energy"] = game_rules["player_start_energy"]
