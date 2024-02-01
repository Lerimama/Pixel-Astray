extends GameManager # default game manager



var current_stray_spawning_round: int = 0 # prištevam na koncu spawna

var lines_scrolled_count: int = 0 # prištevam v stray_step()
var lines_scroll_per_round: int = 7

var current_stage: int = 0 # na štartu se kliče stage up

var current_level: int = 0 # na štartu se kliče level up

# level progres
enum LevelProgressType {COLORS_PICKED, SCROLLING_LINES, FLOOR_CLEARED}
#var current_progress_type: int = LevelProgressType.SCROLLING_LINES		
#var current_progress_type: int = LevelProgressType.COLORS_PICKED		
var current_progress_type: int = LevelProgressType.FLOOR_CLEARED	

var levels_per_game: int = 10
var scrolling_pause_time: float # pavza med stepi
var level_color_scheme: Dictionary # trenutna barvna shema
onready var leveling_conditions: Dictionary = Profiles.scrolling_levels_conditions
var stages_per_level: int # = Profiles.scrolling_levels_conditions[1]


func _ready() -> void:

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_scrolling.tscn")
	PlayerPixel = preload("res://game/pixel/player_scrolling.tscn")
	randomize()


func set_game(): 
	# namen: setam level indikatorje in strayse spawnam po štratu igre
	
	# kliče main.gd pred prikazom igre
	# set_tilemap()
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin

	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
#
#	set_fresh_level_indicators()
#	set_strays()
	
	yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda

	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu

	start_game()

	

func start_game():

	Global.hud.game_timer.start_timer()
	Global.sound_manager.play_music("game_music")

	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.set_physics_process(true)
	
	yield(get_tree().create_timer(2), "timeout") # čaka na hudov slide in
	game_on = true
	
	upgrade_stage_or_level() # level stage logika za upgrade z 0
	spawn_strays(game_data["strays_start_count"])

	stray_step() # prvi step


func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
#	if gameover_reason == GameoverReason.TIME:
#		return
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
	# namem: dodam povezavo s signalom  iz aree	
	
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
	Global.current_tilemap.connect("floor_area_empty", self, "_on_floor_area_emptied")
	
	# grab tilemap tiles
	Global.current_tilemap.get_tiles()
	cell_size_x = Global.current_tilemap.cell_size.x 


func set_game_view():

	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"

	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start

	# SCOLLER ... 1 ekran tudi v prmeru dveh plejerjev
	viewport_container_2.visible = false
	viewport_separator.visible = false
	# /

	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	Global.player1_camera.set_camera_limits()
	

func set_level_colors():

	var spectrum_image: Image
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		level_indicator_color_offset = spectrum_texture_width / stages_per_level

	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, level_color_scheme[1])
		gradient.set_color(1, level_color_scheme[2])
		level_indicator_color_offset = 1.0 / stages_per_level

	var selected_color_position_x: float
	var current_color: Color
	var all_level_colors: Array = [] # za color indikatorje

	for stage in stages_per_level:
		if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
		all_level_colors.append(current_color)

	Global.hud.spawn_color_indicators(all_level_colors) # barve pokažem v hudu	

	
func set_players():
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.modulate = Global.color_white
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
			# new_player_pixel.player_camera.camera_target = new_player_pixel
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
			# new_player_pixel.player_camera.camera_target = new_player_pixel


func upgrade_stage_or_level():
	# kliče se lahko na:
	# stray die 
	# stray step, ki pomeni tudi spawned line
	# on_floor_cleared ... iz tilemapa s "signalom"
	
