extends GridContainer

var unfocused_color: Color = Global.color_almost_black_pixel
var btn_colors: Array
var solved_sweeper_btns: Array

var unlocked_label_path: String = "VBoxContainer/Label"
var locked_label_path: String = "VBoxContainer/LabelLocked"
var record_label_path: String = "VBoxContainer/Record"
var owner_label_path: String = "VBoxContainer/Owner"

var all_level_btns: Array

#onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
#onready var solutions_btn: CheckButton = $SolutionsBtn
#onready var btn_grid_container: Control = $SelectLevelBtnsHolder
onready var pixel_astray_level_btn: Button = $PixelAstrayLevelBtn
onready var LevelBtn: PackedScene = preload("res://home/level_btn.tscn")

var select_level_btns_holder_parent # določim od zunaj

		
func spawn_level_btns():

	# zbrišem vzorčne gumbe v holderju
	for btn in get_children():
		if not btn == pixel_astray_level_btn:
			btn.queue_free()
	
	# spawnam nove gumbe za vsak tilemap_path
	for tilemap_path in Profiles.sweeper_level_tilemap_paths:
		var tilemap_path_index: int = Profiles.sweeper_level_tilemap_paths.find(tilemap_path)
		var tilemap_path_level_number: int = tilemap_path_index + 1
		
		# spawnam vse razen zadnjega, ki je že notri
		if tilemap_path_level_number < Profiles.sweeper_level_tilemap_paths.size():
			var new_level_btn: Button = LevelBtn.instance()
			add_child(new_level_btn)
			new_level_btn.add_to_group(Global.group_menu_confirm_btns)
			all_level_btns.append(new_level_btn)
		elif tilemap_path_level_number == Profiles.sweeper_level_tilemap_paths.size():
			pixel_astray_level_btn.add_to_group(Global.group_menu_confirm_btns)
			all_level_btns.append(pixel_astray_level_btn)
		
	var column_number: int = round(sqrt(Profiles.sweeper_level_tilemap_paths.size()))
	columns = column_number

	
func set_level_btns():
	
	# naberem gumbe in barve
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(all_level_btns.size())
	else:			
		var color_split_offset: float = 1.0 / all_level_btns.size()
		for btn_count in all_level_btns.size():
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)	
	
	# poimenujem gumbe in obarvam solved 
	var solved_levels: Array = Global.data_manager.read_solved_status_from_file(Profiles.game_data_sweeper)
	solved_sweeper_btns = []
	
	for btn in all_level_btns:
		var btn_index: int = all_level_btns.find(btn)
		var btn_level_number: int = btn_index + 1
		# osnovna barva ozadja
		btn.self_modulate = unfocused_color
		# level name
		# če level ni pixel astray, ima številko (ločeno zaradi pixel astray napisa
		if not btn == pixel_astray_level_btn: 
			btn.get_node(locked_label_path).text = "%02d" % btn_level_number
			btn.get_node(unlocked_label_path).text = "%02d" % btn_level_number
		# če je rešen prikažem druge labele, če ni, je samo locked label
		if btn_level_number in solved_levels:
			solved_sweeper_btns.append(btn)
			# skrijem
			btn.get_node(locked_label_path).hide()
			# zapišem
			btn.get_node(record_label_path).text = get_btn_highscore(btn_level_number)[0]
			btn.get_node(owner_label_path).text = "by " + get_btn_highscore(btn_level_number)[1]
			# pokažem
			btn.get_node(unlocked_label_path).modulate = btn_colors[btn_index]
			btn.get_node(unlocked_label_path).show()
			btn.get_node(record_label_path).modulate = btn_colors[btn_index]
			btn.get_node(record_label_path).show()
			btn.get_node(owner_label_path).modulate = btn_colors[btn_index]
			btn.get_node(owner_label_path).show()
		else:
			# skrijem
			btn.get_node(unlocked_label_path).hide()
			btn.get_node(record_label_path).hide()
			btn.get_node(owner_label_path).hide()
			btn.get_node(locked_label_path).modulate = btn_colors[btn_index]
			# btn.get_node(locked_label_path).modulate = Global.color_gui_gray
			btn.get_node(locked_label_path).show()
		
	pixel_astray_level_btn.raise() # move the Blood node to just above the Floor in the tr


func get_btn_highscore(btn_level_number: int):
	
	var btn_level_game_data = Profiles.game_data_sweeper
	btn_level_game_data["level"] = btn_level_number
	
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(btn_level_game_data)
	
	var current_highscore_clock = Global.get_clock_time(current_highscore_line[0])
	var current_highscore_owner: String = current_highscore_line[1]
	
	return [current_highscore_clock, current_highscore_owner]


