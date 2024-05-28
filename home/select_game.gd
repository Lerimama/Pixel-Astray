extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var sweeper_game_btn: Button = $GamesMenu/Sweeper/SweeperBtn
onready var sweeper_btns_holder: Control = $"../SelectLevel/BtnsHolder" # za število ugank
onready var sweeper_label: Label = $GamesMenu/Sweeper/Label
onready var color_pool: Array = $"%Intro".all_colors_available


func _process(delta: float) -> void:
	
	if get_parent().current_screen == get_parent().Screens.SELECT_GAME:
		
		# barvam ozadje gumbov na focus
		var unfocused_color = Global.color_almost_black_pixel
		var focused_btn: BaseButton = get_focus_owner()
		if focused_btn.name == "TutorialBtn":
			$GamesMenu/Tutorial/Background.color = Global.color_dark_gray_pixel
		else:
			$GamesMenu/Tutorial/Background.color = unfocused_color
		if focused_btn.name == "CleanerSBtn" or focused_btn.name == "CleanerMBtn" or focused_btn.name == "CleanerLBtn":
			$GamesMenu/Cleaner/Background.color = Global.color_blue
			$GamesMenu/Cleaner/Background.modulate.a = 0.95 # da ne žari premočno
		else:
			$GamesMenu/Cleaner/Background.color = unfocused_color
			$GamesMenu/Cleaner/Background.modulate.a = 1
		if focused_btn.name == "EraserBtn" or focused_btn.name == "HandlerBtn" or focused_btn.name == "DefenderBtn":
			$GamesMenu/Timeless/Background.color = Global.color_green
			$GamesMenu/Timeless/Background.modulate.a = 0.83 # da ne žari premočno
		else:
			$GamesMenu/Timeless/Background.color = unfocused_color
			$GamesMenu/Timeless/Background.modulate.a = 1
		if focused_btn.name == "TheDuelBtn":
			$GamesMenu/TheDuel/Background.color = Global.color_red
			$GamesMenu/TheDuel/Background.modulate.a = 0.88 # da ne žari premočno
		else:
			$GamesMenu/TheDuel/Background.color = unfocused_color
			$GamesMenu/TheDuel/Background.modulate.a = 1
		if focused_btn.name == "SweeperBtn":
			$GamesMenu/Sweeper/Background.color = Global.color_purple
			$GamesMenu/Sweeper/Background.modulate.a = 0.85 # da ne žari premočno
		else:
			$GamesMenu/Sweeper/Background.color = unfocused_color
			$GamesMenu/Sweeper/Background.modulate.a = 1
	
			
func play_selected_game(selected_game_enum: int):
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_game")
	get_viewport().set_disable_input(true)
	
				
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")
	get_viewport().set_disable_input(true)
	

	
# game btns
func _on_TutorialBtn_pressed() -> void:
	play_selected_game(Profiles.Games.TUTORIAL)
func _on_CleanerSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_S)
func _on_CleanerMBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_M)
func _on_CleanerLBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_L)
func _on_EraserBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER)
func _on_HandlerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.HANDLER)
func _on_DefenderBtn_pressed() -> void:
	play_selected_game(Profiles.Games.DEFENDER)
func _on_TheDuelBtn_pressed() -> void:
	play_selected_game(Profiles.Games.THE_DUEL)
func _on_SweeperBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_level")
	get_viewport().set_disable_input(true)

# ozadja
func _on_TutorialBackground_mouse_entered() -> void:
	
	$GamesMenu/Tutorial/TutorialBtn.grab_focus()
func _on_CleanerBackground_mouse_entered() -> void:
	
	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Cleaner/CleanerMBtn.has_focus() and not $GamesMenu/Cleaner/CleanerLBtn.has_focus():
		$GamesMenu/Cleaner/CleanerSBtn.grab_focus()
func _on_TimelessBackground_mouse_entered() -> void:
	
	# če še ni izbran kateri v trenutnem boxu
	if not $GamesMenu/Timeless/DefenderBtn.has_focus() and not $GamesMenu/Timeless/HandlerBtn.has_focus():
		$GamesMenu/Timeless/EraserBtn.grab_focus()
func _on_SweeperBackground_mouse_entered() -> void:
	
	sweeper_game_btn.grab_focus()
func _on_DuelBackground_mouse_entered() -> void:
	
	$GamesMenu/TheDuel/TheDuelBtn.grab_focus()
