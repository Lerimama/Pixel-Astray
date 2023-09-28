extends Node2D


signal finished_playing

# intro
export var actor_in_motion: bool = true # exportano za animacijo
var step_time: float = 0.065
var last_breath_loop_limit: int = 5 
var last_breath_loop_count: int = 0

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

onready var stray_pixels_count: int = Profiles.game_rules["intro_strays_count"] # 149 celic je v naslovu
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var actor_pixel: KinematicBody2D = $Actor
onready var spectrum_rect: TextureRect = $Spectrum
onready var text: Node2D = $Text
onready var thunder_cover: ColorRect = $Level/ThunderCover
onready var skip_intro_label: Label = $Text/SkipIntroLabel
onready var StrayPixel = preload("res://game/pixel/stray.tscn")


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and skip_intro_label.visible:
		skip_intro()
	
	
func _ready() -> void:
	randomize()

	
func _process(delta: float) -> void:
	strays_on_screen = get_tree().get_nodes_in_group(Global.group_strays)

	
# INTRO ----------------------------------------------------------------------------------


func play_intro():
	animation_player.play("intro_running")
	
	
func skip_intro(): # kadar je intro skipan
	
	skip_intro_label.visible = false
	animation_player.stop()
	thunder_cover.visible = false
	actor_in_motion = false
	text.visible = false
	actor_pixel.visible = false
	
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("finished_playing")
	split_stray_colors()
	
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	yield(get_tree().create_timer(0.1), "timeout")
	show_strays()
	for stray in strays_on_screen: # tole je že tukaj, ker ima nakljiučne pavze in drugače predolgo traya
		stray.current_stray_state = stray.StrayState.WANDERING
#		print("št" ,stray)
	print("število" ,strays_on_screen.size())
		
		
func end_intro(): # kliče se iz animacije, ko intro pride do konca
	for stray in strays_on_screen:
		stray.current_stray_state = stray.StrayState.WANDERING
		print("št" ,stray)
		
	emit_signal("finished_playing")


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
		if loop_count < (stray_pixels_count - title_cells_count): # 
			spawn_floor_stray(current_color)
		# spawnananje v naslov
		elif loop_count < stray_pixels_count:
			spawn_title_stray(current_color)
		loop_count += 1		
	

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
		
		# samo intro
		new_stray_pixel.collision_shape_2d.disabled = true
		
		# odstranim uporabljeno pozicijo
		available_title_positions.remove(selected_cell_index)
		available_floor_positions.remove(selected_cell_index) # floor ima tudi tajle naslova, zato je ta vrstica nujna
	

func spawn_floor_stray(stray_color):
	
	spawned_stray_index += 1

	# instance
	var new_stray_pixel = StrayPixel.instance()
	new_stray_pixel.name = "Stray%s" % str(spawned_stray_index)
	new_stray_pixel.pixel_color = stray_color
	
	# random grid pozicija
	var random_range = available_floor_positions.size()
	var selected_cell_index: int = randi() % int(random_range) # + offset
	new_stray_pixel.global_position = available_floor_positions[selected_cell_index] + Global.level_tilemap.cell_size/2
	new_stray_pixel.z_index = 1
	
	#spawn
	add_child(new_stray_pixel)
	
	# samo intro
	new_stray_pixel.collision_shape_2d.disabled = true
		
	# odstranim uporabljeno pozicijo
	available_floor_positions.remove(selected_cell_index)

		
func show_strays():
	
#	intro_camera.shake_camera(spawn_shake_power, spawn_shake_time, spawn_shake_decay)
	
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


func _on_TileMap_tilemap_completed(floor_cells_global_positions: Array, title_cells_global_positions: Array) -> void:
	
	floor_positions = floor_cells_global_positions # title + floor positions
	title_positions = title_cells_global_positions 
	title_cells_count = title_positions.size()
	available_floor_positions = floor_positions.duplicate()
	available_title_positions = title_positions.duplicate()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"intro_running": 
			animation_player.play("last_breath")
			Global.sound_manager.play_sfx("last_breath")
			last_breath_loop_count = 1	
		"intro_explode": 
			end_intro()
		"last_breath": 
			last_breath_loop_count += 1
			if last_breath_loop_count > last_breath_loop_limit:
				Global.sound_manager.stop_sfx("last_breath")
				animation_player.play("intro_explode")
			else:
				animation_player.play("last_breath")
				Global.sound_manager.play_sfx("last_breath")
