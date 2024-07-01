extends Control


var btn_colors: Array
var all_game_btns: Array

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var sweeper_game_btn: Button = $GamesMenu/Sweeper/SweeperBtn
onready var sweeper_btns_count: int = Profiles.sweeper_level_tilemap_paths.size() # za število ugank
onready var sweeper_label: Label = $GamesMenu/Sweeper/Label
onready var color_pool: Array = $"%Intro".color_pool_colors
onready var tutorial_mode_btn: CheckButton = $GamesMenu/Classic/TutorialModeBtn


func _ready() -> void:
	
	
	if Profiles.tutorial_mode:
		tutorial_mode_btn.pressed = true
	else:
		tutorial_mode_btn.pressed = false
	
	sweeper_label.text %= sweeper_btns_count

	# menu btn group
	all_game_btns = [$GamesMenu/Classic/ClassicBtn,
			$GamesMenu/Cleaner/CleanerSBtn,
			$GamesMenu/Cleaner/CleanerMBtn,
			$GamesMenu/Cleaner/CleanerLBtn,
			$GamesMenu/Cleaner/CleanerXLBtn,
			$GamesMenu/Cleaner/CleanerXXLBtn,
			$GamesMenu/Timeless/EraserBtn,
			$GamesMenu/Timeless/DefenderBtn,
			$GamesMenu/TheDuel/TheDuelBtn,
			$GamesMenu/Sweeper/SweeperBtn,
			]
	
	# vgrupo za efekte
	for btn in all_game_btns:
		btn.add_to_group(Global.group_menu_confirm_btns)
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	
	color_game_btns()


func _process(delta: float) -> void:
	
	if get_parent().current_screen == get_parent().Screens.SELECT_GAME:
		
		# barvam ozadje gumbov na focus
		var unfocused_color = Global.color_almost_black_pixel
		
		var focused_btn: BaseButton = get_focus_owner()
		if focused_btn:
			# klasika
			if focused_btn.name == "ClassicBtn":# or focused_btn.name == "TutorialModeBtn":
				$GamesMenu/Classic/ClassicBtn.modulate = Color.white
				$GamesMenu/Classic/Label.modulate = Color.white
				$GamesMenu/Classic/TutorialModeBtn.modulate = Global.color_gui_gray # rešitev, ker gumb se na začetku obarva kot fokusiran
				$GamesMenu/Classic/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "TutorialModeBtn":
				$GamesMenu/Classic/ClassicBtn.modulate = Global.color_gui_gray
				$GamesMenu/Classic/Label.modulate = Color.white
				$GamesMenu/Classic/TutorialModeBtn.modulate = Color.white # rešitev, ker gumb se na začetku obarva kot fokusiran
				$GamesMenu/Classic/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Classic/TutorialModeBtn.modulate = btn_colors[0] # rešitev, ker gumb se na začetku obarva kot fokusiran
				$GamesMenu/Classic/ClassicBtn.modulate = btn_colors[0]
				$GamesMenu/Classic/Label.modulate = btn_colors[0]
				$GamesMenu/Classic/Background.color = unfocused_color
			# cleaners
			if focused_btn.name == "CleanerSBtn":
				$GamesMenu/Cleaner/CleanerSBtn.modulate = Color.white
				$GamesMenu/Cleaner/CleanerMBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "CleanerMBtn":
				$GamesMenu/Cleaner/CleanerSBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerMBtn.modulate = Color.white
				$GamesMenu/Cleaner/CleanerLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "CleanerLBtn":
				$GamesMenu/Cleaner/CleanerSBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerMBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerLBtn.modulate = Color.white
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "CleanerXLBtn":
				$GamesMenu/Cleaner/CleanerSBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerMBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = Color.white
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "CleanerXXLBtn":
				$GamesMenu/Cleaner/CleanerSBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerMBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = Global.color_gui_gray
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = Color.white
				$GamesMenu/Cleaner/Label.modulate = Color.white
				$GamesMenu/Cleaner/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Cleaner/CleanerSBtn.modulate = btn_colors[5]
				$GamesMenu/Cleaner/CleanerMBtn.modulate = btn_colors[6]
				$GamesMenu/Cleaner/CleanerLBtn.modulate = btn_colors[7]
				$GamesMenu/Cleaner/CleanerXLBtn.modulate = btn_colors[8]
				$GamesMenu/Cleaner/CleanerXXLBtn.modulate = btn_colors[9]
				$GamesMenu/Cleaner/Label.modulate = btn_colors[6]
				$GamesMenu/Cleaner/Background.color = unfocused_color
			# eternals
			if focused_btn.name == "EraserBtn":
				$GamesMenu/Timeless/EraserBtn.modulate = Color.white
				$GamesMenu/Timeless/DefenderBtn.modulate = Global.color_gui_gray
				$GamesMenu/Timeless/Label.modulate = Color.white
				$GamesMenu/Timeless/Background.color = Global.color_thumb_hover
			elif focused_btn.name == "DefenderBtn":
				$GamesMenu/Timeless/EraserBtn.modulate = Global.color_gui_gray
				$GamesMenu/Timeless/DefenderBtn.modulate = Color.white
				$GamesMenu/Timeless/Label.modulate = Color.white
				$GamesMenu/Timeless/Background.color = Global.color_thumb_hover
			else:
				$GamesMenu/Timeless/EraserBtn.modulate = btn_colors[13]
				$GamesMenu/Timeless/DefenderBtn.modulate = btn_colors[14]
				$GamesMenu/Timeless/Label.modulate = btn_colors[13]
				$GamesMenu/Timeless/Background.color = unfocused_color
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
	$GamesMenu/Classic/ClassicBtn.modulate = btn_colors[0]
	$GamesMenu/Classic/TutorialModeBtn.modulate = Global.color_gui_gray # rešitev, ker gumb se na začetku obarva kot fokusiran
	$GamesMenu/Classic/Label.modulate = btn_colors[0]
	
	$GamesMenu/Sweeper/Label.modulate = btn_colors[3]
	$GamesMenu/Sweeper/SweeperBtn.modulate = btn_colors[3]
	
	$GamesMenu/Cleaner/Label.modulate = btn_colors[6]
	$GamesMenu/Cleaner/CleanerSBtn.modulate = btn_colors[5]
	$GamesMenu/Cleaner/CleanerMBtn.modulate = btn_colors[6]
	$GamesMenu/Cleaner/CleanerLBtn.modulate = btn_colors[7]
	$GamesMenu/Cleaner/CleanerXLBtn.modulate = btn_colors[8]
	$GamesMenu/Cleaner/CleanerXXLBtn.modulate = btn_colors[9]
	
	$GamesMenu/TheDuel/Label.modulate = btn_colors[11]	
	$GamesMenu/TheDuel/TheDuelBtn.modulate = btn_colors[11]
	
	$GamesMenu/Timeless/Label.modulate = btn_colors[13]
	$GamesMenu/Timeless/EraserBtn.modulate = btn_colors[13]
	$GamesMenu/Timeless/DefenderBtn.modulate = btn_colors[14]
	
				
