extends Node


signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var players_count: int

# strays
#var strays_in_game: Array = []
var strays_shown: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int
var all_strays_died_alowed: bool = false # za omejevnje signala iz FP

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
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
		all_strays_died_alowed = false
		emit_signal("all_strays_died")
		print("all_strays_died emited")

#	
		
	# raycasting
	


#	Rect2(x: float, y: float, width: float, height: float)
	if get_tree().get_nodes_in_group(Global.group_players).size() == 2 and ray_target_1:
#		print(ray_target_1)
#		printt (ray_target_1, ray_target_2)
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if player.name == "p1":
				
				ray_target_1 = player.global_position
				player.ray_cast_2d.cast_to = Vector2.ZERO
				printt(player.global_position, player.player_camera.get_camera_screen_center())
			if player.name == "p2":
				indi_2.global_position = player.player_camera.get_camera_screen_center()
				var vp_limits = player.player_camera.get_viewport_rect()
				
				var vp_limits_x = indi_2.global_position.x - vp_limits.size.x
				var vp_limits_x2 = indi_2.global_position.x + vp_limits.size.x
				var vp_limits_up = (vp_limits.size.y + player.ray_cast_2d.global_position.y)
#				printt(vp_limits_up, player.player_camera.get_viewport_rect(), vp_limits.size.y, player.ray_cast_2d.global_position.y)
				var vp_limits_down = -(vp_limits.size.y - player.ray_cast_2d.global_position.y)
				
				ray_target_2 = player.global_position
				player.ray_cast_2d.cast_to = ray_target_1 - player.ray_cast_2d.global_position
				
				player.ray_cast_2d.cast_to.x = clamp(player.ray_cast_2d.cast_to.x, -500, 320)
				player.ray_cast_2d.cast_to.y = clamp(player.ray_cast_2d.cast_to.y, player.ray_cast_2d.global_position.y - 900, player.ray_cast_2d.global_position.y + 900)
				
			
			
var ray_target_1: Vector2
var ray_target_2: Vector2
var indi_1
var indi_2

# debug
onready var PosIndi = preload("res://game/DirectionIndicator.tscn")

func spawn_debug_indicator(position, color):
	
	var pos_indi = PosIndi.instance()
	pos_indi.global_position = position
	pos_indi.modulate = color
	pos_indi.z_index = 10
#	pos_indi.modulate.a = 0.5
	Global.node_creation_parent.add_child(pos_indi)
	printt (pos_indi.name, pos_indi.global_position)
	
	return pos_indi
	
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	set_players()
	
	if not game_data["game"] == Profiles.Games.TUTORIAL: 
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
			signaling_player = player
		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	yield(get_tree().create_timer(2), "timeout") # za dojet
	
	stop_game_elements()
	
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
			
			ray_target_1 = new_player_pixel.global_position
#			indi_1 = spawn_debug_indicator(ray_target_1, Color.red)
			
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
			new_player_pixel.player_camera.camera_target = new_player_pixel
			
			ray_target_2 = new_player_pixel.global_position
		
			indi_2 = spawn_debug_indicator(ray_target_2, Color.blue)
		
func set_strays():
	
	spawn_strays(game_data["strays_start_count"])
	
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int = 0
	while strays_shown.size() < game_data["strays_start_count"]:
		show_strays_loop += 1 # zazih
		show_strays(show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout")
	
	# resetiram, da je mogoče in-game spawn
	strays_shown.clear()


func spawn_strays(strays_to_spawn_count: int):
	
	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			
	
	# poberem sliko
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()
	
	# izračun razmaka med barvami
	var spectrum_texture_width = spectrum_rect.rect_size.x
	var color_skip_size = spectrum_texture_width / strays_to_spawn_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	
	var all_colors: Array = []
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	for stray_index in strays_to_spawn_count:
		
		# barva
		var selected_color_position_x = stray_index * color_skip_size # lokacija barve v spektrumu
		var current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		all_colors.append(current_color)
		
		# možne spawn pozicije
		var current_spawn_positions: Array
		if not available_required_spawn_positions.empty(): # najprej obvezne
			current_spawn_positions = available_required_spawn_positions
		elif available_required_spawn_positions.empty(): # potem random
			current_spawn_positions = available_random_spawn_positions
		elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
			print ("No available spawn positions")
			return
		
		# random pozicija med možnimi
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position = current_spawn_positions[selected_cell_index]
		
		# spawn stray
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Global.game_tilemap.cell_size/2 # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		# odstranim uporabljeno pozicijo
		current_spawn_positions.remove(selected_cell_index)
	
	
	Global.hud.spawn_color_indicators(all_colors) # barve pokažem v hudu			
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba


# UTILITI ----------------------------------------------------------------------------------


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
			stray.fade_in()	
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break


func stop_game_elements():
	
	Global.sound_manager.stop_music("game_music_on_gameover")	
	
	# včasih nujno
	Global.hud.popups_out()
	Global.sound_manager.stop_sfx("teleport")
	Global.sound_manager.stop_sfx("heartbeat")
	get_tree().call_group(Global.group_players, "empty_cocking_ghosts")

	
func _change_strays_in_game_count(strays_count_change: int):
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if strays_in_game_count == 0 and not game_data["game"] == Profiles.Games.TUTORIAL: # tutorial sam ve kdaj je gameover
		game_over(GameoverReason.CLEANED)
		

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
		game_data["strays_start_count"] = required_spawn_positions.size()
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if game_data["strays_start_count"] > random_spawn_positions.size() + required_spawn_positions.size():
		game_data["strays_start_count"] = random_spawn_positions.size()/2 + required_spawn_positions.size()

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range)
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
