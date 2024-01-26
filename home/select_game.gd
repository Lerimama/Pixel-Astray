extends Control



func _ready() -> void:
	pass # Replace with function body.


func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("select_game")
	get_viewport().set_disable_input(true)
	
	
# cleaner -----------------------------------------------------------------------------------------

	
func _on_TutorialBtn_pressed() -> void:
	
	return
	
	Profiles.set_game_data(Profiles.Games.TUTORIAL)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play") # home out je signal na koncu animacije
	get_viewport().set_disable_input(true)

func _on_CleanerSBtn_pressed() -> void:

	Profiles.set_game_data(Profiles.Games.CLEANER_S)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_CleanerMBtn_pressed() -> void:

	Profiles.set_game_data(Profiles.Games.CLEANER_M)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_CleanerLBtn_pressed() -> void:

	Profiles.set_game_data(Profiles.Games.CLEANER_L)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)


# sprinter -----------------------------------------------------------------------------------------


func _on_SprinterSBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.SPRINTER_S)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_SprinterMBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.SPRINTER_M)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_SprinterLBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.SPRINTER_L)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_DuelBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.SPRINTER_DUEL)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)


# mover -----------------------------------------------------------------------------------------


func _on_WanderingBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.HUNTER)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)

func _on_FallingBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.SCROLLER)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)
