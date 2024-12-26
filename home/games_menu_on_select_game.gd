extends Control


#var btn_colors: Array
onready var color_pool: Array = $"%Intro".color_pool_colors

onready var all_game_btns: Array = [
	$Cleaner/CleanerBtn,
	$Eraser/XXLBtn,
	$Eraser/SBtn,
	$Eraser/MBtn,
	$Eraser/LBtn,
	$Eraser/XLBtn,
	$Unbeatables/DefenderBtn,
	$Unbeatables/HunterBtn,
	$Sweeper/SweeperBtn,
	$TheDuel/TheDuelBtn
	]



func check_btns_on_focus(focused_btn: Control, btn_colors):

	var unfocused_background_color = Global.color_almost_black
	var focused_background: Control
	var unfocused_backgrounds: Array

	# klasika
	if focused_btn.name == "CleanerBtn":# or focused_btn.name == "TutorialModeBtn":
		focused_background = $Cleaner/Background
	else:
		$Cleaner/CleanerBtn.modulate = btn_colors[0]
		unfocused_backgrounds.append($Cleaner/Background)

	# erasers

	$Eraser/SBtn.modulate = btn_colors[5]
	$Eraser/MBtn.modulate = btn_colors[6]
	$Eraser/LBtn.modulate = btn_colors[7]
	$Eraser/XLBtn.modulate = btn_colors[8]
	$Eraser/XXLBtn.modulate = btn_colors[9]
	if focused_btn.name == "SBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "MBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "LBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "XLBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "XXLBtn":
		focused_background = $Eraser/Background
	else:
		unfocused_backgrounds.append($Eraser/Background)

	# eternals

	$Unbeatables/HunterBtn.modulate = btn_colors[13]
	$Unbeatables/DefenderBtn.modulate = btn_colors[14]
	if focused_btn.name == "HunterBtn":
		focused_background = $Unbeatables/Background
	elif focused_btn.name == "DefenderBtn":
		focused_background = $Unbeatables/Background
	else:
		unfocused_backgrounds.append($Unbeatables/Background)

	# druge
	if focused_btn.name == "SweeperBtn":
		focused_background = $Sweeper/Background
	else:
		$Sweeper/SweeperBtn.modulate = btn_colors[3]
		unfocused_backgrounds.append($Sweeper/Background)

	if focused_btn.name == "TheDuelBtn":
		focused_background = $TheDuel/Background
	else:
		$TheDuel/TheDuelBtn.modulate = btn_colors[11]
		unfocused_backgrounds.append($TheDuel/Background)


	focused_btn.modulate = Color.white

	var focus_time: float = 0.3
	var focus_tween = get_tree().create_tween()
	if focused_background:
		focus_tween.parallel().tween_property(focused_background, "color", Global.color_thumb_hover, focus_time)
	for undi in unfocused_backgrounds:
		focus_tween.parallel().tween_property(undi, "color", unfocused_background_color, focus_time)


func set_game_btns():

	for btn in all_game_btns:
		print (btn)
		btn.connect("pressed", self, "_on_game_btn_pressed", [btn])
		if not btn == $Sweeper/SweeperBtn:
			btn.add_to_group(Batnz.group_critical_btns)
		if btn == $TheDuel/TheDuelBtn and Profiles.touch_available:
			btn.disabled = true
			$TheDuel/Label.text = "Couch coop is disabled\nfor touchscreen."

	$Sweeper/Label.text %= Profiles.sweeper_level_tilemap_paths.size()


func _on_game_btn_pressed(pressed_btn: Button):

	var selected_game: int = -1

	match pressed_btn.name:
		"CleanerBtn": selected_game = Profiles.Games.CLEANER
		"XSBtn": selected_game = Profiles.Games.ERASER_XS
		"SBtn": selected_game = Profiles.Games.ERASER_S
		"MBtn": selected_game = Profiles.Games.ERASER_M
		"LBtn": selected_game = Profiles.Games.ERASER_L
		"XLLBtn": selected_game = Profiles.Games.ERASER_XL
		"DefenderBtn": selected_game = Profiles.Games.DEFENDER
		"HunterBtn": selected_game = Profiles.Games.HUNTER
		"SweeperBtn":
			#			selected_game = Profiles.Games.SWEEPER
			Global.sound_manager.play_gui_sfx("screen_slide")
			get_parent().animation_player.play("select_level")
		"TheDuelBtn": selected_game = Profiles.Games.THE_DUEL

	if selected_game > -1:
		play_selected_game(selected_game)


func play_selected_game(selected_game_enum: int):

#	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"]) # ... povzroča eror preko update in post request
	Profiles.set_game_data(selected_game_enum)
	Global.main_node.home_out()
