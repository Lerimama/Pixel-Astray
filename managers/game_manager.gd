extends Node


#export var pick_neighbour_mode = false
export var can_skip_intro: bool # čas ko lahko skipneš intro ... exportan, ker je tajmiran v animaciji in skip funkciji

var dead_time: float = 3 # pavza med die in revive funkcijo
var colors_to_pick: Array # za hud nejbrhud pravila

# states
var game_on: bool = false
var deathmode_active = false

# intro
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	
var strays_spawn_loop: int = 0	
var strays_shown: Array = []

# spawning
var player_start_position = null  # pogreba iz tajlmepa
var spawned_player_index: int = 0
var spawned_stray_index: int = 0
var players_in_game: Array = []
var strays_in_game: Array = []
var floor_positions: Array # po signalu ob kreaciji tilemapa ... tukaj, da ga lahko grebam do zunaj
var available_floor_positions: Array # dplikat floor_positions za spawnanje pixlov

# stats
onready var player_stats: Dictionary = Profiles.default_player_stats.duplicate() # duplikat default profila
onready var game_stats: Dictionary = Profiles.default_level_stats.duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var stray_pixels_count: int = Profiles.default_level_stats["stray_pixels_count"]
onready var game_rules: Dictionary = Profiles.game_rules # ker ga med ne spreminjaš
onready var pick_neighbour_mode = game_rules["pick_neighbour_mode"]



onready var spectrum_rect: TextureRect = $Spectrum
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var actor_pixel: KinematicBody2D = $"../Actor"

onready var FloatingPoints = preload("res://game/pixel/floating_points.tscn")
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("r"):
#		start_game()
		printt("players_in_game", players_in_game)
		
	if Input.is_action_pressed("no1") and player_stats["player_energy"] > 1:
		player_stats["player_energy"] -= 1
	if Input.is_action_pressed("no2"):
		player_stats["player_energy"] += 10
	if Input.is_action_pressed("no3"):
		if not players_in_game.empty():
			for player in players_in_game:
				player.die() # s te metode s spet kliče stat change "player_life"
	
	if can_skip_intro: # tajmiran v animaciji in skip funkciji
		if event is InputEventKey:
#			if event.pressed and event.scancode == KEY_ESCAPE:
			if Input.is_action_just_pressed("ui_cancel"):
				skip_intro()
				
		
func _ready() -> void:
	
	Global.game_manager = self	
	randomize()
	
	# štartej igro
	yield(get_tree().create_timer(0.1), "timeout") # blink igre, da se ziher vse naloži

#	play_intro()
	skip_intro() # še countdown
	
	
func _process(delta: float) -> void:
	
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	

# GAME LOOP --------------------------------------------------------------------------------------------------------------------------------



func skip_intro(): # spawnanje, ki bi se drugače zgodilo v intro animaciji
	
	animation_player.stop()
	can_skip_intro = false
	
	# za intro animacijo?
	#onready var floor_cover: ColorRect = $"../Level/FloorCover"
	# _temp ... ugasnjeno pred izbrisom
	# floor_cover.color = Color("00ffffff")
		
	split_stray_colors() 
	spawn_player()
	yield(get_tree().create_timer(2), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.2), "timeout")
	show_strays()
	
	set_game()	


func play_intro():
	
	# pavza pred pixelate eventom
	yield(get_tree().create_timer(2), "timeout")
	
	animation_player.play("game_intro")
	# v animaciji spawnam strayse v več grupah, pljerja in zaženem set_game()


func show_strays():
	
	Global.main_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	strays_spawn_loop += 1
	if strays_spawn_loop > 4:
		return
	
	match strays_spawn_loop:
		1: # polovica
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
	print("shown strays: ", strays_shown.size())	
					

