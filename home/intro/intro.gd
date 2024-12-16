extends Node2D


signal finished_playing

export var actor_in_motion: bool = true # exportano za animacijo

var intro_strays_spawned: bool = false
var camera_is_shaking: bool = false # da se šejk ne podvaja
var actor_step_time: float = 0.08

# strays
var creating_strays: bool = false
var spawned_strays_count: int = 0
var strays_shown_on_start: Array = []
var create_strays_count: int = 149 # 149 v naslovu ... ne sme bit onready, ker povozi ukaz s tilemapa
var color_pool_colors: Array

# tilemap data
var start_players_count: int
var cell_size_x: int # napolne se na koncu setanju tilemapa
var default_required_spawn_positions: Array # konstanta
var required_spawn_positions: Array # vključuje tudi wall_spawn_positions
var free_floor_positions: Array # = [] # to so vse proste

onready var spectrum_rect: TextureRect = $Spectrum
onready var spectrum_gradient: TextureRect = $SpectrumGradient
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var stray_step_timer: Timer = $StrayStepTimer
onready var actor_pixel: KinematicBody2D = $Actor
onready var text_node: Node2D = $Text
onready var thunder_cover: ColorRect = $ThunderCover/ThunderCover
onready var StrayPixel: PackedScene = preload("res://home/intro/intro_stray.tscn")
onready var environment_node: Environment = $ArenaEnvironment.environment

onready var hint_btn: Button = $ActionHintPress/HintBtn
onready var action_hint_press: Node2D = $ActionHintPress


func _unhandled_input(event: InputEvent) -> void:

	if action_hint_press.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_on_HintBtn_pressed()
			Analytics.save_ui_click("SkipIntroReturn") # pazi, če začne delat tako kot bi moralo
		elif Input.is_action_just_pressed("ui_cancel"):
			_on_HintBtn_pressed()
			Analytics.save_ui_click("SkipIntroEsc") # pazi, če začne delat tako kot bi moralo


func _ready() -> void:

	Global.game_manager = self

	randomize()
	hint_btn.disabled = true


# INTRO LOOP ----------------------------------------------------------------------------------


func play_intro():

	yield(get_tree().create_timer(1), "timeout")
	animation_player.play("intro_running")
	hint_btn.disabled = false


func finish_intro(): # ob skipanju in regularnem koncu intra

	action_hint_press.hide()
	# vse pospravim ... zazih
	animation_player.stop()
	actor_in_motion = false
	actor_pixel.visible = false
	thunder_cover.visible = false
	text_node.visible = false
	if not intro_strays_spawned:
		set_strays()

	yield(get_tree().create_timer(1), "timeout")
	emit_signal("finished_playing") # menu_in on main

	yield(get_tree().create_timer(3), "timeout")
	random_stray_step()


# STRAYS ---------------------------------------------------------------------------------------


func set_strays(): # kliče animacija

	if not creating_strays:
		# positions
		free_floor_positions = Global.current_tilemap.all_floor_tiles_global_positions.duplicate()
		# colors
		set_color_pool()
		# reset
		spawned_strays_count = 0
		creating_strays = true
		create_strays(create_strays_count)


