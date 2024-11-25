extends Node2D


var get_it_time: float = 1 # tajming za dojet določene faze igre
var throttler_msec_threshold: int = 5 # koliko msec je še na voljo v frejmu, ko raje premaknem na naslednji frame

# node ref
var main_node = null
var game_arena = null # arena
# managers
var sound_manager = null
var data_manager = null
var game_manager = null # tudi za intro
var anal_manager = null
# gui
var current_tilemap = null
var hud = null
var start_countdown = null
var gameover_gui = null
var tutorial_gui = null
# camera
var intro_camera = null
var game_camera = null

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap" # defender in patterns
var group_ghosts = "Ghosts"
var group_menu_confirm_btns = "Menu confirm btns"
var group_menu_cancel_btns = "Menu cancel btns"

# colors
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")
var color_orange: Color = Color("#ff9990")
var color_purple: Color = Color("#c774f5")
# gui colors
var color_almost_white_text: Color = Color("#f5f5f5") # če spremeniš tukaj, moraš tudi v temi
var color_gui_gray: Color = Color("#78ffffff") # siv text s transparenco (ikone ...#838383) ... v kodi samo na btn defocus
var color_hud_text: Color = color_almost_white_text # za vse, ki modulirajo barvo glede na + ali -
var color_btn_disabled: Color = Color("#32ffffff")
var color_btn_enabled: Color = Color("#78ffffff")
var color_btn_hover: Color = Color("#f0f0f0")
var color_btn_focus: Color = Color("#ffffff")
var color_thumb_hover: Color = Color("#232323")
# pixel colors
var color_almost_black_pixel: Color = Color("#141414")
var color_dark_gray_pixel: Color = Color("#232323")#Color("#323232") # start normal
var color_white_pixel: Color = Color(1, 1, 1, 1.22)
var strays_on_screen: Array = [] # za stray position indikatorje
# tilemap colors
var color_wall: Color = Color("#141414") # Color("#232323")
var color_edge: Color = Color.black
var color_floor: Color = Color("#20ffffff")
var color_background: Color = Color.black

# hs / lootlocker
var default_highscore_line_name: String = "Empty score line" # se uporabi, če še ni nobenega v filetu


func _ready():

	randomize() # custom color scheme

	# when _ready is called, there might already be nodes in the tree, so connect all existing buttons
	connect_buttons(get_tree().root)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func get_all_nodes_in_node(node_to_check: Node = get_tree().root, all_nodes_of_nodes: Array = []):

	all_nodes_of_nodes.push_back(node_to_check)

	for node in node_to_check.get_children():
		all_nodes_of_nodes = get_all_nodes_in_node(node)

	print("Nodes in node ",  all_nodes_of_nodes.size())
	return all_nodes_of_nodes


func detect_collision_in_direction(direction_to_check: Vector2, raycast_node: RayCast2D, raycast_length: float = 45):

	if direction_to_check == Vector2.ZERO:
		raycast_node.cast_to = Vector2.ZERO
	else:
		raycast_node.cast_to = raycast_length * direction_to_check
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()


func snap_to_nearest_grid(global_position_to_snap: Vector2):

	var floor_cells: Array = current_tilemap.all_floor_tiles_global_positions
	var cell_size_x: float = current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa

	# adaptacija s pixla na grid
	var current_position_on_grid: Vector2 = Vector2(global_position_to_snap.x - cell_size_x/2, global_position_to_snap.y - cell_size_x/2)
	# snepana grid pozicija
	var snapped_grid_position = current_position_on_grid.snapped(Vector2.ONE * cell_size_x)
	# adaptacija z grida na pixel
	var snapped_pixel_global_position: Vector2 = Vector2(snapped_grid_position.x + cell_size_x/2, snapped_grid_position.y + cell_size_x/2)

	return snapped_pixel_global_position


func get_clock_time(hundreds_to_split: float): # cele stotinke ali ne cele sekunde

	# če so podane stotinke, pretvorim v sekunde z decimalko
	var seconds_to_split: float = hundreds_to_split / 100

	# če so podane sekunde
	var minutes: int = floor(seconds_to_split / 60) # vse cele sekunde delim s 60
	var seconds: int = floor(seconds_to_split) - minutes * 60 # vse sekunde minus sekunde v celih minutah
	var hundreds: int = round((seconds_to_split - floor(seconds_to_split)) * 100) # decimalke množim x 100 in zaokrožim na celo

	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if hundreds == 100:
		seconds += 1
		hundreds = 0

	# return [minutes, seconds, hundreds]
	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + ":" + "%02d" % hundreds

	return time_on_clock


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