func set_game(): # setam ves data igre

	if not players_in_game.empty():
		for player in players_in_game:
			player.visible = true
			player.set_physics_process(false)
	
	actor_pixel.queue_free()
	
	strays_spawn_loop = 0
	
	# HS za spremljat med igro
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_stats["level_no"])
	game_stats["highscore"] = current_highscore_line[0]
	game_stats["highscore_owner"] = current_highscore_line[1]
	
	Global.main_camera.zoom_in()
	# YIELD ... čaka da game_countdown odšteje
	print ("GM start - YIELD")
	# Global.game_countdown.start_countdown() ... zdej je na kameri
	yield(Global.game_countdown, "countdown_finished")	
	
	# RESUME
	print ("GM start - RESUME")
	
	start_game()

	
func start_game(): # goli štart
	
	Global.sound_manager.play_music("game")
	
	game_on = true
	
	# aktiviram plejerja in tajmer
#	Global.hud.game_timer.start_timer(Profiles.default_level_stats["game_time_limit"])
	Global.hud.game_timer.start_timer() # tajmer pobere čas igre in tip štetja iz profila
	
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(true)
	
	
func game_over(game_over_reason: String):

	# ustavim igro
	game_on = false
	deathmode_active =  false
	
	# ustavim tajmer	
	Global.hud.game_timer.stop_timer()
	
	# pavziram plejerja
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(false)
	
	# YIELD 0 ... čaka na konec zoomoutamm
	print ("GM gameover - YIELD 0")
	var camera_zoomed_out = Global.main_camera.zoom_out() # hud gre ven
	
	yield(Global.main_camera, "zoomed_out")
	print ("GM gameover - RESUME 0")

	Global.sound_manager.stop_music("game_fade")
	Global.hud.visible = false # zazih
	
	var player_points = player_stats["player_points"]
	var current_level = game_stats["level_no"]
	
	# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
	print ("GM gameover - YIELD 1")
	# ker kličem funkcijo v variablo more počakat, da se funkcija izvede do returna
	var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, current_level) # yielda 2 za name input je v tej funkciji
	print ("GM gameover - RESUME 1")
	
	if not score_is_ranking:
		Global.gameover_menu.fade_in(game_over_reason)																																																							
	else:
		Global.gameover_menu.fade_in_empty(game_over_reason)

	

# SPAWNANJE --------------------------------------------------------------------------------------------------------------------------------


func spawn_player():
#func spawn_player(spawn_position):
	
	var spawn_position = player_start_position
	spawned_player_index += 1
	
	# instance
	var new_player_pixel = PlayerPixel.instance()
	new_player_pixel.name = "P%s" % str(spawned_player_index)
	new_player_pixel.pixel_color = Global.color_white
	new_player_pixel.global_position = spawn_position # + grid_cell_size/2 ... ne rabim snepat ker se v pixlu na redi funkciji
	new_player_pixel.visible = false
	
	#spawn
	Global.node_creation_parent.add_child(new_player_pixel)
	
	# vzamem lokacijo za izbrisat
#	new_player_pixel.snap_to_nearest_grid()
#	if available_floor_positions.has(new_player_pixel.global_position):
#		pass
	
	# povežem
	new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
	
	# aktiviram plejerja in mu dodelim energijo
#	player_stats["player_active"] = true
#	player_stats["player_energy"] = game_stats["player_start_energy"]
	
	# camera target
	Global.camera_target = new_player_pixel
#	Global.main_camera.reset_camera_position() ... pozicijo raje setam na kameri ob njenem rojstvu
	
	
	# premik kamere na štartu
	yield(get_tree().create_timer(1), "timeout")


func split_stray_colors():
#func split_stray_colors(strays_count):
	
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
		
	Global.hud.spawn_color_indicators(all_colors)				


func spawn_stray(stray_color):
	
	spawned_stray_index += 1

	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_player_index)
	new_stray_pixel.pixel_color = stray_color
	
	# random grid pozicija
	var random_range = available_floor_positions.size()
	var selected_cell_index: int = randi() % int(random_range) # + offset
	new_stray_pixel.global_position = available_floor_positions[selected_cell_index] # + grid_cell_size/2
	new_stray_pixel.z_index = 1
	
	#spawn
	Global.node_creation_parent.add_child(new_stray_pixel)
	
	# connect
	new_stray_pixel.connect("stat_changed", self, "_on_stat_changed")			
	
	# odstranim uporabljeno pozicijo
	available_floor_positions.remove(selected_cell_index)
	

