extends GridContainer


signal level_btns_are_set

var game_key: int # na spawn button se napolne
var unfocused_color: Color = Global.color_almost_black
var btn_colors: Array
var all_level_btns: Array # naberem ob spawnu
var btns_holder_parent # določim od zunaj ... (GO ali home > select level)
var btns_are_set: bool = false
var solved_btns: Array = []
var btn_final_size: Vector2 = Vector2.ZERO # velikost gumba po koncu vseh risajzanj

# vsebina gumba (v taki obliki, ker še niso spawnani)
var record_holder_path: String = "RecordContent"
var level_name_path: String = "LevelName"
var tilemap_path: String = "TilemapHolder/LevelTilemap"
var tilemap_thumb_path: String = "TilemapHolder/LevelTilemap"
var tilemap_thumb_cover_path: String = "TilemapHolder/LevelTilemap/TilemapThumb/Cover"

onready var LevelBtn: PackedScene = preload("res://home/select_level/level_btn.tscn")


func spawn_level_btns(game_name_key: int):

	# zbrišem vzorčne gumbe v holderju
	for btn in get_children():
		btn.queue_free()

	game_key = game_name_key
	var game_tilemap_paths: Array = Profiles.tilemap_paths[game_key]
	var column_number: int = round(sqrt(game_tilemap_paths.size()+2))
	columns = column_number

	# spawnam nove gumbe za vsak tilemap_path
	for tilemap_index in game_tilemap_paths.size():
		var tilemap_path_level_number: int = tilemap_index + 1
		var new_level_btn: Button = LevelBtn.instance()
		add_child(new_level_btn)

		# props
		new_level_btn.add_to_group(Batnz.group_critical_btns)
		all_level_btns.append(new_level_btn)


func set_level_btns_content():

	var record_icon_path: String = "RecordContent/CupIcon"
	var record_score_path: String = "RecordContent/Record"
	var record_owner_path: String = "RecordContent/Owner"

	if not btns_are_set:
		_set_color_scheme()

	for btn_count in all_level_btns.size():
		# poimenujem gumb in barvam ozadje
		var btn = all_level_btns[btn_count]

		# btn name
		var game_tilemap_paths: Array = Profiles.tilemap_paths[game_key]
		var level_tilemap_path: String = game_tilemap_paths[btn_count]

		var level_name: String = Global.get_level_out_of_path(level_tilemap_path)
		btn.name = "LevelBtn_" + level_name

		# highscore ... preverjam HScore > 0
		var level_hs_line: Array = _get_btn_highscore(level_name)

		var current_hs_time_int: int = int(level_hs_line[0])

		btn.get_node(level_name_path).text = level_name
		btn.get_node(level_name_path).show()
		btn.get_node(record_owner_path).show()

		if current_hs_time_int > 0:
			solved_btns.append(btn)
			btn.get_node(record_score_path).text = level_hs_line[0]
			btn.get_node(record_owner_path).text = "by " + level_hs_line[1]
			btn.get_node(record_icon_path).show()
			btn.get_node(record_score_path).show()
		else:
			btn.get_node(record_owner_path).text = Profiles.game_text["btn_empty_score_string"]
			btn.get_node(record_icon_path).hide()
			btn.get_node(record_score_path).hide()

		# tilemap
		if not btns_are_set:
			_spawn_level_btn_tilemap(btn, btn_count)

	btn_final_size = Vector2.ZERO # reset

	#	yield(get_tree(), "idle_frame") # da zabeleži trenutne velikosti

	colorize_level_btns() # more bit spredaj
	_connect_level_btns()

	#	if not btns_are_set: # _temp preprečim error s signalom
	emit_signal("level_btns_are_set")

	btns_are_set = true


func colorize_level_btns():

	if btns_are_set: # neka finta
		_set_color_scheme()

	for btn_count in all_level_btns.size():
		var btn = all_level_btns[btn_count]
		btn.get_node(record_holder_path).modulate = btn_colors[btn_count]
		btn.get_node(tilemap_path).modulate = btn_colors[btn_count]
		btn.get_node(level_name_path).modulate = btn_colors[btn_count]

		_on_btn_unhovered_or_unfocused(btn)


