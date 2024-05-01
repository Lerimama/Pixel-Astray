extends Node2D


# --------------------------------------------------------------------------------------------------------------
# VARIABLE -----------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------


var main_node = null
var node_creation_parent = null # arena

# managers
var sound_manager = null
var data_manager = null
var game_manager = null # tudi za intro

# gui
var current_tilemap = null
var hud = null
var start_countdown = null
var gameover_menu = null
var tutorial_gui = null

# camera
var intro_camera = null
var player1_camera = null
var player2_camera = null

var strays_on_screen: Array = []

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap" # scroller in patterns
var group_player_cameras = "Player Cameras"
var group_ghosts = "Ghosts"

# pixel colors
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")
var color_gray_dark: Color = Color("#232323") # tudi color_floor_scroller
# level colors
var color_wall_dark_theme: Color = Color("#141414")
var color_edge_dark_theme: Color = Color.black
var color_floor_dark_theme: Color = Color("#20ffffff")
var color_background_dark_theme: Color = Color.black
# gui colors
var color_hud_text: Color = Color("#fafafa")
var color_gui_gray: Color = Color("#838383") # siva v tekstih (naslovi) in ikonah
# samo za reference ... niso v kodi
var color_almost_black: Color = Color("#141414") # start player, wall, floor
var color_hud_background: Color = Color("#141414")
var color_wall_gray: Color = Color("#141414")


# --------------------------------------------------------------------------------------------------------------
# FUNKCIJE -----------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------


var current_scene = null # za scene switching
var allow_focus_sfx: bool = false # focus sounds


func _ready(): 
	
	randomize() # custom color scheme
	
	# when _ready is called, there might already be nodes in the tree, so connect all existing buttons
	connect_buttons(get_tree().root)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	

func snap_to_nearest_grid(current_global_position: Vector2):
	
	if not is_instance_valid(current_tilemap):
		print("ERROR! Snapanje na grid ... manjka Global.current_tilemap")
		
	var floor_cells: Array = current_tilemap.floor_global_positions
	var cell_size_x: float = current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
	
	# adaptacija zaradi središčne točke strejsa in playerja
	var current_position: Vector2 = Vector2(current_global_position.x - cell_size_x/2, current_global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice ... potem izbrana je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell
		# snap position
		var snap_to_position: Vector2 = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)
		return snap_to_position
	else: 
		return current_global_position # vrneš isto pozicijo na katere že je 


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


func release_scene(scene_node): # release scene
	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)	


func _free_scene(scene_node):
	print ("SCENE RELEASED (in next step): ", scene_node)	
	scene_node.free()
	

func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	print ("SCENE INSTANCED: ", current_scene)
	print ("---")
	
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root
	print ("SCENE ADDED: ", current_scene)	
	
	return current_scene


# split colors ------------------------------------------------------------------------------------------------


var spectrum_rect: TextureRect
var game_color_theme_gradient: Gradient
onready var gradient_texture: Resource = preload("res://assets/theme/color_theme_gradient.tres")
onready	var spectrum_texture_scene: PackedScene = preload("res://assets/theme/color_theme_spectrum.tscn")