func create_strays(strays_to_spawn_count: int = required_spawn_positions.size()):

	#	spawned_strays_count = 0
	#	free_floor_positions = Global.current_tilemap.all_floor_tiles_global_positions.duplicate()

	var color_pool_split_size: int = floor(color_pool_colors.size() / strays_to_spawn_count)

	# set strays to spawn
	var strays_set_to_spawn: Array = [] # naložim setingse za vsakega straysa, da jijh lahko spawnam z zamikom ... (stray_index, new_stray_color, selected_stray_position, turn_to_white)
	for stray_index in strays_to_spawn_count:

		var new_stray_color_pool_index: int = stray_index * color_pool_split_size
		var new_stray_color: Color = color_pool_colors[new_stray_color_pool_index] # barva na lokaciji v spektrumu
		var current_spawn_positions: Array = required_spawn_positions

		# žrebanje random pozicije določenih spawn pozicij
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)
		var selected_cell_position: Vector2 = current_spawn_positions[selected_cell_index]
		var selected_stray_position: Vector2 = selected_cell_position + Vector2(cell_size_x/2, cell_size_x/2)

		# če je prazna spawnam, drugače preskočim spawn in odštejem število potrebnih za spavnanje (na koncu preverjam, da ni število spawnanih 0)
		var turn_to_white: bool = false
		strays_set_to_spawn.append([stray_index, new_stray_color, selected_stray_position, turn_to_white])

		required_spawn_positions.erase(selected_cell_position)

	# spawn ... trotlam
	var throttler_start_msec = Time.get_ticks_msec()
	var spawned_strays_true_count: int = 0
	for set_stray in strays_set_to_spawn:
		var new_stray_index = set_stray[0]
		var new_stray_color = set_stray[1]
		var selected_stray_position = set_stray[2]
		var turn_to_white = set_stray[3]
		var msec_taken = Time.get_ticks_msec() - throttler_start_msec
		# znotraj frejma ... spawnam
		if msec_taken < (round(1000 / Engine.get_frames_per_second()) - Global.throttler_msec_threshold): # msec_per_frame - ...
			spawned_strays_true_count += 1
			spawn_stray(new_stray_index, new_stray_color, selected_stray_position, turn_to_white)
		# zunaj frejma
		else:
			# print ("re-trotlam - intro stray spawn")
			var msec_to_next_frame: float = Global.throttler_msec_threshold + 1
			var sec_to_next_frame: float = msec_to_next_frame / 1000.0
			yield(get_tree().create_timer(sec_to_next_frame), "timeout") # da se vsi straysi spawnajo
			throttler_start_msec = Time.get_ticks_msec()
			# vrnem pozicijo nazaj
			required_spawn_positions.append(selected_stray_position)

	# ponovim za preostale spawne
	if spawned_strays_true_count < strays_to_spawn_count and not spawned_strays_true_count == 0:
		create_strays(strays_to_spawn_count - spawned_strays_true_count)
		return

	intro_strays_spawned = true # more bit čimprej

	var show_strays_loop: int = 0
	strays_shown_on_start.clear()
	while strays_shown_on_start.size() < create_strays_count:
		show_strays_loop += 1
		call_deferred("show_strays_in_loop", show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout") # da se vsi straysi spawnajo

	required_spawn_positions = default_required_spawn_positions.duplicate() # za barvne sheme


func spawn_stray(stray_index: int, stray_color: Color, stray_position: Vector2, is_white: bool):
	# namen: add child parent, faces off

	# spawn
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "S%s" % str(stray_index)
	new_stray_pixel.stray_color = stray_color
	new_stray_pixel.global_position = stray_position # dodana adaptacija zaradi središča pixla
	new_stray_pixel.z_index = 2 # višje od plejerja
	add_child(new_stray_pixel)

	new_stray_pixel.pixel_face.hide()
	spawned_strays_count += 1

	if is_white:
		new_stray_pixel.current_state = new_stray_pixel.STATES.WALL

	return new_stray_pixel


func show_strays_in_loop(show_strays_loop: int):

	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	match show_strays_loop:
		1:
			strays_to_show_count = round(spawned_strays_count/10)
		2:
			strays_to_show_count = round(spawned_strays_count/8)
		3:
			strays_to_show_count = round(spawned_strays_count/4)
		4:
			strays_to_show_count = round(spawned_strays_count/2)
		5: # še preostale
			strays_to_show_count = spawned_strays_count - strays_shown_on_start.size()

	# show
	var loop_count = 0
	for stray in get_tree().get_nodes_in_group(Global.group_strays): # nujno jih ponovno zajamem
		if strays_shown_on_start.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			break
		if loop_count >= strays_to_show_count:
			stray.show_stray()
			strays_shown_on_start.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže

	# zamaknjen thunder
	yield(get_tree().create_timer(0.5), "timeout")
	shake_camera_on_show_strays()
	match show_strays_loop:
		1, 2:
			Global.sound_manager.play_event_sfx("thunder_strike")
		5:
			creating_strays = false


func respawn_title_strays():

	if not creating_strays:
		stray_step_timer.stop()
		var pseudo_value: int = -1
		var intro_strays: Array = get_tree().get_nodes_in_group(Global.group_strays)
		for stray in intro_strays:
			stray.die(intro_strays.find(stray), intro_strays.size())
		yield(get_tree().create_timer(1), "timeout") # ... da je časovni razmak
		call_deferred("set_strays")
		yield(get_tree().create_timer(3), "timeout")
		call_deferred("random_stray_step")


func random_stray_step():

	# random dir
	var random_direction_index: int = randi() % int(4)
	var stepping_direction: Vector2
	match random_direction_index:
		0: stepping_direction = Vector2.LEFT
		1: stepping_direction = Vector2.UP
		2: stepping_direction = Vector2.RIGHT
		3: stepping_direction = Vector2.DOWN

	# random stray

	var intro_strays = get_tree().get_nodes_in_group(Global.group_strays)
	var random_stray_no: int = randi() % int(spawned_strays_count)# intro_strays.size())
	var stray_to_move = intro_strays[random_stray_no]
	if not intro_strays.empty():
		stray_to_move.step(stepping_direction)

	# next step random time
	var random_pause_time_divider: float = randi() % int(5) + 1 # višji offset da manjši razpon v random času
	var random_pause_time = 1 / random_pause_time_divider
	stray_step_timer.start(random_pause_time)


# UTILITY ------------------------------------------------------------------------------------


func is_floor_position_free(position_in_check: Vector2):
	# pozicija mora biti že snepana

	var position_in_check_on_grid = position_in_check - Vector2(cell_size_x/2, cell_size_x/2)

	if free_floor_positions.has(position_in_check_on_grid):
		return true
	else:
		return false


func remove_from_free_floor_positions(position_to_remove: Vector2):
	# pozicija mora biti že snepana

	var position_to_remove_on_grid = position_to_remove - Vector2(cell_size_x/2, cell_size_x/2)
	if free_floor_positions.has(position_to_remove_on_grid):
		free_floor_positions.erase(position_to_remove_on_grid)


func add_to_free_floor_positions(position_to_add: Vector2):

	var position_to_add_on_grid = position_to_add - Vector2(cell_size_x/2, cell_size_x/2)

	# preverim, da je med original floor pozicijami in, da ni slučajno že med free
	if Global.current_tilemap.all_floor_tiles_global_positions.has(position_to_add_on_grid) and not free_floor_positions.has(position_to_add_on_grid):
		free_floor_positions.append(position_to_add_on_grid)


func set_color_pool():

	var colors_wanted_count: int = default_required_spawn_positions.size()

	color_pool_colors = [] # reset

	if Profiles.use_default_color_theme:
		color_pool_colors = Global.get_spectrum_colors(colors_wanted_count) # prvi level je original ... vsi naslednji imajo random gradient
	else:
		var color_split_offset: float = 1.0 / colors_wanted_count
		for color_count in colors_wanted_count:
			var color = Global.game_color_theme_gradient.interpolate(color_count * color_split_offset) # barva na lokaciji v spektrumu
			color_pool_colors.append(color)


func shake_camera_on_show_strays():

	if not camera_is_shaking:
		camera_is_shaking = true
		# shake
		var spawn_shake_power: float = 0.35
		var spawn_shake_time: float = 1
		var spawn_shake_decay: float = 0.2
		Global.intro_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)


