extends Node


export var pick_neighbour_mode = false
var colors_to_pick: Array # za hud nejbrhud pravila

# states
var game_on: bool = false
var deathmode_on = false

# intro
var stray_pixels_count: int = Profiles.default_level_stats["stray_pixels_count"]
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	
var strays_spawn_loop: int = 0	
var strays_shown: Array = []

# spawning
var player_start_position: Vector2 # pogreba iz tajlmepa
var spawned_player_index: int = 0
var spawned_stray_index: int = 0
var players_in_game: Array = []
var strays_in_game: Array = []
var floor_positions: Array # po signalu ob kreaciji tilemapa ... tukaj, da ga lahko grebam do zunaj
var available_floor_positions: Array # dplikat floor_positions za spawnanje pixlov
var revive_time: float = 3 # pavza med die in revive funkcijo

onready var StrayPixel = preload("res://game/pixel/Stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/Player.tscn")
onready var spectrum_rect: TextureRect = $Spectrum
onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
onready var animated_pixel: KinematicBody2D = $"../Pixel"

# stats
onready var player_stats: Dictionary = Profiles.default_player_stats.duplicate() # duplikat default profila
onready var game_stats: Dictionary = Profiles.default_level_stats.duplicate() # duplikat default profila
onready var game_rules: Dictionary = Profiles.game_rules 
onready var FloatingTag = preload("res://game/pixel/FloatingTag.tscn")


func _unhandled_input(_event: InputEvent) -> void:

	if Input.is_action_just_pressed("r"):
#		start_game()
		printt("players_in_game", players_in_game)
		
	if Input.is_action_pressed("no1"):
		player_stats["player_energy"] -= 1
	if Input.is_action_pressed("no2"):
		player_stats["player_energy"] += 10
	if Input.is_action_pressed("no3"):
		if not players_in_game.empty():
			for player in players_in_game:
				player.die() # s te metode s spet kliče stat change "player_life"

		
func _ready() -> void:
	
	Global.game_manager = self	
	randomize()
	
	# štartej igro
	yield(get_tree().create_timer(0.1), "timeout") # blink igre, da se ziher vse naloži
#	set_game()
	play_intro()
	Global.camera_target = animated_pixel
	
	
func _process(delta: float) -> void:
	
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	

# GAME LOOP --------------------------------------------------------------------------------------------------------------------------------


func play_intro():
	
	Global.main_camera.zoom = Vector2(2, 2)
	split_stray_colors(stray_pixels_count)	
	
	# pavza pred pixelate eventom
	yield(get_tree().create_timer(2), "timeout")
	
	# spawnam strayse v več grupah
	animation_player.play("pixelate")
		
	
	return
	
#	split_stray_colors(game_stats["stray_pixels_count"])
	# -> tukaj daš fejdin efekt na strejse
	

#	plejer.animation_player.stop()	
#	plejer.animation_player.play("still_alive")	

	

func show_strays():
	
	Global.main_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	strays_spawn_loop += 1
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
					

func set_game():

	animated_pixel.queue_free()
	strays_spawn_loop = 0
	
	yield(get_tree().create_timer(1), "timeout")

	Global.main_camera.animation_player.play("intro_zoom")
#	Global.main_camera.zoom = Vector2(1, 1)
	
#	Global.game_countdown.start_countdown()
	
	
	# highscore za hud
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_stats["level_no"])
	game_stats["highscore"] = current_highscore_line[0]
	game_stats["highscore_owner"] = current_highscore_line[1]
	
	Global.hud.fade_in() # hud zna vse sam ... vseskozi je GM njegov "mentor"
	
	yield(get_tree().create_timer(1), "timeout") # ne moreš klicat start game v istem frejmu, ker potem še ne prepozna plejerja
	
	start_game()

	
func start_game():
	
	game_on = true
	Global.hud.start_timer()
	
	# aktiviram plejerja
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(true)
	else:			
		print("PLAYER = NIGA")
	
	
