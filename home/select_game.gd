extends Control



func _ready() -> void:
	pass # Replace with function body.


func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("select_game")
	get_viewport().set_disable_input(true)
	

func play_selected_game(selected_game_enum: int):
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)
	
		
# at the cleaners -----------------------------------------------------------------------------------------


func _on_CleanerSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER)
	
#	Profiles.set_game_data(Profiles.Games.CLEANER_S)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)


func _on_EraserSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_S)

#	Profiles.set_game_data(Profiles.Games.ERASER_S)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)

func _on_EraserMBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_M)

#	Profiles.set_game_data(Profiles.Games.ERASER_M)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)

func _on_EraserLBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_L)

#	Profiles.set_game_data(Profiles.Games.ERASER_L)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)


func _on_CleanerMBtn_pressed() -> void:
#	Profiles.set_game_data(Profiles.Games.CLEANER_M)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)
	pass

func _on_CleanerLBtn_pressed() -> void:
#	Profiles.set_game_data(Profiles.Games.CLEANER_L)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)
	pass
	
func _on_CleanerDuelBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_DUEL)
	
#	Profiles.set_game_data(Profiles.Games.CLEANER_DUEL)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)


# scrollers -----------------------------------------------------------------------------------------

	
func _on_ScrollerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.SCROLLER)
#	Profiles.set_game_data(Profiles.Games.SCROLLER)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)


func _on_SidewinderBtn_pressed() -> void:
	play_selected_game(Profiles.Games.SIDEWINDER)
#
#	Profiles.set_game_data(Profiles.Games.SIDEWINDER)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play")
#	get_viewport().set_disable_input(true)


func _on_TutorialBtn_pressed() -> void:
	play_selected_game(Profiles.Games.TUTORIAL)
	
#	Profiles.set_game_data(Profiles.Games.TUTORIAL)
#	Global.sound_manager.play_gui_sfx("menu_fade")
#	$"%AnimationPlayer".play("play") # home out je signal na koncu animacije
#	get_viewport().set_disable_input(true)


func _on_RiddlerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_S)
func _on_RiddlerBtn2_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_M)
func _on_RiddlerBtn3_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_L)

func _on_RunnerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.RUNNER)


