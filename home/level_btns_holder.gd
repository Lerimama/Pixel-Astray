extends GridContainer

var unfocused_color: Color = Global.color_almost_black_pixel
var btn_colors: Array
var all_level_btns: Array # naberem ob spawnu
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
			new_level_btn.add_to_group(Global.group_critical_btns)
			all_level_btns.append(new_level_btn)
		elif tilemap_path_level_number == Profiles.sweeper_level_tilemap_paths.size():
			the_pixel_astray_level_btn.add_to_group(Global.group_menu_confirm_btns)
			the_pixel_astray_level_btn.add_to_group(Global.group_critical_btns)
			all_level_btns.append(the_pixel_astray_level_btn)

	var column_number: int = round(sqrt(Profiles.sweeper_level_tilemap_paths.size()))
	columns = column_number


func set_level_btns():

	color_level_btns()

	# opredelim solved gumbe
	var btns_with_score: Array = []

	# za vsak level btn preverim , če je v filetu prvi skor > 0
	for btn_count in all_level_btns.size():
#	for count in Profiles.sweeper_level_tilemap_paths.size():
#		printt("LB", Profiles.sweeper_level_tilemap_paths.size(), all_level_btns.size())

		# poimenujem gumb in barvam ozadje
		var btn = all_level_btns[btn_count]
		var btn_level_number: int = btn_count + 1
		btn.name = "Sweeper%02dBtn" % btn_level_number
		btn.self_modulate = unfocused_color

		if not btn == the_pixel_astray_level_btn: # če level ni pixel astray, ima številko (ločeno zaradi pixel astray napisa
			btn.get_node(locked_label_path).text = "%02d" % btn_level_number
			btn.get_node(unlocked_label_path).text = "%02d" % btn_level_number

		# preverjam HScore > 0
		var level_hs_line: Array = get_btn_highscore(btn_level_number)
		var current_hs_time_int: int = int(level_hs_line[0])
		# če je score
		if current_hs_time_int > 0:
			btn.get_node(record_label_path).text = get_btn_highscore(btn_level_number)[0]
			btn.get_node(owner_label_path).text = "by " + get_btn_highscore(btn_level_number)[1]
			# pokažem, obarvam
			btn.get_node(unlocked_label_path).modulate = btn_colors[btn_count]
			btn.get_node(record_label_path).modulate = btn_colors[btn_count]
			btn.get_node(owner_label_path).modulate = btn_colors[btn_count]
			btn.get_node(unlocked_label_path).show()
			btn.get_node(record_label_path).show()
			btn.get_node(owner_label_path).show()
			# skrijem
			btn.get_node(locked_label_path).hide()
		# če ni scora
		else:
			# pokažem, obarvam
			btn.get_node(locked_label_path).modulate = btn_colors[btn_count]
			btn.get_node(locked_label_path).show()
			# skrijem
			btn.get_node(unlocked_label_path).hide()
			btn.get_node(record_label_path).hide()
			btn.get_node(owner_label_path).hide()

	the_pixel_astray_level_btn.raise() # move to "top layer" ... to bottom of node tree


func get_btn_highscore(btn_level_number: int):

	var btn_level_game_data = Profiles.game_data_sweeper
	btn_level_game_data["level"] = btn_level_number

	var current_highscore_line: Array = Global.data_manager.get_top_highscore(btn_level_game_data)

	var current_highscore_clock = 0
	# če je < 0, ga ne formatiram (bolje vem, da je "scoreless")
	if current_highscore_line[0] > 0:
		current_highscore_clock = Global.get_clock_time(current_highscore_line[0])

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

	var sweeper_game_name: String = "Sweeper %02d" % (pressed_btn_index + 1)
	Analytics.save_game_data(sweeper_game_name)

