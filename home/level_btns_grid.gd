extends GridContainer


signal level_btns_are_set

var unfocused_color: Color = Global.color_almost_black
var btn_colors: Array
var all_level_btns: Array # naberem ob spawnu
var btns_holder_parent # določim od zunaj ... (GO ali home > select level)
var btns_are_set: bool = false
var solved_btns: Array = []

var record_content_path: String = "RecordContent"

var level_label_path: String = "RecordContent/LevelCount"
#var cup_icon_path: String = "LevelCount/CupIcon"
var record_label_path: String = "RecordContent/Record"
var owner_label_path: String = "RecordContent/Owner"
var tilemap_node_path: String = "TilemapHolder/LevelTilemap"
var tilemap_holder_node_path: String = "TilemapHolder"

var empty_score_string: String = "Waiting for\nfirst cleaning"
var content_focus_alpha: float = 0
var content_defocus_alpha: float = 1
var tilemap_focus_alpha: float = 1
var tilemap_defocus_alpha: float = 0.32

onready var LevelBtn: PackedScene = preload("res://home/level_btn.tscn")


func spawn_level_btns():

	# zbrišem vzorčne gumbe v holderju
	for btn in get_children():
		btn.queue_free()

	# spawnam nove gumbe za vsak tilemap_path
	for tilemap_path in Profiles.sweeper_level_tilemap_paths:
		var tilemap_path_index: int = Profiles.sweeper_level_tilemap_paths.find(tilemap_path)
		var tilemap_path_level_number: int = tilemap_path_index + 1

		# spawnam vse razen zadnjega, ki je že notri
		if tilemap_path_level_number <= Profiles.sweeper_level_tilemap_paths.size():
			var new_level_btn: Button = LevelBtn.instance()
			add_child(new_level_btn)
			new_level_btn.add_to_group(Batnz.group_critical_btns)
			all_level_btns.append(new_level_btn)

	var column_number: int = round(sqrt(Profiles.sweeper_level_tilemap_paths.size()))
	columns = column_number


func set_level_btns_content():


	if not btns_are_set:
		_set_color_scheme()

	for btn_count in all_level_btns.size():
		# poimenujem gumb in barvam ozadje
		var btn = all_level_btns[btn_count]
		var btn_level_number: int = btn_count + 1
		btn.name = "Sweeper%02dBtn" % btn_level_number
		# highscore ... preverjam HScore > 0
		var level_hs_line: Array = _get_btn_highscore(btn_level_number)
		var current_hs_time_int: int = int(level_hs_line[0])
		btn.get_node(record_label_path).show()
		btn.get_node(owner_label_path).show()
		btn.get_node(level_label_path).show()
#		btn.get_node(cup_icon_path).show()
		if current_hs_time_int > 0:
			solved_btns.append(btn)
			btn.get_node(level_label_path).text = "%02d" % btn_level_number
			btn.get_node(record_label_path).text = level_hs_line[0]
			btn.get_node(owner_label_path).text = "by " + level_hs_line[1]
		else:
			btn.get_node(owner_label_path).text = empty_score_string
#			btn.get_node(cup_icon_path).hide()
			btn.get_node(level_label_path).hide()
			btn.get_node(record_label_path).hide()

		# tilemap
		if not btns_are_set:
			_create_level_btn_tilemap(btn, btn_level_number)

	colorize_level_btns() # more bit spredaj

	_connect_level_btns()

#	if not btns_are_set: # _temp preprečim error s signalom
	emit_signal("level_btns_are_set")

	btns_are_set = true


func _set_color_scheme():

	btn_colors.clear()

	# splitam shemo s številom gumbov in jim določim barve
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(all_level_btns.size())
	else:
		var color_split_offset: float = 1.0 / all_level_btns.size()
		for btn_count in all_level_btns.size():
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)


func colorize_level_btns():

	if btns_are_set: # neka finta
		_set_color_scheme()

	# za vsak level btn preverim , če je v filetu prvi skor > 0
	for btn_count in all_level_btns.size():

		var btn = all_level_btns[btn_count]
		var btn_level_number: int = btn_count + 1

		btn.get_node(record_content_path).modulate = btn_colors[btn_count]
		btn.get_node(level_label_path).modulate = btn_colors[btn_count]
		btn.get_node(record_content_path).modulate.a = content_defocus_alpha

		btn.get_node(tilemap_node_path).modulate = btn_colors[btn_count]
		btn.get_node(tilemap_node_path).modulate.a = tilemap_defocus_alpha
		btn.self_modulate = Global.color_thumb_hover


func _create_level_btn_tilemap(level_btn: Button, btn_level_number: int):


		var sweeper_tilemap_path: String = "res://game/tilemaps/sweeper/tilemap_sweeper_%02d.tscn" % btn_level_number
		var BtnTilemap: PackedScene = load(sweeper_tilemap_path)

		_spawn_btn_tilemap(level_btn, BtnTilemap)


func _spawn_btn_tilemap(level_btn, BtnTilemap):

		var cell_size_x: float = 32

		var new_btn_tilemap = BtnTilemap.instance()
		new_btn_tilemap.name = "LevelTilemap"
		new_btn_tilemap.modulate.a = 0.5
		level_btn.get_node(tilemap_holder_node_path).add_child(new_btn_tilemap)

		# size
		var tilemap_size_div: float = level_btn.rect_size.x / (new_btn_tilemap.get_used_rect().size.x * cell_size_x)
		var tilemap_scal_fine_tune_div = 0.97 # razmerje med setano velikostjo in "remote" adaptacijo
		new_btn_tilemap.scale *= tilemap_size_div / tilemap_scal_fine_tune_div
		# position
		var tilemap_offset: Vector2 = Vector2.ONE * -3.2
		new_btn_tilemap.position += tilemap_offset

		# da hover pravilno deluje
		new_btn_tilemap.edge_holder.z_index = 0
		new_btn_tilemap.tilemap_background.hide()


