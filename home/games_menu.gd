extends Control


var unfocused_btn_color = Color.white
var btn_colors: Array
var focus_time: float = 0.2

onready var color_pool: Array = $"%Intro".color_pool_colors
onready var description_label: Label = $Description/Label
onready var all_game_btns: Array = $HBoxContainer.get_children()


func _ready() -> void:

	_set_game_btns()


func update_btn_colors():

	btn_colors.clear()

	# naberem gumbe in barve
	var color_count: int = all_game_btns.size() + 6
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(color_count)
	else:
		var color_split_offset: float = 1.0 / color_count
		for btn_count in color_count:
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)


func _set_game_btns():

	update_btn_colors()

	$HBoxContainer/CleanerBtn/Label.text = Profiles.game_data[Profiles.Games.CLEANER]["home_btn_desc"]
	$HBoxContainer/EraserBtn/Label.text = Profiles.game_data[Profiles.Games.ERASER]["home_btn_desc"]
	$HBoxContainer/DefenderBtn/Label.text = Profiles.game_data[Profiles.Games.DEFENDER]["home_btn_desc"]
	$HBoxContainer/SweeperBtn/Label.text = Profiles.game_data[Profiles.Games.SWEEPER]["home_btn_desc"]
	$HBoxContainer/HunterBtn/Label.text = Profiles.game_data[Profiles.Games.HUNTER]["home_btn_desc"]

#	$HBoxContainer/CleanerBtn.modulate = btn_colors[3]
#	$HBoxContainer/EraserBtn.modulate = btn_colors[5]
#	$HBoxContainer/DefenderBtn.modulate = btn_colors[6]
#	$HBoxContainer/SweeperBtn.modulate = btn_colors[7]
#	$HBoxContainer/HunterBtn.modulate = btn_colors[9]


	for btn in all_game_btns:
		btn.connect("pressed", self, "_on_game_btn_pressed", [btn])
		btn.connect("focus_entered", self, "_on_game_btn_focused", [btn])
		btn.connect("focus_exited", self, "_on_game_btn_unfocused", [btn])
		if not btn == $HBoxContainer/SweeperBtn:
			btn.add_to_group(Batnz.group_critical_btns)

	$TutorialModeBtn.set_pressed_no_signal(Profiles.tutorial_mode)


func _play_selected_game(selected_game_enum: int):

	#	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"]) # ... povzroča eror preko update in post request
	Profiles.set_game_data(selected_game_enum)
	Global.main_node.home_out()


func _on_game_btn_pressed(pressed_btn: Button):

	var selected_game: int = -1

	match pressed_btn.name:
		"CleanerBtn": selected_game = Profiles.Games.CLEANER
		"EraserBtn":
			Global.sound_manager.play_gui_sfx("screen_slide")
			get_parent().get_parent().menu_out()
			get_parent().get_parent().animation_player.play("select_eraser")
		"DefenderBtn": selected_game = Profiles.Games.DEFENDER
		"HunterBtn": selected_game = Profiles.Games.HUNTER
		"SweeperBtn":
			Global.sound_manager.play_gui_sfx("screen_slide")
			get_parent().get_parent().menu_out()
			get_parent().get_parent().animation_player.play("select_sweeper")
		"TheDuelBtn": selected_game = Profiles.Games.THE_DUEL

	if selected_game > -1:
		_play_selected_game(selected_game)


func _on_game_btn_unfocused(btn: Control):
	# dogaja se tudi na prehajanju po eraser gumbih ... ni optimalno

	var unfocus_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	unfocus_tween.tween_property(btn, "modulate", unfocused_btn_color, focus_time)
	# če so defokusirani vsi skrijem opis
#	if not all_game_btns.has(get_focus_owner()):
#		unfocus_tween.parallel().tween_property(description_label, "modulate:a", 0, 0.2)


func _on_game_btn_focused(btn: Control):

	var current_btn_color: Color
	var current_btn_description: String

	match btn.name:
		"CleanerBtn":
			current_btn_color = btn_colors[1]
#			current_btn_description = Profiles.game_data[Profiles.Games.CLEANER]["home_btn_desc"]
		"EraserBtn":
			current_btn_color = btn_colors[3]
#			current_btn_description = Profiles.game_data[Profiles.Games.ERASER]["home_btn_desc"]
		"DefenderBtn":
			current_btn_color = btn_colors[5]
#			current_btn_description = Profiles.game_data[Profiles.Games.DEFENDER]["home_btn_desc"]
		"SweeperBtn":
			current_btn_color = btn_colors[7]
#			current_btn_description = Profiles.game_data[Profiles.Games.SWEEPER]["home_btn_desc"]
		"HunterBtn":
			current_btn_color = btn_colors[9]
#			current_btn_description = Profiles.game_data[Profiles.Games.HUNTER]["home_btn_desc"]
#		"TheDuelBtn":
#			current_btn_color = btn_colors[9]
##			current_btn_description = Profiles.game_data[Profiles.Games.THE_DUEL]["home_btn_desc"]

#	btn.get_node("BtnLabel").modulate = Color.white

	description_label.text = current_btn_description
	var focus_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	focus_tween.tween_property(btn, "modulate", current_btn_color, focus_time)
#	focus_tween.parallel().tween_property(description_label, "modulate", current_btn_color, 0.2)#.from(current_btn_color).set_delay(0.2)
#	focus_tween.parallel().tween_property(description_label, "modulate", Color.white, 0.2)#.from(current_btn_color).set_delay(0.2)
#	focus_tween.parallel().tween_property(description_label, "modulate:a", 0, 0.2)
#	focus_tween.tween_callback(description_label, "set_text", [current_btn_description])
#	focus_tween.parallel().tween_property(description_label, "modulate", Color.white, 0.2)#.from(current_btn_color).set_delay(0.2)
	focus_tween.parallel().tween_property(description_label, "modulate", current_btn_color, focus_time)#.from(current_btn_color).set_delay(0.2)
