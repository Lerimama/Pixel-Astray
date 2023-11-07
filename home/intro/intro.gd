extends Node2D


signal finished_playing

# intro
export var actor_in_motion: bool = true # exportano za animacijo
var intro_strays_spawned: bool = false
var step_time: float = 0.08

# shake
var spawn_shake_power: float = 0.25
var spawn_shake_time: float = 0.5
var spawn_shake_decay: float = 0.2	

# spawning
var strays_spawn_loop: int = 0	
var strays_shown: Array = []
var spawned_stray_index: int = 0
var strays_on_screen: Array = []
var title_cells_count: int # pogreba ob izgradnji tilemapa
var floor_positions: Array # po signalu ob kreaciji tilemapa ... tukaj, da ga lahko grebam do zunaj
var available_floor_positions: Array # dplikat floor_positions za spawnanje pixlov
var title_positions: Array
var available_title_positions: Array

onready var intro_tile_map: TileMap = $Level/TileMap
onready var stray_pixels_count: int =  149 # 149 celic je v naslovu
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var stray_step_timer: Timer = $StrayStepTimer
onready var actor_pixel: KinematicBody2D = $Actor
onready var spectrum_rect: TextureRect = $Spectrum
onready var text_node: Node2D = $Text
onready var thunder_cover: ColorRect = $Level/ThunderCover
onready var skip_intro: HBoxContainer = $Text/SkipIntro
onready var StrayPixel = preload("res://game/pixel/stray.tscn")


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") and skip_intro.visible:
		end_intro()
	
	
func _ready() -> void:
	randomize()

	
func _process(delta: float) -> void:
	strays_on_screen = get_tree().get_nodes_in_group(Global.group_strays)

	
# INTRO ----------------------------------------------------------------------------------


func play_intro():
	
	yield(get_tree().create_timer(1), "timeout")
	animation_player.play("intro_running")
	
	
func end_intro():
	
	# vse pospravim ... zazih
	animation_player.stop()
	skip_intro.visible = false
	actor_in_motion = false
	actor_pixel.visible = false
	thunder_cover.visible = false
	text_node.visible = false
	
	if not intro_strays_spawned:
		split_stray_colors()
	
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	
	yield(get_tree().create_timer(1), "timeout")
	emit_signal("finished_playing") # menu_in on main
	yield(get_tree().create_timer(1), "timeout")
	stray_step()	


func stray_step():
	
	# random dir
	var random_direction_index: int = randi() % int(6)
	var stepping_direction: Vector2
	match random_direction_index:
		0: stepping_direction = Vector2.LEFT
		1: stepping_direction = Vector2.UP
		2: stepping_direction = Vector2.RIGHT
		3: stepping_direction = Vector2.DOWN
		# uteži
		4: stepping_direction = Vector2.LEFT
		5: stepping_direction = Vector2.RIGHT
		6: stepping_direction = Vector2.LEFT
		7: stepping_direction = Vector2.RIGHT
	
	# random stray	
	var random_stray_no: int = randi() % int(strays_on_screen.size())
	var strays_to_move = strays_on_screen[random_stray_no]
	if not strays_on_screen.empty():
		strays_to_move.step(stepping_direction)
	# strays_to_move.modulate = Color.white
	
	# next step random time
	var random_pause_time_factor: float = randi() % int(5) + 1 # višji offset da manjši razpon v random času
	var random_pause_time = 0.2 / random_pause_time_factor
	stray_step_timer.start(random_pause_time)
		

# SPAWNING ----------------------------------------------------------------------------------


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
	var loop_count = 0
	for color in color_count:
		# pozicija pixla na sliki
		var selected_color_position_x = loop_count * color_skip_size
		# zajem barve na lokaciji pixla
		var current_color = spectrum_image.get_pixel(selected_color_position_x, 0)
		# spawnananje v okolico ... pogoji sem zakompliciral, da dobim obratni vrstni red
		if loop_count < title_cells_count:
			spawn_title_stray(current_color)
		else: # če jih je več kot v naslovu
			return
		loop_count += 1		
	
	intro_strays_spawned = true
	
	
func spawn_title_stray(stray_color):
	
	spawned_stray_index += 1

	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_stray_index)
	new_stray_pixel.pixel_color = stray_color
	
	# random grid pozicija
	var random_range = available_title_positions.size()
	
	if random_range > 0: # zazih
		var selected_cell_index: int = randi() % int(random_range) # + offset
		new_stray_pixel.global_position = available_title_positions[selected_cell_index]# + grid_cell_size/2
		new_stray_pixel.z_index = 1

		#spawn
		add_child(new_stray_pixel)
		
		# odstranim uporabljeno pozicijo
		available_title_positions.remove(selected_cell_index)
		available_floor_positions.remove(selected_cell_index) # floor ima tudi tajle naslova, zato je ta vrstica nujna
	
		
func show_strays():
	
	# intro_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	
	var strays_to_show_count: int
	
	strays_spawn_loop += 1
	if strays_spawn_loop <= 4:
		# polovica, četrtina, osmina, ostale
		match strays_spawn_loop:
			1: strays_to_show_count = round(strays_on_screen.size()/2)
			2: strays_to_show_count = round(strays_on_screen.size()/4)
			3: strays_to_show_count = round(strays_on_screen.size()/8)
			4: strays_to_show_count = strays_on_screen.size() - strays_shown.size()
	
	# fade-in za vsak stray v igri ... med še ne pokazanimi (strays_to_show)
	var loop_count = 0
	for stray in strays_on_screen:
		# če stray še ni pokazan ga pokažem in dodam me pokazane
		if not strays_shown.has(stray):# and loop_count < strays_count_to_reveal:
			stray.fade_in()	
			strays_shown.append(stray)
			loop_count += 1 # šterjem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break


# ZVOK ----------------------------------------------------------------------------------

	
func play_stepping_loop():
	if actor_in_motion:
		Global.sound_manager.play_stepping_sfx(1)
		yield(get_tree().create_timer(step_time), "timeout")
		play_stepping_loop()


func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")
	
	
func play_thunder_strike():
	Global.sound_manager.play_sfx("thunder_strike")

	
# SIGNALI ----------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"intro_running": 
			animation_player.play("intro_explode")
		"intro_explode":
			end_intro()


func _on_StrayStepTimer_timeout() -> void:
	stray_step()


func _on_TileMap_tilemap_completed(floor_cells_global_positions: Array, title_cells_global_positions: Array) -> void:
	
	floor_positions = floor_cells_global_positions # title + floor positions
	title_positions = title_cells_global_positions 
	title_cells_count = title_positions.size()
	
	available_floor_positions = floor_positions.duplicate()
	available_title_positions = title_positions.duplicate()
