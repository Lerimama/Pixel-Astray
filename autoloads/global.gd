extends Node2D


# VARIABLE -----------------------------------------------------------------------------------------------------

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
const SAVING = "saving"
# colors
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")
var color_orange: Color = Color("#ff9990")
var color_purple: Color = Color("#c774f5")

# tilemap colors
var color_wall: Color = Color("#141414") # Color("#232323")
var color_edge: Color = Color.black
var color_floor: Color = Color("#20ffffff")
var color_background: Color = Color.black

# gui colors
var color_almost_white_text: Color = Color("#f5f5f5") # če spremeniš tukaj, moraš tudi v temi
var color_gui_gray: Color = Color("#78ffffff") # siv text s transparenco (ikone ...#838383) ... v kodi samo na btn defocus
var color_hud_text: Color = color_almost_white_text # za vse, ki modulirajo barvo glede na + ali -

# pixel colors
var color_almost_black_pixel: Color = Color("#141414") 
var color_dark_gray_pixel: Color = Color("#232323")#Color("#323232") # start normal
var color_white_pixel: Color = Color(1, 1, 1, 1.22)
var color_thumb_hover: Color = Color("#232323")
var strays_on_screen: Array = [] # za stray position indikatorje

var allow_focus_sfx: bool = false # focus sounds

# FUNKCIJE -----------------------------------------------------------------------------------------------------


func _ready(): 
	
	randomize() # custom color scheme
	
	# when _ready is called, there might already be nodes in the tree, so connect all existing buttons
	connect_buttons(get_tree().root)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func get_all_nodes_in_node(node_to_check: Node = get_tree().root, all_nodes_of_nodes: Array = []):
	
	all_nodes_of_nodes.push_back(node_to_check)
	
	for node in node_to_check.get_children():
		all_nodes_of_nodes = get_all_nodes_in_node(node)
	
	print("Nodes in node",  all_nodes_of_nodes.size())
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
	print("SCENE RELEASED (in next step): ", scene_node)	
	scene_node.free()
	

func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	print("SCENE INSTANCED: ", current_scene)
	
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root
	print("SCENE ADDED: ", current_scene)	
	print("---")
	
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


# FILETI in FOLDERJI -----------------------------------------------------------------------------------------


func get_folder_contents(rootPath: String, files_only: bool = true) -> Array:
	
	var files = []
	var folders = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, true)
		_add_folder_contents(dir, files, folders, files_only)
	else:
		push_error("An error occurred when trying to access the path.")

	if files_only:
		return files
	else:
		return [files, folders]
	
	
func _add_folder_contents(dir: Directory, files: Array, folders: Array, files_only: bool):
	
	var file_name = dir.get_next() # zaradi pogoja je setan že tukaj, potem pa se aplcira pravo ime ... zato se na koncu doda en prazen element

	# dokler ne naletim na "prazen" filet, beležim filete
	while (file_name != ""):
		# za obe varianti ponovim celo kodo, da lahko uporabim tudi ločeno
		
		# var path = dir.get_current_dir() + "/" + file_name
		var path = dir.get_current_dir() + file_name
	
		# folder
		if dir.current_is_dir() and not files_only:
			#			print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			folders.append(path)
			_add_folder_contents(subDir, files, folders, true)
			file_name = dir.get_next()
			
		# filet
		else:
			#			print("Found file: %s" % path)
			files.append(path)
			file_name = dir.get_next()
			
		#	if files_only: # v tem primeru se mi doda en prazen element, pa ga vržem ven
		#		files.pop_back()	
	
	dir.list_dir_end()


# BUTTONS --------------------------------------------------------------------------------------------------

# vsak hover, postane focus
# dodam sounde na focus
# dodam sounde na confirm, cancel, quit
# dodam modulate na Checkbutton focus

# naberi gumbe in jih poveži
func _on_SceneTree_node_added(node: Control):

	if node is BaseButton or node is HSlider:
		connect_to_button(node)


# naberi gumbe v globino gumbe in jih poveži
func connect_buttons(root: Node):

	for child in root.get_children():
		if child is BaseButton or child is HSlider:
			connect_to_button(child)