var current_scene = null # za scene switching


func release_scene(scene_node): # release scene

	scene_node.propagate_call("queue_free", []) # kvefrijam vse node v njem

	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)


func _free_scene(scene_node):

	if OS.is_debug_build():  # debug OS mode
		#		print("SCENE RELEASED (in next step): ", scene_node)
		pass
	scene_node.free()


func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)

	current_scene = scene_resource.instance()

	if OS.is_debug_build():  # debug OS mode
		#		print("SCENE INSTANCED: ", current_scene)
		pass
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root

	if OS.is_debug_build():  # debug OS mode
		#		print("SCENE ADDED: ", current_scene)
		#		print("--- new scene ---")
		pass
	return current_scene


# COLORS ------------------------------------------------------------------------------------------------


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
# sounde na focus
# sounde na confirm, cancel, quit
# modulate na Checkbutton focus
# nofx focus


var allow_focus_sfx: bool = true # focus no-sounds
var current_focused_control#: Control # samo zaradi zaznavanja toggle batnov


# naberi gumbe in jih poveži
func _on_SceneTree_node_added(node: Control):

	if node is BaseButton or node is HSlider:
		connect_to_button(node)

# naberi gumbe v globino in jih poveži
func connect_buttons(root: Node):

	for child in root.get_children():
		if child is BaseButton or child is HSlider:
			connect_to_button(child)

# poveži gumb
func connect_to_button(button):

	# klik akcija
	# čekbox
	if button is CheckButton:
		button.connect("toggled", self, "_on_button_toggled")
	# vsak button, ki ni slider
	#	elif button is BaseButton:
	elif button is HSlider:
		pass
	else:
		button.connect("pressed", self, "_on_button_pressed", [button])

	# hover in fokus
	button.connect("mouse_entered", self, "_on_control_hovered", [button])
	button.connect("focus_entered", self, "_on_control_focused", [button])
	button.connect("focus_exited", self, "_on_control_unfocused", [button])


# on confirm and cancel
func _on_button_pressed(button: BaseButton):

	Analytics.save_ui_click(button)

	# ker ti gumbi peljejo na nov ekran, po njihovem kliku
	if button.is_in_group(Global.group_menu_confirm_btns):
		Global.sound_manager.play_gui_sfx("btn_confirm")
		get_viewport().set_disable_input(true) # prevent dablklik

	elif button.is_in_group(Global.group_menu_cancel_btns):
		Global.sound_manager.play_gui_sfx("btn_cancel")
		get_viewport().set_disable_input(true) # prevent dablklik

	if button is OptionButton: # ko odpreš dropdown je confirm sound:
		Global.sound_manager.play_gui_sfx("btn_focus_change")


# on toggle
func _on_button_toggled(button_pressed: bool) -> void:

	if str(current_focused_control) == "[Deleted Object]": # anti home_out nek toggle btn
		pass
	else:
		if button_pressed:
			Global.sound_manager.play_gui_sfx("btn_confirm")
		else:
			Global.sound_manager.play_gui_sfx("btn_cancel")

		if current_focused_control: # debug, da lahko štartam z igro ... zazih
			Analytics.save_ui_click([current_focused_control, button_pressed])


# on hover
func _on_control_hovered(control: Control):

	if not control.has_focus() and not control is ColorRect:
		control.grab_focus()

# on focus
func _on_control_focused(control: Control):
	#	printt("Control focused", control)

	current_focused_control = control

	if allow_focus_sfx:
		Global.sound_manager.play_gui_sfx("btn_focus_change")

	# check btn color fix
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = Color.white


# on defocus - barvanje settings gumbi
func _on_control_unfocused(control: Control):
	#	printt("Control unfocused", control)

	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = color_gui_gray # Color.white

# nofx focus
func grab_focus_nofx(control_to_focus: Control):
	#	printt("No sfx focus", control_to_focus, allow_focus_sfx)

	# reseta na fokus
	allow_focus_sfx = false
	control_to_focus.grab_focus()
	set_deferred("allow_focus_sfx", true)