func play_selected_game(selected_game_enum: int):
	
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_game")
	
				
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")
	
	
func _on_ClassicBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLASSIC)
	
	
func _on_TutorialModeBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Profiles.tutorial_mode = true
	else:
		Profiles.tutorial_mode = false

		
func _on_CleanerSBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLEANER_XS)
	
	
func _on_CleanerMBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLEANER_S)
	
	
func _on_CleanerLBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLEANER_M)


func _on_CleanerXLBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLEANER_L)


func _on_CleanerXXLBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CLEANER_XL)
	
	
func _on_EraserBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.CHASER)
	
	
func _on_DefenderBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.DEFENDER)
	
	
func _on_TheDuelBtn_pressed() -> void:
	
	play_selected_game(Profiles.Games.THE_DUEL)
	
	
func _on_SweeperBtn_pressed() -> void:
	
	# ?	play_selected_game(Profiles.Games.SWEEPER)
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_level")
	get_viewport().set_disable_input(true)
	Global.focus_without_sfx($"../SelectLevel".select_level_btns_holder.all_level_btns[0])
	
	
func _on_ClassicBackground_mouse_entered() -> void:
	
	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Classic/ClassicBtn.has_focus() and not tutorial_mode_btn.has_focus():
		$GamesMenu/Classic/ClassicBtn.grab_focus()
	
	
func _on_CleanerBackground_mouse_entered() -> void:
	
	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Cleaner/CleanerMBtn.has_focus() and not $GamesMenu/Cleaner/CleanerLBtn.has_focus() and not $GamesMenu/Cleaner/CleanerXLBtn.has_focus() and not $GamesMenu/Cleaner/CleanerXXLBtn.has_focus():
		$GamesMenu/Cleaner/CleanerSBtn.grab_focus()
		
		
func _on_TimelessBackground_mouse_entered() -> void:
	
	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Timeless/DefenderBtn.has_focus():
		$GamesMenu/Timeless/EraserBtn.grab_focus()
		
		
func _on_SweeperBackground_mouse_entered() -> void:
	
	sweeper_game_btn.grab_focus()
	
	
func _on_DuelBackground_mouse_entered() -> void:
	
	$GamesMenu/TheDuel/TheDuelBtn.grab_focus()
