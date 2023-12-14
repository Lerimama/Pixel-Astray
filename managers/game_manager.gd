extends Node


signal all_strays_cleaned # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
#var colors_to_pick: Array # za hud nejbrhud pravila
#var energy_drain_active: bool = false # za kontrolo črpanja energije

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var players_count: int

# strays
var strays_start_count: int # opredeli se on_tilemap_completed
var strays_in_game: Array = []
var strays_shown: Array = []

# tilemap data
var floor_positions: Array
var random_spawn_positions: Array
var required_spawn_positions: Array

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var spectrum_rect: TextureRect = $Spectrum
onready var StrayPixel = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel = preload("res://game/pixel/player.tscn")


func _ready() -> void:
	
	Global.game_manager = self
	randomize()

	
func _process(delta: float) -> void:
	
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	
	if strays_in_game.size() == 0 and game_on:
		game_over(GameoverReason.CLEANED)
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	set_players()

	if game_data["game"] != Profiles.Games.TUTORIAL: 
		set_strays()
		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda

	Global.hud.slide_in(players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	
	start_game()
	
	
func start_game():
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.open_tutorial()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game_music")
		
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.set_physics_process(true)
#			player.animation_player.play("virgin_blink")
			player.pixel_color = Color.white
			
		game_on = true
	
	
func game_over(gameover_reason):
	
	if game_on == false: # preprečim double gameover
		return
	
	game_on = false
	
	stop_game_elements()
	
	if gameover_reason == GameoverReason.CLEANED:
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.animation_player.play("become_white_again")
			signaling_player = player
		yield(signaling_player, "stat_changed") # počakam, da poda vse točke
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	
	var tilemap_to_release: TileMap = Global.game_tilemap # trenutno naložen v areni
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	tilemap_to_release.free()
	
	# spawn new tilemap
	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
	var new_game_tilemap = GameTilemap.instance()
	Global.node_creation_parent.add_child(new_game_tilemap) # direct child of root
	
	# povežem s signalom	
	Global.game_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	
	# grab tilemap tiles
	Global.game_tilemap.get_tiles()


func set_game_view():
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"
	
	var cell_align_start: Vector2 = Vector2(Global.game_tilemap.cell_size.x, Global.game_tilemap.cell_size.y/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start
	
	if players_count == 2:
		viewport_container_2.visible = true
		viewport_2.world_2d = viewport_1.world_2d
		Global.player2_camera.position = player_start_positions[1] + cell_align_start
	else:
		viewport_container_2.visible = false
		viewport_separator.visible = false
	
	# set player camer limits
	var tilemap_edge = Global.game_tilemap.get_used_rect()
	var tilemap_cell_size = Global.game_tilemap.cell_size
	
	# minimap
	var minimap_container: ViewportContainer = $"../Minimap"
	var minimap_viewport: Viewport = $"../Minimap/MinimapViewport"
	var minimap_camera: Camera2D = $"../Minimap/MinimapViewport/MinimapCam"	
	if Global.game_manager.game_settings["minimap_on"]:
		minimap_container.visible = true
		minimap_viewport.world_2d = viewport_1.world_2d
		minimap_viewport.size.y = minimap_viewport.size.x * tilemap_edge.size.y / tilemap_edge.size.x # višina minimape v razmerju s formatom tilemapa
		minimap_camera.set_camera(tilemap_edge, tilemap_cell_size, minimap_viewport.size)
	else:
		minimap_container.visible = false
	
	
func set_players():
	
#	game_settings["player_start_color"] = Color.purple
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Global.game_tilemap.cell_size/2 # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.pixel_color = game_settings["player_start_color"]
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# stats
		new_player_pixel.player_stats = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
		new_player_pixel.player_stats["player_energy"] = game_settings["player_start_energy"]
		new_player_pixel.player_stats["player_life"] = game_settings["player_start_life"]
		
		# povežem s hudom
		new_player_pixel.connect("stat_changed", Global.hud, "_on_stat_changed")
		new_player_pixel.emit_signal("stat_changed", new_player_pixel, new_player_pixel.player_stats) # štartno statistiko tako javim 
		
		# pregame setup
		# new_player_pixel.modulate.a = 0
		new_player_pixel.set_physics_process(false)
		
		# players camera
		if spawned_player_index == 1:
			new_player_pixel.player_camera = Global.player1_camera
			new_player_pixel.player_camera.camera_target = new_player_pixel
			
			
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
			new_player_pixel.player_camera.camera_target = new_player_pixel
		
		
func set_strays():
	
	split_stray_colors()
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int
	while strays_shown != strays_in_game:
		show_strays_loop += 1 # zazih
		show_strays(show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout")
	
	
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
#		print ("current_color p: ", current_color)
#		current_color.a = 1.1
		all_colors.append(current_color)
#		print ("current_color a: ", current_color)
		# spawn stray 
		spawn_stray(current_color, spawned_stray_index)
		spawned_stray_index += 1
		
	Global.hud.spawn_color_indicators(all_colors)				
	

func spawn_stray(stray_color: Color, stray_index: int):
	
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
	new_stray_pixel.stray_color = stray_color
	new_stray_pixel.global_position = available_positions[selected_cell_index] + Global.game_tilemap.cell_size/2 # dodana adaptacija zaradi središča pixla
	new_stray_pixel.z_index = 2 # višje od plejerja
	Global.node_creation_parent.add_child(new_stray_pixel)
	
	# odstranim uporabljeno pozicijo
	available_positions.remove(selected_cell_index) # ker ni duplikat, se briše iz array baze
	

func show_strays(show_strays_loop: int):

	var spawn_shake_power: float = 0.30
	var spawn_shake_time: float = 0.7
	var spawn_shake_decay: float = 0.2		
	get_tree().call_group(Global.group_player_cameras, "shake_camera", spawn_shake_power, spawn_shake_time, spawn_shake_decay)
		
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	match show_strays_loop:
		1:
			Global.sound_manager.play_sfx("thunder_strike")
			# Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game.size()/10)
		2:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game.size()/8)
		3:
			strays_to_show_count = round(strays_in_game.size()/4)
		4:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game.size()/2)
		5: # še preostale
			strays_to_show_count = strays_in_game.size() - strays_shown.size()
	
	# stray fade-in
	var loop_count = 0
	for stray in strays_in_game:
		if not strays_shown.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			stray.fade_in()	
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break
	

func stop_game_elements():
	
	Global.hud.game_timer.stop_timer()
	Global.hud.popups.visible = false # zazih
	Global.sound_manager.stop_sfx("teleport") # zazih
	Global.sound_manager.stop_sfx("heartbeat") # zazih
	Global.sound_manager.stop_music("game_music")	
	

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
		strays_start_count = game_data["strays_start_count"] # podatek mora bit znan pred ukazom s tilemapa, da ga tilemap povozi
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if strays_start_count > random_spawn_positions.size() + required_spawn_positions.size():
		# printt("to many strays to spawn:", strays_start_count - (random_spawn_positions.size() + required_spawn_positions.size()))
		strays_start_count = random_spawn_positions.size()/2 + required_spawn_positions.size()
		# printt(strays_start_count, " strays spawned")

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range)
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
		# printt ("player position missing. Random position added. ", player_start_positions)
	
	players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