func _spawn_level_btn_tilemap(level_btn: Button, btn_count: int):

		var game_tilemap_paths: Array = Profiles.tilemap_paths[game_key]
		var level_tilemap_path: String = game_tilemap_paths[btn_count]
		var BtnTilemap: PackedScene = load(level_tilemap_path)

		var new_btn_tilemap = BtnTilemap.instance()
		new_btn_tilemap.name = "LevelTilemap"
		level_btn.get_node("TilemapHolder").add_child(new_btn_tilemap)

		yield(get_tree(), "idle_frame") # da zabeleži trenutne velikosti

		# size
		var thumbnail_visible_rect: Vector2 = new_btn_tilemap.get_node("TilemapThumb/Background").rect_size - Vector2(64, 64)
		var thumbnail_visible_position: Vector2 = new_btn_tilemap.get_node("TilemapThumb/Background").rect_position + Vector2(32, 32)

		var tilemap_thumb_width: float = thumbnail_visible_rect.x
		var tilemap_size_factor: float = level_btn.rect_size.x / tilemap_thumb_width
		new_btn_tilemap.scale *= tilemap_size_factor

		# grid size ... prvi gumb je mera
		if btn_final_size == Vector2.ZERO:
			btn_final_size = thumbnail_visible_rect * tilemap_size_factor
			rect_size = Vector2.ZERO # scale grid ... zmanjšam na najmanj ... min_size gumbov ga resiza na pravilno
		level_btn.rect_min_size = btn_final_size

		# position ... rob tilemapa se ne vidi
		var tilemap_offset: Vector2 = thumbnail_visible_position * tilemap_size_factor
		new_btn_tilemap.position -= tilemap_offset

		new_btn_tilemap.show_as_thumbnail()

		return


func _get_btn_highscore(level_name: String):


	var btn_level_game_data = Profiles.game_data[game_key]
	btn_level_game_data["level_name"] = level_name

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

# BTNS ---------------------------------------------------------------------------------------------


func _on_btn_hovered_or_focused(btn):

	var btn_color: Color = btn_colors[all_level_btns.find(btn)]
	var fade_time: float = 0.2
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_callback(btn, "set_self_modulate", [Color.white])
	fade_tween.parallel().tween_property(btn.get_node(tilemap_thumb_cover_path), "modulate:a", 0, fade_time)#.set_delay(0.01)
#	fade_tween.parallel().tween_property(btn.get_node(tilemap_path).thumb_cover, "modulate:a", 0, fade_time)#.set_delay(0.01)
	fade_tween.parallel().tween_property(btn.get_node(record_holder_path), "modulate:a", 0, fade_time)#.set_delay(0.01)
	fade_tween.parallel().tween_property(btn, "self_modulate", btn_color, fade_time).from(Color.white).set_delay(0.01)


func _on_btn_unhovered_or_unfocused(btn: Button):

	var btn_color: Color = btn_colors[all_level_btns.find(btn)]
	var fade_time: float = 0.2
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(btn.get_node(tilemap_thumb_cover_path), "modulate:a", 0.8, fade_time)
#	fade_tween.tween_property(btn.get_node(tilemap_path).thumb_cover, "modulate:a", 0.8, fade_time)
	if solved_btns.has(btn):
		fade_tween.parallel().tween_property(btn.get_node(record_holder_path), "modulate", btn_color, fade_time)
	else:
		fade_tween.parallel().tween_property(btn.get_node(record_holder_path), "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(btn, "self_modulate", Global.color_thumb_hover, fade_time)


func _on_btn_pressed(btn: Button):

	var pressed_btn_index: int = get_children().find(btn)
#	btns_holder_parent.play_selected_level(pressed_btn_index + 1)
	btns_holder_parent.play_selected_level(btn.get_node(level_name_path).text)

