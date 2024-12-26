extends Control


var unfocused_btn_color = Color.white
var btn_colors: Array
var focus_time: float = 0.2

onready var color_pool: Array = $"%Intro".color_pool_colors
onready var global_color_pool: Array = Global.current_color_pool
onready var description_label: Label = $Description/Label
onready var eraser_holder_edge: Panel = $HBoxContainer/Eraser/Background
onready var eraser_label: Label = $HBoxContainer/Eraser/Label
onready var all_new_btns: Array = [
	$HBoxContainer/CleanerBtn,
	$HBoxContainer/Eraser/HBoxContainer/XSBtn,
	$HBoxContainer/Eraser/HBoxContainer/SBtn,
	$HBoxContainer/Eraser/HBoxContainer/MBtn,
	$HBoxContainer/Eraser/HBoxContainer/LBtn,
	$HBoxContainer/Eraser/HBoxContainer/XLBtn,
	$HBoxContainer/HunterBtn,
	$HBoxContainer/DefenderBtn,
	$HBoxContainer/SweeperBtn
	]
onready var game_descriptions: Array = [
	"You have %d minutes to show your cleaning skills. Restore perfect order to this vibrant mess."  % 5,
	"Eliminate all %d stray pixels. Give it your best and beat the record time!" % 32,
	"Eliminate all %d stray pixels. Give it your best and beat the record time!" % 0,
	"Eliminate all %d stray pixels. Give it your best and beat the record time!" % 01,
	"Eliminate all %d stray pixels. Give it your best and beat the record time!" % 02,
	"Eliminate all %d stray pixels. Give it your best and beat the record time!" % 03,
	"Stop invading colors from taking over the screen as they keep crashing in!",
	"Stop nasty colors from flooding the screen as they keep poping in!",
	"Sweep them all in one move! %d saturated screens need a quick cleaning service." % Profiles.sweeper_level_tilemap_paths.size()
	]


func _ready() -> void:

	_set_game_btns()


func update_btn_colors():

	btn_colors.clear()

	# naberem gumbe in barve
	var color_count: int = all_new_btns.size() + 6
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(color_count)
	else:
		var color_split_offset: float = 1.0 / color_count
		for btn_count in color_count:
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)


func _set_game_btns():

	update_btn_colors()

	for btn in all_new_btns:
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
		"XSBtn": # selected_game = Profiles.Games.ERASER_XS
			Global.sound_manager.play_gui_sfx("screen_slide")
			get_parent().get_parent().menu_out()
			get_parent().get_parent().animation_player.play("select_eraser")
		"SBtn": selected_game = Profiles.Games.ERASER_S
		"MBtn": selected_game = Profiles.Games.ERASER_M
		"LBtn": selected_game = Profiles.Games.ERASER_L
		"XLBtn": selected_game = Profiles.Games.ERASER_XL
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

	var focus_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	focus_tween.tween_property(btn, "modulate", unfocused_btn_color, focus_time)

	# ker eraser skupino pedenam v fokusiranju, preverjam, če je fokusiran "glavni meni"
	if not all_new_btns.has(get_focus_owner()):
		focus_tween.parallel().tween_property(eraser_holder_edge, "modulate", Global.color_gui_gray, focus_time)
		focus_tween.parallel().tween_property(eraser_label, "modulate", Global.color_gui_gray, focus_time)


func _on_game_btn_focused(btn: Control):

	description_label.text = game_descriptions[all_new_btns.find(btn)]

	var current_btn_color: Color
	var eraser_holder_color: Color = Global.color_gui_gray # če ni fokusiran eraser btn, ostane bwla

	match btn.name:
		"CleanerBtn": current_btn_color = btn_colors[0]
		"XSBtn":
			current_btn_color = btn_colors[3]
			eraser_holder_color = current_btn_color
		"SBtn":
			current_btn_color = btn_colors[4]
			eraser_holder_color = current_btn_color
		"MBtn":
			current_btn_color = btn_colors[5]
			eraser_holder_color = current_btn_color
		"LBtn":
			current_btn_color = btn_colors[6]
			eraser_holder_color = current_btn_color
		"XLBtn":
			current_btn_color = btn_colors[7]
			eraser_holder_color = current_btn_color
		"DefenderBtn": current_btn_color = btn_colors[11]
		"HunterBtn": current_btn_color = btn_colors[13]
		"SweeperBtn": current_btn_color = btn_colors[14]

	var focus_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	focus_tween.tween_property(btn, "modulate", current_btn_color, focus_time)
	if not eraser_holder_color == Global.color_gui_gray: # imitacija blinka
		focus_tween.parallel().tween_callback(eraser_holder_edge, "set_modulate", [Color.white])
		focus_tween.parallel().tween_callback(eraser_label, "set_modulate", [Color.white])
		focus_tween.parallel().tween_property(eraser_holder_edge, "modulate", eraser_holder_color, focus_time).from(Color.white).set_delay(0.01)
		focus_tween.parallel().tween_property(eraser_label, "modulate", eraser_holder_color, focus_time).from(Color.white).set_delay(0.01)
#		focus_tween.parallel().tween_property(eraser_holder_edge, "modulate", eraser_holder_color, focus_time).from(Color.white).set_delay(0.2)
#		focus_tween.parallel().tween_property(eraser_label, "modulate", eraser_holder_color, focus_time).from(Color.white).set_delay(0.2)
	else:
		focus_tween.parallel().tween_property(eraser_holder_edge, "modulate", Global.color_gui_gray, focus_time)
		focus_tween.parallel().tween_property(eraser_label, "modulate", eraser_holder_color, focus_time)


func _on_Label_mouse_entered() -> void:

	# label hover fokusira prvi eraser gumb
	$HBoxContainer/Eraser/HBoxContainer/XSBtn.grab_focus()