func _get_btn_highscore(btn_level_number: int):

	var btn_level_game_data = Profiles.game_data_sweeper
	btn_level_game_data["level"] = btn_level_number

	var current_highscore_line: Array = Data.get_saved_highscore(btn_level_game_data)

	var current_highscore_clock = 0
	# če je < 0, ga ne formatiram (bolje vem, da je "scoreless")
	if current_highscore_line[0] > 0:
		current_highscore_clock = Global.get_clock_time(current_highscore_line[0])

	var current_highscore_owner: String = current_highscore_line[1]

	return [current_highscore_clock, current_highscore_owner]


func _connect_level_btns(connect_it: bool = true):

	for btn in get_children():
		if connect_it:
			if not btn.is_connected("mouse_entered", self, "_on_btn_hovered_or_focused"):
				btn.connect("mouse_entered", self, "_on_btn_hovered_or_focused", [btn])
			if not btn.is_connected("mouse_exited", self, "_on_btn_unhovered_or_unfocused"):
				btn.connect("mouse_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
			if not btn.is_connected("focus_entered", self, "_on_btn_hovered_or_focused"):
				btn.connect("focus_entered", self, "_on_btn_hovered_or_focused", [btn])
			if not btn.is_connected("focus_exited", self, "_on_btn_unhovered_or_unfocused"):
				btn.connect("focus_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
			if not btn.is_connected("pressed", self, "_on_btn_pressed"):
				btn.connect("pressed", self, "_on_btn_pressed", [btn])
		else:
			if btn.is_connected("mouse_entered", self, "_on_btn_hovered_or_focused"):
				btn.disconnect("mouse_entered", self, "_on_btn_hovered_or_focused")
			if btn.is_connected("mouse_exited", self, "_on_btn_unhovered_or_unfocused"):
				btn.disconnect("mouse_exited", self, "_on_btn_unhovered_or_unfocused")
			if btn.is_connected("focus_entered", self, "_on_btn_hovered_or_focused"):
				btn.disconnect("focus_entered", self, "_on_btn_hovered_or_focused")
			if btn.is_connected("focus_exited", self, "_on_btn_unhovered_or_unfocused"):
				btn.disconnect("focus_exited", self, "_on_btn_unhovered_or_unfocused")
			if btn.is_connected("pressed", self, "_on_btn_pressed"):
				btn.disconnect("pressed", self, "_on_btn_pressed")



#		if btn.is_connected("mouse_entered", self, "_on_btn_hovered_or_focused"):
#			btn.disconnect("mouse_entered", self, "_on_btn_hovered_or_focused")
#		if btn.is_connected("mouse_exited", self, "_on_btn_unhovered_or_unfocused"):
#			btn.disconnect("mouse_exited", self, "_on_btn_unhovered_or_unfocused")
#		if btn.is_connected("focus_entered", self, "_on_btn_hovered_or_focused"):
#			btn.disconnect("focus_entered", self, "_on_btn_hovered_or_focused")
#		if btn.is_connected("focus_exited", self, "_on_btn_unhovered_or_unfocused"):
#			btn.disconnect("focus_exited", self, "_on_btn_unhovered_or_unfocused")
#		if btn.is_connected("pressed", self, "_on_btn_pressed"):
#			btn.disconnect("pressed", self, "_on_btn_pressed")
#		btn.connect("mouse_entered", self, "_on_btn_hovered_or_focused", [btn])
#		btn.connect("mouse_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
#		btn.connect("focus_entered", self, "_on_btn_hovered_or_focused", [btn])
#		btn.connect("focus_exited", self, "_on_btn_unhovered_or_unfocused", [btn])
#		btn.connect("pressed", self, "_on_btn_pressed", [btn])


# BTNS ---------------------------------------------------------------------------------------------


func _on_btn_hovered_or_focused(btn):

	var btn_color: Color = btn_colors[all_level_btns.find(btn)]

	var fade_time: float = 0.2
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(btn.get_node(tilemap_node_path), "modulate:a", tilemap_focus_alpha, fade_time)
	fade_tween.parallel().tween_property(btn.get_node(record_content_path), "modulate:a", content_focus_alpha, fade_time)
	fade_tween.parallel().tween_property(btn, "self_modulate", btn_color, fade_time)


func _on_btn_unhovered_or_unfocused(btn):

	var btn_color: Color = btn_colors[all_level_btns.find(btn)]

	var fade_time: float = 0.2
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(btn.get_node(tilemap_node_path), "modulate:a", tilemap_defocus_alpha, fade_time)
	if solved_btns.has(btn):
		fade_tween.parallel().tween_property(btn.get_node(record_content_path), "modulate", Global.color_almost_white_text, fade_time)
	else:
		fade_tween.parallel().tween_property(btn.get_node(record_content_path), "modulate:a", content_defocus_alpha, fade_time)
	fade_tween.parallel().tween_property(btn, "self_modulate", Global.color_thumb_hover, fade_time)


func _on_btn_pressed(btn):

	var pressed_btn_index: int = get_children().find(btn)


	btns_holder_parent.play_selected_level(pressed_btn_index + 1)

	var sweeper_game_name: String = "Sweeper %02d" % (pressed_btn_index + 1)
#	Analytics.save_selected_game_data(sweeper_game_name) # ... povzroča eror preko update in post request