#  poveži gumb
func connect_to_button(button):

	# klik akcija
	# čekbox
	if button is CheckButton:
		button.connect("toggled", self, "_on_button_toggled")
	# vsak button, ki ni slider
	elif not button is HSlider:
		button.connect("pressed", self, "_on_button_pressed", [button])

	# hover in fokus
	button.connect("mouse_entered", self, "_on_control_hovered", [button])
	button.connect("focus_entered", self, "_on_control_focused", [button])
	button.connect("focus_exited", self, "_on_control_unfocused", [button])


# on confirm and cancel 
func _on_button_pressed(button: BaseButton):
	#	printt("Btn pressed", button)

	# ker ti gumbi peljejo na nov ekran, po njihovem kliku
	if button.is_in_group(Global.group_menu_confirm_btns):
		Global.sound_manager.play_gui_sfx("btn_confirm")
		set_deferred("allow_focus_sfx", false)
		get_viewport().set_disable_input(true) # anti dablklik
	elif button.is_in_group(Global.group_menu_cancel_btns):
		Global.sound_manager.play_gui_sfx("btn_cancel")
		set_deferred("allow_focus_sfx", false)
		get_viewport().set_disable_input(true) # anti dablklik


# on toggle	
func _on_button_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")

# on hover
func _on_control_hovered(control: Control):
	# izločim sounde za select game ozadja
	#	if control is ColorRect:
	#		return
		
#	if not control.has_focus() and control is Button:		
	if not control.has_focus() and not control is ColorRect:		
		control.grab_focus()

# on focus
func _on_control_focused(control: Control):
	#	printt("Control focused", control)

	Global.sound_manager.play_gui_sfx("btn_focus_change")

	if not allow_focus_sfx:
		set_deferred("allow_focus_sfx", true)

	# check btn color fix
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = Color.white

# on defocus - barvanje settings gumbi
func _on_control_unfocused(control: Control):
	#	printt("Control unfocused", control)

	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = color_gui_gray # Color.white


func focus_without_sfx(control_to_focus: Control):
	#	printt("No sfx focus", control_to_focus, allow_focus_sfx)

	# reseta na fokus
	allow_focus_sfx = false
	control_to_focus.grab_focus()

	
# CALL THROTLED --------------------------------------------------------------


var _to_call: Array = []
var _mutex: Mutex = Mutex.new()

var _frame_budget_msec: = 0
var _frame_budget_threshold_msec: = 0
var _is_setup: bool = false

# youtube video https://www.youtube.com/watch?v=WLDM0tQ-XqE
# project settings / general / run > SceneTree spremeniš v CustomSceneTree
func _run_callables() -> void:
	
	if not _is_setup:
		push_error("Please run THROTTLER.start before calling")
		return
		
	var frame_budget_remaining_msec: = _frame_budget_msec	
	var frame_budget_used_msec: = 0
	var is_working: = true
	var call_count: = 0
	
	while is_working:
		var before: = Time.get_ticks_msec()	
		
		_mutex.lock()
		var entry = _to_call.pop_front()
		_mutex.unlock()
		
		var did_call: = false
		
		if entry:
			var callable = entry["callable"]
			var args = entry["args"]
			if callable != null and callable.is_valid():
#				if args != null and typeof(args) == TYPE_ARRAY and not args.is_empty():
				if args != null and typeof(args) == TYPE_ARRAY and not args.empty():
					callable.callv(args)
					pass
				else:
					callable.call()
				did_call = true
				call_count = +1
		
		var after: = Time.get_ticks_msec()
		var used: = after - before
		frame_budget_remaining_msec -= used
		frame_budget_used_msec += used	
		
		# stop running callables if none are left, or we are over budget
		if not did_call or frame_budget_remaining_msec < _frame_budget_threshold_msec:
			is_working = false
		
		if call_count > 0:
			print("THROTTLE BUDGET", _frame_budget_msec, frame_budget_used_msec, frame_budget_remaining_msec)

		
func start(frame_budget_mesec: int, frame_budget_threshold_msec: int) -> void:
	
	_frame_budget_msec = frame_budget_mesec
	_frame_budget_threshold_msec = frame_budget_threshold_msec
	_is_setup = true
		
		
func call_throttled(method, args: Array = []) -> void:
	
	printt ("CALABLE", method, args)
	var entry: Dictionary = {
		"callable" : method,
		"args": args,
	}

	_mutex.lock()
	_to_call.push_back(entry)
	_mutex.unlock()
	
