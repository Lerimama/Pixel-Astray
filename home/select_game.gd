extends Control


var btn_colors: Array
var all_game_btns: Array

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var sweeper_game_btn: Button = $GamesMenu/Sweeper/SweeperBtn
onready var sweeper_btns_count: int = Profiles.sweeper_level_tilemap_paths.size() # za število ugank
#onready var sweeper_label: Label = $GamesMenu/Sweeper/Label
onready var color_pool: Array = $"%Intro".color_pool_colors
onready var default_focus_node: Control = $GamesMenu/Cleaner/CleanerBtn


func _ready() -> void:

	$TutorialModeBtn.set_pressed_no_signal(Profiles.tutorial_mode)
	$GamesMenu/Sweeper/Label.text %= sweeper_btns_count
	$BackBtn.add_to_group(Batnz.group_cancel_btns)

	# menu btn group
	all_game_btns = [$GamesMenu/Cleaner/CleanerBtn,
			$GamesMenu/Eraser/SBtn,
			$GamesMenu/Eraser/MBtn,
			$GamesMenu/Eraser/LBtn,
			$GamesMenu/Eraser/XLBtn,
			$GamesMenu/Eraser/XXLBtn,
			$GamesMenu/Unbeatables/HunterBtn,
			$GamesMenu/Unbeatables/DefenderBtn,
			$GamesMenu/TheDuel/TheDuelBtn,
			$GamesMenu/Sweeper/SweeperBtn,
			]

	# v grupo za efekte
	for btn in all_game_btns:
		if not btn == $GamesMenu/Sweeper/SweeperBtn:
			btn.add_to_group(Batnz.group_critical_btns)
		if btn == $GamesMenu/TheDuel/TheDuelBtn and Profiles.touch_available:
			btn.disabled = true
			$GamesMenu/TheDuel/Label.text = "Couch coop is disabled\nfor touchscreen."

	colorize_game_btns()


func _process(delta: float) -> void:

	if get_parent().current_screen == get_parent().Screens.SELECT_GAME:
		var unfocused_color = Global.color_almost_black

		var focused_btn: BaseButton = get_focus_owner()
		if focused_btn:
			$GamesMenu.check_btns_on_focus(focused_btn, btn_colors)


func colorize_game_btns():

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

	# pobarvam gumbe in labele
	$GamesMenu/Cleaner/CleanerBtn.modulate = btn_colors[0]
	$GamesMenu/Cleaner/Label.modulate = btn_colors[0]
	$GamesMenu/Sweeper/Label.modulate = btn_colors[3]
	$GamesMenu/Sweeper/SweeperBtn.modulate = btn_colors[3]
	$GamesMenu/Eraser/Label.modulate = btn_colors[6]
	$GamesMenu/Eraser/SBtn.modulate = btn_colors[5]
	$GamesMenu/Eraser/MBtn.modulate = btn_colors[6]
	$GamesMenu/Eraser/LBtn.modulate = btn_colors[7]
	$GamesMenu/Eraser/XLBtn.modulate = btn_colors[8]
	$GamesMenu/Eraser/XXLBtn.modulate = btn_colors[9]
	$GamesMenu/TheDuel/Label.modulate = btn_colors[11]
	$GamesMenu/TheDuel/TheDuelBtn.modulate = btn_colors[11]
	$GamesMenu/Unbeatables/Label.modulate = btn_colors[13]
	$GamesMenu/Unbeatables/HunterBtn.modulate = btn_colors[13]
	$GamesMenu/Unbeatables/DefenderBtn.modulate = btn_colors[14]


func play_selected_game(selected_game_enum: int):

	Profiles.set_game_data(selected_game_enum)
#	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"]) # ... povzroča eror preko update in post request

	Global.main_node.home_out()


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")
	get_parent().menu_in()


func _on_CleanerBtn_pressed() -> void:

	play_selected_game(Profiles.Games.CLEANER)


func _on_TutorialModeBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Profiles.tutorial_mode = true
	else:
		Profiles.tutorial_mode = false


func _on_SBtn_pressed() -> void:

	play_selected_game(Profiles.Games.ERASER_XS)


func _on_MBtn_pressed() -> void:

	play_selected_game(Profiles.Games.ERASER_S)


func _on_LBtn_pressed() -> void:

	play_selected_game(Profiles.Games.ERASER_M)


func _on_XLBtn_pressed() -> void:

	play_selected_game(Profiles.Games.ERASER_L)


func _on_XXLBtn_pressed() -> void:

	play_selected_game(Profiles.Games.ERASER_XL)


func _on_HunterBtn_pressed() -> void:

	play_selected_game(Profiles.Games.HUNTER)


func _on_DefenderBtn_pressed() -> void:

	play_selected_game(Profiles.Games.DEFENDER)


func _on_TheDuelBtn_pressed() -> void:

	play_selected_game(Profiles.Games.THE_DUEL)


func _on_SweeperBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_level")


func _on_CleanerBackground_mouse_entered() -> void:

	$GamesMenu/Cleaner/CleanerBtn.grab_focus()


func _on_EraserBackground_mouse_entered() -> void:

	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Eraser/MBtn.has_focus() and not $GamesMenu/Eraser/LBtn.has_focus() and not $GamesMenu/Eraser/XLBtn.has_focus() and not $GamesMenu/Eraser/XXLBtn.has_focus():
		$GamesMenu/Eraser/SBtn.grab_focus()


func _on_UnbeatablesBackground_mouse_entered() -> void:

	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Unbeatables/DefenderBtn.has_focus():
		$GamesMenu/Unbeatables/HunterBtn.grab_focus()


func _on_SweeperBackground_mouse_entered() -> void:

	sweeper_game_btn.grab_focus()


func _on_DuelBackground_mouse_entered() -> void:

	$GamesMenu/TheDuel/TheDuelBtn.grab_focus()

