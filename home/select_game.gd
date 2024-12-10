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
#		else:
#			btn.connect("pressed", self, "_on_game_btn_pressed", [btn])
	$BackBtn.add_to_group(Batnz.group_cancel_btns)

	color_game_btns()


func _process(delta: float) -> void:

	if get_parent().current_screen == get_parent().Screens.SELECT_GAME:

		# barvam ozadje gumbov na focus
		var unfocused_color = Global.color_almost_black_pixel

		var focused_btn: BaseButton = get_focus_owner()
		if focused_btn:
			# klasika
			if focused_btn.name == "CleanerBtn":# or focused_btn.name == "TutorialModeBtn":
				$GamesMenu/Cleaner/CleanerBtn.modulate = Color.white
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Cleaner/CleanerBtn.modulate = btn_colors[0]
				$GamesMenu/Cleaner/Label.modulate = btn_colors[0]
				$GamesMenu/Cleaner/Background.color = unfocused_color
			# erasers
			if focused_btn.name == "SBtn":
				$GamesMenu/Eraser/SBtn.modulate = Color.white
				$GamesMenu/Eraser/MBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/LBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/Label.modulate = Color.white
				$GamesMenu/Eraser/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "MBtn":
				$GamesMenu/Eraser/SBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/MBtn.modulate = Color.white
				$GamesMenu/Eraser/LBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/Label.modulate = Color.white
				$GamesMenu/Eraser/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "LBtn":
				$GamesMenu/Eraser/SBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/MBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/LBtn.modulate = Color.white
				$GamesMenu/Eraser/XLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/Label.modulate = Color.white
				$GamesMenu/Eraser/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "XLBtn":
				$GamesMenu/Eraser/SBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/MBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/LBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XLBtn.modulate = Color.white
				$GamesMenu/Eraser/XXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/Label.modulate = Color.white
				$GamesMenu/Eraser/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "XXLBtn":
				$GamesMenu/Eraser/SBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/MBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/LBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Eraser/XXLBtn.modulate = Color.white
				$GamesMenu/Eraser/Label.modulate = Color.white
				$GamesMenu/Eraser/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Eraser/SBtn.modulate = btn_colors[5]
				$GamesMenu/Eraser/MBtn.modulate = btn_colors[6]
				$GamesMenu/Eraser/LBtn.modulate = btn_colors[7]
				$GamesMenu/Eraser/XLBtn.modulate = btn_colors[8]
				$GamesMenu/Eraser/XXLBtn.modulate = btn_colors[9]
				$GamesMenu/Eraser/Label.modulate = btn_colors[6]
				$GamesMenu/Eraser/Background.color = unfocused_color
			# eternals
			if focused_btn.name == "HunterBtn":
				$GamesMenu/Unbeatables/HunterBtn.modulate = Color.white
				$GamesMenu/Unbeatables/DefenderBtn.modulate = Global.color_gui_gray
				$GamesMenu/Unbeatables/Label.modulate = Color.white
				$GamesMenu/Unbeatables/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "DefenderBtn":
				$GamesMenu/Unbeatables/HunterBtn.modulate = Global.color_gui_gray
				$GamesMenu/Unbeatables/DefenderBtn.modulate = Color.white
				$GamesMenu/Unbeatables/Label.modulate = Color.white
				$GamesMenu/Unbeatables/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Unbeatables/HunterBtn.modulate = btn_colors[13]
				$GamesMenu/Unbeatables/DefenderBtn.modulate = btn_colors[14]
				$GamesMenu/Unbeatables/Label.modulate = btn_colors[13]
				$GamesMenu/Unbeatables/Background.color = unfocused_color
			# druge
			if focused_btn.name == "SweeperBtn":
				$GamesMenu/Sweeper/Label.modulate = Color.white
				$GamesMenu/Sweeper/SweeperBtn.modulate = Color.white
				$GamesMenu/Sweeper/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Sweeper/Label.modulate = btn_colors[3]
				$GamesMenu/Sweeper/SweeperBtn.modulate = btn_colors[3]
				$GamesMenu/Sweeper/Background.color = unfocused_color
			if focused_btn.name == "TheDuelBtn":
				$GamesMenu/TheDuel/TheDuelBtn.modulate = Color.white
				$GamesMenu/TheDuel/Label.modulate = Color.white
				$GamesMenu/TheDuel/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/TheDuel/TheDuelBtn.modulate = btn_colors[11]
				$GamesMenu/TheDuel/Label.modulate = btn_colors[11]
				$GamesMenu/TheDuel/Background.color = unfocused_color


func color_game_btns():

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
	Analytics.save_selected_game_data(Profiles.current_game_data["game_name"])

	Global.main_node.home_out()


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")


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
	$"../SelectLevel".select_level_btns_holder.all_level_btns[0].grab_focus()


func _on_CleanerBackground_mouse_entered() -> void:

	# če še ni izbran kateri v trenutnem boxu
	#	if not $GamesMenu/Cleaner/CleanerBtn.has_focus():
	#	if not $GamesMenu/Cleaner/CleanerBtn.has_focus() and not tutorial_mode_btn.has_focus():
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