func spawn_tag_popup(position: Vector2, value): # kliče ga GM
	
	var cell_size_x: float = Global.level_tilemap.cell_size.x
	
	var new_floating_points = FloatingPoints.instance()
	new_floating_points.z_index = 2
	new_floating_points.global_position = position - Vector2 (cell_size_x/2, cell_size_x + cell_size_x/2)
	Global.node_creation_parent.add_child(new_floating_points)
	new_floating_points.label.text = str(value)

	
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
	# stat_change ima predznak (s pixla ali s def profila) ... tukaj je vse +, če je sprememba -1, se tukaj zgodi -1
		
		# od playerja
		"player_life": 
			player_stats["player_life"] += stat_change
			
			# energija ob izgubi lajfa na tired nivo
			var tired_energy = Profiles.default_player_stats["player_energy"] * Profiles.game_rules["tired_energy_level"]
			player_stats["player_energy"] = 0
			
			if player_stats["player_life"] < 1:
				yield(get_tree().create_timer(dead_time), "timeout")
#				game_over(Global.game_over_reason_life)
				game_over("player died")
			else:
				yield(get_tree().create_timer(dead_time), "timeout")
				# resetiram energijo ... če je loose lajf, ker je bila porabljena
				player_stats["player_energy"] = Profiles.default_player_stats["player_energy"]
				stat_owner.revive()
				
		"cells_travelled": 
			player_stats["cells_travelled"] += stat_change
			# energija
			if Profiles.game_rules["energy_speed_mode"]:
				if player_stats["player_energy"] > 0:
					player_stats["player_energy"] += game_rules["cell_travelled_energy"]
		"skills_used": 
			player_stats["skills_used"] += stat_change
			# energija
			if player_stats["player_energy"] > 0:
				player_stats["player_energy"] += game_rules["skill_used_energy"]
		"burst_released": 
			player_stats["skills_used"] += 1 # tukaj se kot valju poda burst power
		
		# signal od ubitega stray pixla (1)
		"off_pixels_count":
			printt("STAT CHANGE", stat_change)
			# statistika še ostalih pixlov
			game_stats["off_pixels_count"] += stat_change
			game_stats["stray_pixels_count"] -= stat_change
			
			# točke, energija in floating prikaz za prvi pixel 
			if stat_change == 1:
				player_stats["player_points"] += game_rules["color_picked_points"]
				player_stats["player_energy"] += game_rules["color_picked_energy"]
				spawn_tag_popup(stat_owner.global_position, game_rules["color_picked_points"]) 
			
			# točke, energija in floating prikaz za vsakega naslednega v vrsti 
			elif stat_change > 1:
				var points_for_seq_pixel = (game_rules["additional_color_picked_points"] * stat_change) - game_rules["color_picked_points"] # odštejem, da se točke od prvega pixla ne podvajajo
				var energy_for_seq_pixel = (game_rules["additional_color_picked_energy"] * stat_change) - game_rules["color_picked_energy"]
				player_stats["player_points"] += points_for_seq_pixel
				player_stats["player_energy"] += energy_for_seq_pixel
				spawn_tag_popup(stat_owner.global_position, points_for_seq_pixel) 
			
			# points tag
#			Global.hud.spawn_tag_popup(stat_owner.global_position, game_rules["color_picked_points"]) 
#			spawn_tag_popup(stat_owner.global_position, game_rules["color_picked_points"] * stat_change) 
			
			
		
	# loose life 
#	 ne vpliva v trenutnem formatu
#	player_stats["player_energy"] = clamp(player_stats["player_energy"], 0, Profiles.default_player_stats["player_energy"])
#	if player_stats["player_energy"] <= 0:
#		stat_owner.die() # s te metode s spet pošlje statistika change "player_life"

	pass