func get_random_gradient_colors(color_count: int):
	
	var setting_game_color_theme: bool = false 
	
	# za barvno shemo igre ... pomeni, da se kliče iz settingsov
	if color_count == 0: 
		setting_game_color_theme = true
		color_count = 320
		
	# grebam texturo spectruma
	spectrum_rect = spectrum_texture_scene.instance()
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()

	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	var new_color_scheme_split_size: float = spectrum_texture_width / color_count

	# PRVA barva 
	var random_split_index_1: int = randi() % int(color_count)
	var random_color_position_x_1: float = random_split_index_1 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_1: Color = spectrum_image.get_pixel(random_color_position_x_1, 0) # barva na lokaciji v spektrumu
	
	# DRUGA barva
	var random_split_index_2: int = randi() % int(color_count)
	var random_color_position_x_2: float = random_split_index_2 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_2: Color = spectrum_image.get_pixel(random_color_position_x_2, 0) # barva na lokaciji v spektrumu	
	
	# TRETJA barva 
	var random_split_index_3: int = randi() % int(color_count)
	var random_color_position_x_3: float = random_split_index_3 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_3: Color = spectrum_image.get_pixel(random_color_position_x_3, 0) # barva na lokaciji v spektrumu

	# GRADIENT
	
	# za barvno shemo igre
	if setting_game_color_theme:
		
		# setam gradient barvne sheme (node)
		game_color_theme_gradient = gradient_texture.get_gradient()
		game_color_theme_gradient.set_color(0, random_color_1)
		game_color_theme_gradient.set_color(1, random_color_2)
		game_color_theme_gradient.set_color(2, random_color_3)
		
		return	game_color_theme_gradient # settingsi rabijo barvno temo 
	
	# za barvno shemo levela
	else: # ostali rabijo barve
	
		# setam gradient barvne sheme (node)
		var level_scheme_gradient: Gradient = gradient_texture.get_gradient()
		level_scheme_gradient.set_color(0, random_color_1)
		level_scheme_gradient.set_color(1, random_color_2)
		level_scheme_gradient.set_color(2, random_color_3)

		# naberem barve glede na število potrebnih barv
		var split_colors: Array
		var color_split_offset: float = 1.0 / color_count
		for n in color_count:
			var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
			var color = level_scheme_gradient.interpolate(color_position_x) # barva na lokaciji v spektrumu
			split_colors.append(color)	
		
		return	split_colors # level rabi že izbrane barve
	
	
func get_spectrum_colors(color_count: int):
	randomize()
	
	# grabam texturo spectruma
	if not spectrum_rect:
		spectrum_rect = spectrum_texture_scene.instance()
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()

	# izžrebam barvi gradienta iz nastavljenega spektruma
	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	var new_color_scheme_split_size: float = spectrum_texture_width / color_count
	
	# naberem barve glede na število potrebnih barv
	var split_colors: Array
	var color_split_offset: float = spectrum_texture_width / color_count
	for n in color_count:
		var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
		var color = spectrum_image.get_pixel(color_position_x, 0) # barva na lokaciji v spektrumu
		split_colors.append(color)
	
	return	split_colors
	
	
# BUTTONS --------------------------------------------------------------------------------------------------

# vsak hover, postane focus
# dodam sounde na focus
# dodam sounde na confirm, cancel, quit
# dodam modulate na Checkbutton focus


func _on_SceneTree_node_added(node: Control):
	
	if node is BaseButton or node is HSlider:
		connect_to_button(node)


func connect_buttons(root: Node): # recursively connect all buttons
	
	for child in root.get_children():
		if child is BaseButton or child is HSlider:
			connect_to_button(child)
		connect_buttons(child)


func connect_to_button(button):
	
	# pressing btnz
	if button is CheckButton:
		button.connect("toggled", self, "_on_button_toggled")
	elif not button is HSlider:
		button.connect("pressed", self, "_on_button_pressed", [button])
	
	# hover and focus
	button.connect("mouse_entered", self, "_on_control_hovered", [button])
	button.connect("focus_entered", self, "_on_control_focused", [button])
	button.connect("focus_exited", self, "_on_control_unfocused", [button])


func _on_button_pressed(button: BaseButton):
#	print("PRESSED ", button)
	if button.name == "BackBtn":
		Global.sound_manager.play_gui_sfx("btn_confirm")
	elif button.name == "QuitBtn" or button.name == "CancelBtn":
		Global.sound_manager.play_gui_sfx("btn_cancel")
	else:
		Global.sound_manager.play_gui_sfx("btn_confirm")

	
func _on_button_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_control_hovered(control: Control):
	
	if not control.has_focus():		
		control.grab_focus()
		Global.sound_manager.play_gui_sfx("btn_focus_change")
		
				
func _on_control_focused(control: Control):
	
	Global.sound_manager.play_gui_sfx("btn_focus_change")
	# check btn color fix
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = Color.white


func _on_control_unfocused(control: Control):
	
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = color_gui_gray # Color.white


func grab_focus_no_sfx(control_to_focus: Control):
	
	allow_focus_sfx = false
	control_to_focus.grab_focus()
	allow_focus_sfx = true
