extends Node
class_name GameManager # default game manager


signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var show_position_indicators: bool = false # na začetku jih ne rabim gledat

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var start_players_count: int

# strays
var strays_shown: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int = 0 # za statistiko na hudu
var all_strays_died_alowed: bool = false # za omejevanje signala iz FP ... kdaj lahko reagira na 0 straysov v igri
var all_stray_colors: Array # barve na štartnem spawnu (site kot v spektrumu)
var available_respawn_positions: Array # pozicije na voljo, ki se apdejtajo na vsak stray in player spawn ali usmrtitev 
var dont_turn_to_wall_positions: Array # za zaščito, da wall stray ne postane wall (ob robu igre recimo)

# tilemap data
var cell_size_x: int # napolne se na koncu setanju tilemapa
var random_spawn_positions: Array
var required_spawn_positions: Array
var goal_stray_positions: Array

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var start_strays_spawn_count: int = game_settings["strays_start_count"] # število se lahko popravi iz tilempa signala
onready var StrayPixel: PackedScene = preload("res://game/pixel/stray.tscn")
onready var PlayerPixel: PackedScene = preload("res://game/pixel/player_cleaning.tscn")


func _ready() -> void:
	
	Global.game_manager = self
	randomize()

	
func _process(delta: float) -> void:
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
		all_strays_died_alowed = false
		emit_signal("all_strays_died")
	
	# position indicators
	if game_on:
		if available_respawn_positions.empty():
			game_over(GameoverReason.TIME)	
		available_respawn_positions = Global.current_tilemap.floor_global_positions.duplicate()
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if available_respawn_positions.has(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
				available_respawn_positions.erase(stray.global_position - Vector2(cell_size_x/2, cell_size_x/2) )
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if available_respawn_positions.has(player.global_position - Vector2(cell_size_x/2, cell_size_x/2)):
				available_respawn_positions.erase(player.global_position - Vector2(cell_size_x/2, cell_size_x/2) )
		
		if Global.strays_on_screen.size() <= game_settings["show_position_indicators_stray_count"] and game_settings["position_indicators_on"]:
			show_position_indicators = true
		else:
			show_position_indicators = false
	else:
		show_position_indicators = false

	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	# kliče main.gd pred prikazom igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	# player intro animacija

	
	if game_data["game"] == Profiles.Games.TUTORIAL: 
		yield(get_tree().create_timer(1), "timeout") # da se animacija plejerja konča	
		# tutorial funkcijo prikaza plejerja izpelje v svoji kodi
	else:
		
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.animation_player.play("lose_white_on_start")
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
		
		yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
		
		set_strays()
		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda	
	
	Global.hud.slide_in(start_players_count)
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
			
		game_on = true

	
func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if gameover_reason == GameoverReason.CLEANED:
		all_strays_died_alowed = true
		yield(self, "all_strays_died")
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.all_cleaned()
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	stop_game_elements()
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	tilemap_to_release.free()
	
	# spawn new tilemap
	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
	var new_tilemap = GameTilemap.instance()
	Global.node_creation_parent.add_child(new_tilemap) # direct child of root
	
	# povežem s signalom	
	Global.current_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	
	# grab tilemap tiles
	Global.current_tilemap.get_tiles()
	cell_size_x = Global.current_tilemap.cell_size.x 

	
func set_game_view():
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"
	
	# pre-zoom pozicija kamere
	#	var tilemap_center: Vector2 = Vector2(Global.current_tilemap.get_used_rect().size.x, Global.current_tilemap.get_used_rect().size.y) * cell_size_x / 2 
	#	tilemap_center = Vector2(2200, Global.current_tilemap.get_used_rect().size.y) * cell_size_x / 2 
	#	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	#
	#	if game_data["game"] == Profiles.Games.ENIGMA:	
	#		Global.player1_camera.position = tilemap_center
	#		printt ("P", tilemap_center, Global.player1_camera.position, player_start_positions[0] )
	#	else:	
	#		Global.player1_camera.position = player_start_positions[0] + cell_align_start


#	if start_players_count == 2:
#		viewport_container_2.visible = true
#		viewport_2.world_2d = viewport_1.world_2d
#	else:
	viewport_container_2.visible = false
	viewport_separator.visible = false
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	get_tree().call_group(Global.group_player_cameras, "set_camera_limits")
	if game_data["game"] == Profiles.Games.ENIGMA or game_data["game"] == Profiles.Games.THE_DUEL:	
		get_tree().call_group(Global.group_player_cameras, "set_zoom_to_level_size")
			
	# minimap
#	var minimap_container: ViewportContainer = $"../Minimap"
#	var minimap_viewport: Viewport = $"../Minimap/MinimapViewport"
#	var minimap_camera: Camera2D = $"../Minimap/MinimapViewport/MinimapCam"	
	
#	if Global.game_manager.game_settings["minimap_on"]:
#		minimap_container.visible = true
#		minimap_viewport.world_2d = viewport_1.world_2d
#		minimap_viewport.size.y = minimap_viewport.size.x * tilemap_edge.size.y / tilemap_edge.size.x # višina minimape v razmerju s formatom tilemapa
#		minimap_camera.set_camera(tilemap_edge, cell_size_x, minimap_viewport.size)
#	else:
#		minimap_container.visible = false
	
	
func set_players():
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		if game_data["game"] == Profiles.Games.TUTORIAL:
			new_player_pixel.modulate = Global.color_almost_black # da se lažje bere text nad njim
		else: 
			new_player_pixel.modulate = game_settings["player_start_color"]
#			new_player_pixel.modulate = Color.white
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
		new_player_pixel.set_physics_process(false)
		
		# players camera
		if spawned_player_index == 1:
			new_player_pixel.player_camera = Global.player1_camera
			new_player_pixel.player_camera.camera_target = new_player_pixel
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
			new_player_pixel.player_camera.camera_target = new_player_pixel
			
		
func set_strays():
	
	spawn_strays(start_strays_spawn_count)
	
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int = 0
	while strays_shown.size() < start_strays_spawn_count:
		show_strays_loop += 1 # zazih
		show_strays_on_start(show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout")
	
	strays_shown.clear() # resetiram, da je mogoč in-game spawn

	
func spawn_strays(strays_to_spawn_count: int):
	
	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
	# colors
	var all_colors_available: Array
	if Profiles.use_custom_color_theme:
		var color_split_offset: float = 1.0 / strays_to_spawn_count
		for stray_count in strays_to_spawn_count:
			var color = Global.game_color_theme_gradient.interpolate(stray_count * color_split_offset) # barva na lokaciji v spektrumu
			all_colors_available.append(color)	
	else:
		all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
	all_stray_colors = [] # reset ... za color indikatorje
	
	# positions
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	# spawn
	for stray_index in strays_to_spawn_count:
		var current_color: Color = all_colors_available[stray_index] # barva na lokaciji v spektrumu
		# spawn positions
		var current_spawn_positions: Array
		if not available_required_spawn_positions.empty(): # najprej obvezne
			current_spawn_positions = available_required_spawn_positions
		elif available_required_spawn_positions.empty(): # potem random
			current_spawn_positions = available_random_spawn_positions
		elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
			print ("No available spawn positions")
			return
		# random position
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position = current_spawn_positions[selected_cell_index]
		# spawn
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		all_stray_colors.append(current_color)
		current_spawn_positions.remove(selected_cell_index) # odstranim pozicijo iz nabora za start spawn
			
	Global.hud.spawn_color_indicators(all_stray_colors) # barve pokažem v hudu		
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba
	
	
# UTILITI ----------------------------------------------------------------------------------


func show_strays_on_start(show_strays_loop: int):

	var spawn_shake_power: float = 0.30
	var spawn_shake_time: float = 0.7
	var spawn_shake_decay: float = 0.2		
	get_tree().call_group(Global.group_player_cameras, "shake_camera", spawn_shake_power, spawn_shake_time, spawn_shake_decay)
		
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	match show_strays_loop:
		1:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/10)
		2:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/8)
		3:
			strays_to_show_count = round(strays_in_game_count/4)
		4:
			Global.sound_manager.play_sfx("thunder_strike")
			strays_to_show_count = round(strays_in_game_count/2)
		5: # še preostale
			strays_to_show_count = strays_in_game_count - strays_shown.size()
	
	# stray fade-in
	var spawned_strays = get_tree().get_nodes_in_group(Global.group_strays)
	var loop_count = 0
	for stray in spawned_strays:
		if not strays_shown.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			stray.show_stray()
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break

	
func stop_game_elements():
	
	# včasih nujno
	Global.hud.popups_out()
	get_tree().call_group(Global.group_players, "empty_cocking_ghosts")
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.stop_sound("teleport")
		player.stop_sound("heartbeat")
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		stray.current_state = stray.States.STATIC

	
func _change_strays_in_game_count(strays_count_change: int):
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	strays_in_game_count = clamp(0, strays_in_game_count, strays_in_game_count)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		return
	if strays_in_game_count == 0: # tutorial sam ve kdaj je gameover, klasika pa nima cleaned modela 
		game_over(GameoverReason.CLEANED)		


# SIGNALI ----------------------------------------------------------------------------------


func _on_tilemap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array): # , goal_stray_global_positions: Array) -> void:
	
	# opredelim tipe pozicij
	player_start_positions = player_cells_positions
	random_spawn_positions = random_spawn_floor_positions
	required_spawn_positions = stray_cells_positions
	
	# start strays count setup
	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
		start_strays_spawn_count = required_spawn_positions.size()
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if start_strays_spawn_count > random_spawn_positions.size() + required_spawn_positions.size():
		start_strays_spawn_count = random_spawn_positions.size()/2 + required_spawn_positions.size()

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range) + 1
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
	
	# grab respawn positions
	available_respawn_positions = Global.current_tilemap.floor_global_positions.duplicate()
	dont_turn_to_wall_positions = no_stray_cells_positions