func game_over():
	
	# ustavim igro
	game_on = false
	deathmode_on =  false
	
	# pavziram plejerja
	if not players_in_game.empty():
		for player in players_in_game:
			player.set_physics_process(false)
	
	Global.hud.stop_timer()
	yield(get_tree().create_timer(2), "timeout")

	# YIELD 1 ... čaka na konec preverke rankinga ... če ni rankinga dobi false, če je ne dobi nič
	print ("GM - YIELD 1")
	
	var player_points = player_stats["player_points"]
	var current_level = game_stats["level_no"]
	var score_is_ranking = Global.data_manager.manage_gameover_highscores(player_points, current_level)
	
	# RESUME 1
	print ("GM - RESUME 1")

	if not score_is_ranking:
		Global.gameover_menu.fade_in()																																																							
	else:
		Global.gameover_menu.fade_in_empty()

	

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
	
	#spawn
	Global.node_creation_parent.add_child(new_player_pixel)
	
	# vzamem lokacijo za izbrisat
#	new_player_pixel.snap_to_nearest_grid()
#	if available_floor_positions.has(new_player_pixel.global_position):
#		pass
	
	# povežem
	new_player_pixel.connect("stat_changed", self, "_on_stat_changed")
	
	# aktiviram plejerja (hud mora vedet)
	player_stats["player_active"] = true

	# camera target
	Global.camera_target = new_player_pixel
	Global.main_camera.reset_camera_position()
	
	# premik kamere na štartu
	yield(get_tree().create_timer(1), "timeout")
	Global.main_camera.drag_margin_top = 0.2
	Global.main_camera.drag_margin_bottom = 0.2
	Global.main_camera.drag_margin_left = 0.3
	Global.main_camera.drag_margin_right = 0.3
	

func split_stray_colors(stray_pixels_count):
	
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
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 2
	new_floating_tag.global_position = position - Vector2 (cell_size_x/2, cell_size_x + cell_size_x/2)
	Global.node_creation_parent.add_child(new_floating_tag)
	new_floating_tag.label.text = str(value)

	
# SIGNALI ----------------------------------------------------------------------------------


func _on_FloorMap_floor_completed(floor_cells_global_positions: Array, player_start_global_position: Vector2) -> void:

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
			if player_stats["player_life"] <= 1:
				game_over()
			else:
				player_stats["player_life"] += stat_change
				stat_owner.revive()
		"cells_travelled": 
			player_stats["cells_travelled"] += stat_change
			# energija
			if player_stats["player_energy"] > 0:
				player_stats["player_energy"] += game_rules["energy_cell_travelled"]
		"skills_used": 
			player_stats["skills_used"] += stat_change
			# energija
			if player_stats["player_energy"] > 0:
				player_stats["player_energy"] += game_rules["energy_skill_used"]
		"burst_released": 
			player_stats["skills_used"] += 1 # tukaj se kot valju poda burst power
		
		# od straysa
			
		"off_pixels_count":
			game_stats["off_pixels_count"] += stat_change
			game_stats["stray_pixels_count"] -= stat_change
			# točke
			player_stats["player_points"] += game_rules["points_color_picked"]
			# energija
			player_stats["player_energy"] += game_rules["energy_color_picked"]		
			
			# points tag
#			Global.hud.spawn_tag_popup(stat_owner.global_position, game_rules["points_color_picked"]) 
			spawn_tag_popup(stat_owner.global_position, game_rules["points_color_picked"]) 
			
		
	# loose life
	
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 0, Profiles.default_player_stats["player_energy"])
	
	if player_stats["player_energy"] <= 0:
		
		# resetiram energijo ... nujno že tukaj, ker če ne se kliče ob vsaki spremembi statistike in je stack oversize error
		player_stats["player_energy"] = Profiles.default_player_stats["player_energy"]

		stat_owner.die() # s te metode s spet pošlje statistika change "player_life"
		yield(get_tree().create_timer(revive_time), "timeout")
		stat_owner.revive()