func play_actor_stepping_sound(): # kliče animacija

	if actor_in_motion:
		Global.sound_manager.play_intro_stepping_sfx()
		yield(get_tree().create_timer(actor_step_time), "timeout")
		play_actor_stepping_sound()


func play_blinking_sound(): # kliče animacija
	Global.sound_manager.play_event_sfx("blinking")


func play_thunder_strike():
	Global.sound_manager.play_event_sfx("thunder_strike")


# SIGNALS ----------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"intro_running":
			animation_player.play("intro_explode")
		"intro_explode":
			finish_intro()


func _on_StrayStepTimer_timeout() -> void:
	random_stray_step()


func _on_TileMap_completed(stray_random_positions: Array, stray_positions: Array, stray_wall_positions: Array, no_stray_positions: Array, player_positions: Array) -> void:

	default_required_spawn_positions = stray_positions # zaradi trotlinga
	required_spawn_positions = default_required_spawn_positions.duplicate() # ima tudi wall_spawn_positions
	create_strays_count = required_spawn_positions.size()

	# preventam preveč straysov (več kot je možnih pozicij)
	if create_strays_count > required_spawn_positions.size():
		create_strays_count = required_spawn_positions.size()


func _on_HintBtn_pressed() -> void:

	hint_btn.grab_focus()
	finish_intro()
