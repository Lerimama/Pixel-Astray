extends Node


signal finished_playing

export var actor_in_motion: bool = true # exportano za animacijo
var intro_strays_spawned: bool = false
var step_time: float = 0.08

# players ... v intru zaenkrat ne rabim
var player_start_positions: Array
var players_count: int

# strays
var strays_in_game: Array = []
var strays_shown: Array = []
var strays_start_count: int =  500 # 149 v naslovu ... ne sme bit onready, ker povozi ukaz s tilemapa
var all_colors_available: Array

# tilemap data
var random_spawn_positions: Array
var required_spawn_positions: Array

onready var spectrum_rect: TextureRect = $Spectrum
onready var spectrum_gradient: TextureRect = $SpectrumGradient
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var stray_step_timer: Timer = $StrayStepTimer
onready var actor_pixel: KinematicBody2D = $Actor
onready var text_node: Node2D = $Text
onready var thunder_cover: ColorRect = $ThunderCover/ThunderCover
#onready var skip_intro: HBoxContainer = $Text/SkipIntro
onready var skip_intro: HBoxContainer = $Text/ActionHint
onready var StrayPixel = preload("res://home/intro/intro_stray.tscn")


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_accept") and skip_intro.visible:
		_on_StartButton_pressed()
		finish_intro()
		
		
func _ready() -> void:
	
	randomize()
	
	
func _process(delta: float) -> void:
	
	strays_in_game = get_tree().get_nodes_in_group(Global.group_strays)
	
	
# INTRO LOOP ----------------------------------------------------------------------------------


func play_intro():
	
	yield(get_tree().create_timer(1), "timeout")
	animation_player.play("intro_running")
	
	
func finish_intro(): # ob skipanju in regularnem koncu intra
	
	# vse pospravim ... zazih
	animation_player.stop()
	skip_intro.visible = false
	actor_in_motion = false
	actor_pixel.visible = false
	thunder_cover.visible = false
	text_node.visible = false
	
	if not intro_strays_spawned:
		set_strays()
		
	yield(get_tree().create_timer(1), "timeout")
	emit_signal("finished_playing") # menu_in on main
	
	yield(get_tree().create_timer(1), "timeout")
	random_stray_step()		

	
# STRAYS ---------------------------------------------------------------------------------------

		
func set_strays():
	
	spawn_strays(strays_start_count)
	
	yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
	
	var show_strays_loop: int = 0
	while strays_shown != strays_in_game:
		show_strays_loop += 1 # zazih
		show_strays(show_strays_loop)
		yield(get_tree().create_timer(0.1), "timeout")
	
	# resetiram, da je mogoče in-game spawn
	strays_shown.clear()
	
	
func spawn_strays(strays_to_spawn_count: int = required_spawn_positions.size()):
	yield(get_tree().create_timer(0), "timeout") # da se ne spawna, ko še ni wall	
	
	# colors
	all_colors_available = [] # zazih
	if Profiles.use_custom_color_theme:
		# naberem barve glede na število potrebnih barv
		var color_split_offset: float = 1.0 / strays_to_spawn_count
		for stray_count in strays_to_spawn_count:
			var color = Global.game_color_theme_gradient.interpolate(stray_count * color_split_offset) # barva na lokaciji v spektrumu
			all_colors_available.append(color)	
	else:
		all_colors_available = Global.get_spectrum_colors(strays_to_spawn_count) # prvi level je original ... vsi naslednji imajo random gradient
	
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	# spawn
	for stray_index in strays_to_spawn_count:
		var current_color: Color = all_colors_available[stray_index] # barva na lokaciji v spektrumu
		# možne spawn pozicije
		var current_spawn_positions: Array
		if not available_required_spawn_positions.empty(): # najprej obvezne
			current_spawn_positions = available_required_spawn_positions
		elif available_required_spawn_positions.empty(): # potem random
			current_spawn_positions = available_random_spawn_positions
		elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
			print("No available spawn positions")
			return
		# random pozicija med možnimi
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position = current_spawn_positions[selected_cell_index]
		# spawn stray
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Global.current_tilemap.cell_size/2 # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		add_child(new_stray_pixel)
#		call_deferred("add_child", new_stray_pixel)
		
		current_spawn_positions.remove(selected_cell_index)
		
	intro_strays_spawned = true	


func show_strays(show_strays_loop: int):
	
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	match show_strays_loop:
		1:	
			# sound efekti so v animaciji		
			strays_to_show_count = round(strays_in_game.size()/10)
		2:
			strays_to_show_count = round(strays_in_game.size()/8)
		3:
			strays_to_show_count = round(strays_in_game.size()/4)
		4:
			strays_to_show_count = round(strays_in_game.size()/2)
		5: # še preostale
			strays_to_show_count = strays_in_game.size() - strays_shown.size()
	
	# stray fade-in
	var loop_count = 0
	for stray in strays_in_game:
		if not strays_shown.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			stray.animation_player.play("glitch_intro")	
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break
	
	
# UTILITI -------------------------------------------------------------------------------------


func shake_camera_on_show_strays():
	
	# shake
	var spawn_shake_power: float = 0.35
	var spawn_shake_time: float = 1
	var spawn_shake_decay: float = 0.2
	Global.intro_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	

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
	var random_stray_no: int = randi() % int(strays_in_game.size())
	var stray_to_move = strays_in_game[random_stray_no]
	if not strays_in_game.empty():
		stray_to_move.step(stepping_direction)
	
	# next step random time
	var random_pause_time_divider: float = randi() % int(5) + 1 # višji offset da manjši razpon v random času
	var random_pause_time = 0.2 / random_pause_time_divider
	stray_step_timer.start(random_pause_time)
	

func respawn_title_strays():
	
	stray_step_timer.stop()
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		#		stray.queue_free()
		stray.call_deferred("queue_free")
	call_deferred("set_strays")
	yield(get_tree().create_timer(1), "timeout")
	#	random_stray_step()
	call_deferred("random_stray_step")
	
		
func play_stepping_loop():
	
	if actor_in_motion:
		Global.sound_manager.play_stepping_sfx(1)
		yield(get_tree().create_timer(step_time), "timeout")
		play_stepping_loop()


func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")
	
	
func play_thunder_strike():
	Global.sound_manager.play_sfx("thunder_strike")
	
	
# SIGNALS ----------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"intro_running": 
			animation_player.play("intro_explode")
		"intro_explode":
			finish_intro()


func _on_StrayStepTimer_timeout() -> void:
	random_stray_step()
	
	
func _on_TileMap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array) -> void:

	# opredelim tipe pozicij
	random_spawn_positions = random_spawn_floor_positions
	required_spawn_positions = stray_cells_positions
	player_start_positions = player_cells_positions
	
	# start strays count setup
	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
		strays_start_count = required_spawn_positions.size()
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if strays_start_count > random_spawn_positions.size() + required_spawn_positions.size():
		strays_start_count = random_spawn_positions.size()/2 + required_spawn_positions.size()

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range)
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup


func _on_StartButton_pressed() -> void:
	finish_intro()
