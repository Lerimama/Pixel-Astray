extends GridContainer

var unfocused_color: Color = Global.color_almost_black_pixel
var btn_colors: Array
var all_level_btns: Array
var select_level_btns_holder_parent # določim od zunaj

var unlocked_label_path: String = "VBoxContainer/Label"
var locked_label_path: String = "VBoxContainer/LabelLocked"
var record_label_path: String = "VBoxContainer/Record"
var owner_label_path: String = "VBoxContainer/Owner"

onready var the_pixel_astray_level_btn: Button = $PixelAstrayLevelBtn
onready var LevelBtn: PackedScene = preload("res://home/level_btn.tscn")

		
func spawn_level_btns():

	# zbrišem vzorčne gumbe v holderju
	for btn in get_children():
		if not btn == the_pixel_astray_level_btn:
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
			the_pixel_astray_level_btn.add_to_group(Global.group_menu_confirm_btns)
			all_level_btns.append(the_pixel_astray_level_btn)
		
	var column_number: int = round(sqrt(Profiles.sweeper_level_tilemap_paths.size()))
	columns = column_number

	
func set_level_btns():
	
	color_level_btns()
	
	# opredelim solved gumbe 
	var solved_levels: Array = []
	
	# za vsak level btn preverim , če je v filetu prvi skor > 0
	for count in Profiles.sweeper_level_tilemap_paths.size(): 
		var sweeper_game_data: Dictionary = Profiles.game_data_sweeper.duplicate()
		sweeper_game_data["level"] = count + 1
		var level_highscores: Dictionary = Global.data_manager.read_highscores_from_file(sweeper_game_data)
		# pridobim skor linijie
		var scoreline_player_name_as_key: String = level_highscores["01"].keys()[0]
		var scoreline_score: float = level_highscores["01"][scoreline_player_name_as_key]
		if scoreline_score > 0:
			solved_levels.append(sweeper_game_data["level"])
	
	# napolnem in obarvam gumbe
	for btn in all_level_btns:
		var btn_index: int = all_level_btns.find(btn)
		var btn_level_number: int = btn_index + 1
		# osnovna barva ozadja
		btn.self_modulate = unfocused_color
		# level name
		# če level ni pixel astray, ima številko (ločeno zaradi pixel astray napisa
		if not btn == the_pixel_astray_level_btn: 
			btn.get_node(locked_label_path).text = "%02d" % btn_level_number
			btn.get_node(unlocked_label_path).text = "%02d" % btn_level_number
		# če je rešen prikažem druge labele, če ni, je samo locked label
		if btn_level_number in solved_levels:
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
			btn.get_node(locked_label_path).show()
		
	the_pixel_astray_level_btn.raise() # move to "top layer" ... to bottom of node tree


func get_btn_highscore(btn_level_number: int):
	
	var btn_level_game_data = Profiles.game_data_sweeper
	btn_level_game_data["level"] = btn_level_number
	
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(btn_level_game_data)
	
	var current_highscore_clock = Global.get_clock_time(current_highscore_line[0])
	var current_highscore_owner: String = current_highscore_line[1]
	
	return [current_highscore_clock, current_highscore_owner]


func color_level_btns(): 
	
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
		btn.connect("pressed", self, "_on_btn_pressed", [btn])
		
		
func _on_btn_hovered_or_focused(btn):

	btn.self_modulate = Global.color_thumb_hover
	btn.get_node(unlocked_label_path).modulate = Color.white
	btn.get_node(locked_label_path).modulate = Color.white
	btn.get_node(record_label_path).modulate = Color.white
	btn.get_node(owner_label_path).modulate = Color.white
	
	
func _on_btn_unhovered_or_unfocused(btn):
	
	btn.self_modulate = Global.color_almost_black_pixel
	btn.get_node(unlocked_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(record_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(owner_label_path).modulate = btn_colors[all_level_btns.find(btn)]
	btn.get_node(locked_label_path).modulate = btn_colors[all_level_btns.find(btn)]

	
func _on_btn_pressed(btn):
	var pressed_btn_index: int = get_children().find(btn)
	select_level_btns_holder_parent.play_selected_level(pressed_btn_index + 1)
		
