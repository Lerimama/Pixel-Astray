extends Control


var btn_colors: Array

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var color_pool: Array = $"%Intro".color_pool_colors
onready var default_focus_node: Control = $GamesMenu/Cleaner/CleanerBtn


func _ready() -> void:

#	$BackBtn.add_to_group(Batnz.group_cancel_btns)
#
#	colorize_game_btns()
#	$GamesMenu.set_game_btns()
	pass


func _process(delta: float) -> void:

	if get_parent().current_screen == get_parent().Screens.SELECT_GAME:
		var unfocused_color = Global.color_almost_black

		var focused_btn: BaseButton = get_focus_owner()
		if focused_btn:
			$GamesMenu.check_btns_on_focus(focused_btn, btn_colors)


func colorize_game_btns():

	btn_colors.clear()

	# naberem gumbe in barve
	var color_count: int = $GamesMenu.all_game_btns.size() + 6
	if Profiles.use_default_color_theme:
		btn_colors = Global.get_spectrum_colors(color_count)
	else:
		var color_split_offset: float = 1.0 / color_count
		for btn_count in color_count:
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)

	# pobarvam gumbe in labele
	$GamesMenu/Cleaner/Label.modulate = btn_colors[0]
	$GamesMenu/Cleaner/CleanerBtn.modulate = btn_colors[0]

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


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
#	animation_player.play_backwards("select_game")
	animation_player.play_backwards("select_sweeper")
	get_parent().menu_in()


func _on_TutorialModeBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Profiles.tutorial_mode = true
	else:
		Profiles.tutorial_mode = false


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

	$GamesMenu/Sweeper/SweeperBtn.grab_focus()