func recolor_level_btns(): 
	btn_colors.clear()
	# naberem gumbe in barve
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(all_level_btns.size())
	else:			
		var color_split_offset: float = 1.0 / all_level_btns.size()
		for btn_count in all_level_btns.size():
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)	
	

# akcije ---------------------------------------------------------------------------------------------


func connect_level_btns():
	
	for btn in get_children():
		btn.connect("mouse_entered", self, "_on_btn_hovered_or_focused", [btn])
		btn.connect("focus_entered", self, "_on_btn_hovered_or_focused", [btn])
		btn.connect("focus_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
		# btn.connect("mouse_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
		btn.connect("pressed", self, "_on_btn_pressed", [btn])
		
		
func _on_btn_hovered_or_focused(btn):

	btn.self_modulate = Global.color_thumb_hover
	btn.get_node(unlocked_label_path).modulate = Color.white
	btn.get_node(locked_label_path).modulate = Color.white
	btn.get_node(record_label_path).modulate = Color.white
	btn.get_node(owner_label_path).modulate = Color.white
	
	# v1 barvanje na hover
	#	btn.self_modulate = btn_colors[all_level_btns.find(btn)]
	#	btn.get_node(unlocked_label_path).modulate = Color.white
	#	btn.get_node(locked_label_path).modulate = Color.white
	#	btn.get_node(record_label_path).modulate = Color.white
	#	btn.get_node(owner_label_path).modulate = Color.white
	
	
func _on_btn_unhovered_or_unfocused(btn):
	
	btn.self_modulate = Global.color_almost_black_pixel
	btn.get_node(unlocked_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(record_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(owner_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(locked_label_path).modulate = btn_colors[all_level_btns.find(btn)]
#		btn.get_node(record_label_path).modulate = Global.color_gui_gray

	# v1 barvanje
	#	btn.self_modulate = Global.color_almost_black_pixel
	#	if solved_sweeper_btns.has(btn):
	#		btn.get_node(unlocked_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	#		btn.get_node(record_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	#		btn.get_node(owner_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	#	else:
	#		btn.get_node(locked_label_path).modulate = Global.color_gui_gray
	#		btn.get_node(record_label_path).modulate = Global.color_gui_gray
	
	
func _on_btn_pressed(btn):
	var pressed_btn_index: int = get_children().find(btn)
	select_level_btns_holder_parent.play_selected_level(pressed_btn_index + 1)
		
		
		

# btn background tilemaps
	
#func set_btn_tilemap(btn: Button):
#
#		var BtnTilemap: PackedScene
#		var tilemap_position_adapt: float
#		match btn.name:
#			"01":
#				BtnTilemap = preload("res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn")
#				tilemap_position_adapt = 0
#			"02":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_02.tscn")
#				tilemap_position_adapt = 0
#			"03":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_03.tscn")
#				tilemap_position_adapt = 0
#			"04":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_04.tscn")
#				tilemap_position_adapt = 2
#			"05":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_05.tscn")
#				tilemap_position_adapt = 2
#			"06":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_06.tscn")
#				tilemap_position_adapt = 2
#			"07":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_07.tscn")
#				tilemap_position_adapt = 2
#			"08":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_08.tscn")
#				tilemap_position_adapt = 2
#			"09":
#				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_09.tscn")
#				tilemap_position_adapt = 2
#
#		var tilemap_scale_div: float = 8
#		var cell_size_x: float = 32
#
#		var new_btn_tilemap = BtnTilemap.instance()
#		new_btn_tilemap.scale /=  tilemap_scale_div
#		new_btn_tilemap.show_behind_parent = true
##		new_btn_tilemap.z_index = -1
#		btn.add_child(new_btn_tilemap)
#
#		var tilemap_reduced_size: Vector2 = new_btn_tilemap.get_used_rect().size * cell_size_x/2 / tilemap_scale_div
#		# sredinska pozicija
#		new_btn_tilemap.position.x = btn.rect_size.x/2 - tilemap_reduced_size.x# - btn.rect_size.x
#		new_btn_tilemap.position.y = btn.rect_size.y/2 - tilemap_reduced_size.y
#		# daptacija zamika pixilov
#		new_btn_tilemap.position.x += tilemap_position_adapt
#		new_btn_tilemap.position.y += tilemap_position_adapt
#		# barvanje 
#		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.edge_tile_id, Color(1,1,1,0))
#		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.edge_tile_id, Color.red)
#		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.floor_tile_id, Color(1,1,1,0))
#		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.spawn_stray_tile_id, Color.white) # prava barva se seta v select levels, v igri se jo itak zamenja s tlemi
#
#		new_btn_tilemap.set_process_input(false)
#