#	if current_progress_type == LevelProgressType.FLOOR_CLEARED:
#		current_stage = stages_per_level + 1 # +1 da je že naslednji level
	
	# stage up
	if current_stage <= stages_per_level and not current_stray_spawning_round == 0:# and not floor_is_cleared: # pogoj runde preusmeri funkcijo v upgrade levela (spodaj)
		
		
		current_stage += 1
		Global.hud.update_indicator_on_stage_up(current_stage) # povdari indikator
		printt ("new stage", current_stage)
		
		if current_progress_type == LevelProgressType.FLOOR_CLEARED:
			while current_stage < stages_per_level:
				printt ("x stage", current_stage)
				current_stage += 1
				yield(get_tree().create_timer(0.05), "timeout")
				Global.hud.update_indicator_on_stage_up(current_stage) # obarvaj prvega
				
				
	# level up ... tudi ob štartu ko je spawning round 0
	else:
		# če ne presega max levelov
		if current_level < levels_per_game:
			current_level += 1 # številka trenutnega levela 
			printt ("new level", current_level)
			# prebarvam in reštaram level
			Global.hud.empty_color_indicators() # novi indkatorji
			set_level_conditions()
			if current_progress_type == LevelProgressType.FLOOR_CLEARED:
				stages_per_level = 3					
			set_level_colors() 
			# poštimam prvi stage levela 
			current_stage = 1
			Global.hud.update_indicator_on_stage_up(current_stage) # obarvaj prvega
			
		# če presega max levele ... game over
		else:
			game_over(GameoverReason.TIME)
	
	
func set_level_conditions():
		
	
	if current_level > 0:
		stages_per_level = leveling_conditions[current_level].stages_per_level
		level_color_scheme = leveling_conditions[current_level].color_scheme
		scrolling_pause_time = leveling_conditions[current_level].scrolling_pause_time
		game_data["strays_start_count"] = leveling_conditions[current_level].strays_spawn_count
		
#		print(level_color_scheme)
		

# STRAYS -----------------------------------------------------------------------------

func spawn_strays(strays_to_spawn_count: int):
	
	if not game_on:
		return
		
	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			

	var spectrum_image: Image
	var color_offset: float
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		# razmak med barvami za strayse
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		color_offset = spectrum_texture_width / strays_to_spawn_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, level_color_scheme[1])
		gradient.set_color(1, level_color_scheme[2])
		# razmak med barvami za strayse
		color_offset = 1.0 / strays_to_spawn_count

	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"

	var all_colors: Array = [] # za color indikatorje

	for stray_index in strays_to_spawn_count:

		# barva
		var current_color: Color
		var selected_color_position_x: float
		if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu

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
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		# odstranim uporabljeno pozicijo
		new_stray_pixel.show_stray()
		current_spawn_positions.remove(selected_cell_index)


	self.strays_in_game_count = strays_to_spawn_count # setget sprememba
	current_stray_spawning_round += 1


func stray_step():
	
	var stepping_direction: Vector2
	
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		
		stepping_direction = Vector2.DOWN
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.IDLE: 
				stray.step(stepping_direction)
		
		if lines_scrolled_count % lines_scroll_per_round == 0:
			spawn_strays(game_data["strays_start_count"])
			
		lines_scrolled_count += 1
		
		if current_progress_type == LevelProgressType.SCROLLING_LINES:
			upgrade_stage_or_level()
			
		yield(get_tree().create_timer(scrolling_pause_time), "timeout")
		
	if game_on and not floor_is_cleared:
		stray_step()

#		print("flor", strays_on_floor)


# SIGNALI -----------------------------------------------------------------------------

#var strays_dying: Array = []
#var strays_on_floor: Array =[] # za čekiranje ... podatek ureja tilemap 

#var 
#
#func check_strays_on_floor(): = true
#		current_stage = 
var floor_is_cleared: bool = false

func on_floor_cleared(): # kliče Player še pred aplciranjem animacij
	
	# posledice pucanja flora
	floor_is_cleared = true

	# next level
	if current_progress_type == LevelProgressType.FLOOR_CLEARED:
#		floor_is_cleared = true
#		current_stage = stages_per_level + 1 # da gre takoj na novi level
		upgrade_stage_or_level()
	else:
		# get xtra points
		pass
		
	print ("spucana tla")
	
	

func _on_floor_area_emptied(): # ko so zbrisani vsi strayi, reštartam prazna tla
	floor_is_cleared = false
	stray_step()
	#joy vibra stop
	# stop kamera šejk
	
	

	print ("spucan ekran")
	pass
