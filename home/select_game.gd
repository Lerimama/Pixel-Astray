extends Control

#onready var sweeper_btn: Button = $GameBtns/SweeperBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var sweeper_btn: Button = $GamesMenu/Sweeper/SweeperBtn

onready var sweeper_btns_holder: Control = $"../SelectLevel/LevelGrid/BtnsHolder" # za število ugank
onready var sweeper_label: Label = $GamesMenu/Sweeper/Label

onready var color_pool: Array = $"%Intro".all_colors_available


func _process(delta: float) -> void:
	
	if not get_parent().current_screen == get_parent().Screens.SELECT_GAME:
		return
		
	# barvam ozadje gumbov na focus
	var of_color = Global.color_almost_black_pixel
	var focused_btn: BaseButton = get_focus_owner()
	if focused_btn.name == "TutorialBtn":
		$GamesMenu/Tutorial/Background.color = Global.color_dark_gray_pixel
	else:
		$GamesMenu/Tutorial/Background.color = of_color
	if focused_btn.name == "CleanerSBtn" or focused_btn.name == "CleanerMBtn" or focused_btn.name == "CleanerLBtn":
		$GamesMenu/Cleaner/Background.color = Global.color_blue
		#		var random_index = randi() % $"%Intro".all_colors_available.size() -1
		#		$GamesMenu/Cleaner/Background.color = $"%Intro".all_colors_available[random_index]
	else:
		$GamesMenu/Cleaner/Background.color = of_color
	if focused_btn.name == "EraserBtn" or focused_btn.name == "HandlerBtn" or focused_btn.name == "DefenderBtn":
		$GamesMenu/Timeless/Background.color = Global.color_orange
	else:
		$GamesMenu/Timeless/Background.color = of_color
	if focused_btn.name == "TheDuelBtn":
		$GamesMenu/TheDuel/Background.color = Global.color_red
	else:
		$GamesMenu/TheDuel/Background.color = of_color
	if focused_btn.name == "SweeperBtn":
		$GamesMenu/Sweeper/Background.color = Global.color_purple
	else:
		$GamesMenu/Sweeper/Background.color = of_color
			
			
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")
	get_viewport().set_disable_input(true)
	

func play_selected_game(selected_game_enum: int):
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_game")
	get_viewport().set_disable_input(true)
	
		
# at the cleaners -----------------------------------------------------------------------------------------


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
