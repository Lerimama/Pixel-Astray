extends Node


enum Screens {INTRO, MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES, SELECT_LEVEL}
var current_screen = Screens.INTRO # se določi z main animacije

var allow_ui_sfx: bool = false # za kontrolo defolt focus soundov

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $HomeScreen/Menu
onready var intro: Node2D = $HomeScreen/IntroViewPortContainer/IntroViewport/Intro
onready var intro_viewport: Viewport = $HomeScreen/IntroViewPortContainer/IntroViewport
onready var navigation_hint: Label = $NavigationHint
onready var home_swipe_btn: TouchScreenButton = $HomeSwipeBtn


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_cancel"):

		match current_screen:
			Screens.SELECT_GAME:
				$SelectGame/BackBtn.grab_focus()
				$SelectGame.call_deferred("_on_BackBtn_pressed")
			Screens.ABOUT:
				$About/BackBtn.grab_focus()
				$About.call_deferred("_on_BackBtn_pressed")
			Screens.SETTINGS:
				$Settings/BackBtn.grab_focus()
				$Settings.call_deferred("_on_BackBtn_pressed")
			Screens.HIGHSCORES:
				$Highscores/BackBtn.grab_focus()
				$Highscores.call_deferred("_on_BackBtn_pressed")
			Screens.SELECT_LEVEL:
				$SelectLevel/BackBtn.grab_focus()
				$SelectLevel.call_deferred("_on_BackBtn_pressed")

		get_viewport().set_disable_input(true)
		Analytics.save_ui_click("BackEsc")


func _ready():

	menu.hide()

	# navigation hint
	navigation_hint.hide()
	if OS.has_touchscreen_ui_hint():
		navigation_hint.text = "You can swipe to navigate around." # ugasne ga swipe gumb
		home_swipe_btn.show()
	else:
		navigation_hint.text = "You can use keyboard or game-pad to navigate around." # ugasne se iz na esc

	# btn groups
	menu.get_node("SelectGameBtn").add_to_group(Global.group_menu_confirm_btns)
	menu.get_node("SettingsBtn").add_to_group(Global.group_menu_confirm_btns)
	menu.get_node("HighscoresBtn").add_to_group(Global.group_menu_confirm_btns)
	menu.get_node("AboutBtn").add_to_group(Global.group_menu_confirm_btns)
	menu.get_node("ExitGameBtn").add_to_group(Global.group_menu_cancel_btns)

	if Profiles.html5_mode:
		menu.get_node("ExitGameBtn").hide()

	var focused_control: Control = menu.get_focus_owner()
#	focused_control.call_deferred("release_focus")


func open_with_intro(): # kliče main.gd -> home_in_intro()

	intro.play_intro() # intro signal na koncu kliče menu_in()

	if Profiles.html5_mode:
		$Highscores.call_deferred("load_all_highscore_tables", true, true) # global update, in background
	else:
		$Highscores.call_deferred("load_all_highscore_tables", false) # global update, in background


func open_without_intro(): # debug ... kliče main.gd -> home_in_no_intro()

	intro.finish_intro() # intro signal na koncu kliče menu_in()

	if Profiles.html5_mode:
		$Highscores.call_deferred("load_all_highscore_tables", true, true)
	else:
		$Highscores.call_deferred("load_all_highscore_tables", false)


func open_from_game(finished_game: int): # select_game screen ... kliče main.gd -> home_in_from_game()

	animation_player.play("select_game")
	current_screen = Screens.SELECT_GAME

	# premik animacije na konec
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)

	# fokus glede na končano igro
	if finished_game == Profiles.Games.CLEANER:
		Global.grab_focus_nofx($SelectGame/GamesMenu/Cleaner/CleanerBtn)
	elif finished_game == Profiles.Games.HUNTER:
		Global.grab_focus_nofx($SelectGame/GamesMenu/Unbeatables/HunterBtn)
	elif finished_game == Profiles.Games.DEFENDER:
		Global.grab_focus_nofx($SelectGame/GamesMenu/Unbeatables/DefenderBtn)
	elif finished_game == Profiles.Games.SWEEPER:
		Global.grab_focus_nofx($SelectGame/GamesMenu/Sweeper/SweeperBtn)
	elif finished_game == Profiles.Games.THE_DUEL:
		Global.grab_focus_nofx($SelectGame/GamesMenu/TheDuel/TheDuelBtn)
	else: # ERASER_XS, ERASER_S, ERASER_M, ERASER_L, ERASER_XL,
		Global.grab_focus_nofx($SelectGame/GamesMenu/Eraser/SBtn)

	intro.finish_intro()

	if Profiles.html5_mode:
		$Highscores.call_deferred("load_all_highscore_tables", true, true)
	else:
		$Highscores.call_deferred("load_all_highscore_tables", false)


func menu_in(): # kliče se na koncu intra, na skip intro in ko se vrnem iz drugih ekranov


	current_screen = Screens.MAIN_MENU
	Global.grab_focus_nofx(menu.get_node("SelectGameBtn"))

	menu.modulate.a = 0
	menu.show()

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 1, 0.5)
	if not home_swipe_btn.has_swiped:
		fade_in.parallel().tween_callback(navigation_hint, "show")
		fade_in.parallel().tween_property(navigation_hint, "modulate:a", 1, 0.5).from(0.0)


func menu_out():

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 0, 0.5)
	fade_in.parallel().tween_property(navigation_hint, "modulate:a", 0, 0.2)
	yield(fade_in,"finished")
	menu.hide()
	navigation_hint.hide()


# SIGNALI ---------------------------------------------------------------------------------------------------


func _on_Intro_finished_playing() -> void:

	intro_viewport.set_disable_input(true) # dokler se predvaja mora biti, da skipanje deluje

	if not current_screen == Screens.SELECT_GAME and not current_screen == Screens.SELECT_LEVEL : # v primeru ko se vrnem iz igre
		menu_in()

	if not Global.sound_manager.menu_music_set_to_off: # tale pogoj je možen samo ob vračanju iz igre
		Global.sound_manager.play_music("menu_music")


func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:

	get_viewport().set_disable_input(false)

	match animation_name:
		"select_game":
			if not animation_reversed(Screens.SELECT_GAME):
				current_screen = Screens.SELECT_GAME
				Global.grab_focus_nofx($SelectGame.default_focus_node)
		"about":
			if not animation_reversed(Screens.ABOUT):
				current_screen = Screens.ABOUT
				Global.grab_focus_nofx($About.default_focus_node)
		"settings":
			if not animation_reversed(Screens.SETTINGS):
				current_screen = Screens.SETTINGS
				Global.grab_focus_nofx($Settings.default_focus_node)
		"highscores":
			if not animation_reversed(Screens.HIGHSCORES):
				current_screen = Screens.HIGHSCORES
				if $Highscores.default_focus_node.disabled:
					ConnectCover.open_cover(false)
				else:
					Global.grab_focus_nofx($Highscores.default_focus_node)
		"select_level":
			if not animation_reversed(Screens.SELECT_LEVEL):
				current_screen = Screens.SELECT_LEVEL
				Global.grab_focus_nofx($SelectLevel.default_focus_node)


func animation_reversed(from_screen: int):

	if animation_player.current_animation_position == 0: # pomeni, da je animacija v rikverc končana

		# preverim s katerega ekrana je animirano še preden zamenjam na MAIN_MENU
		match from_screen:
			Screens.SELECT_GAME:
				Global.grab_focus_nofx(menu.get_node("SelectGameBtn"))
				menu_in()
			Screens.ABOUT:
				Global.grab_focus_nofx(menu.get_node("AboutBtn"))
				menu_in()
			Screens.SETTINGS:
				Global.grab_focus_nofx(menu.get_node("SettingsBtn"))
				menu_in()
			Screens.HIGHSCORES:
				Global.grab_focus_nofx(menu.get_node("HighscoresBtn"))
				menu_in()
			Screens.SELECT_LEVEL:
				current_screen = Screens.SELECT_GAME
				Global.grab_focus_nofx($SelectGame/GamesMenu/Sweeper/SweeperBtn)

		return true


# MENU BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBtn_pressed() -> void:

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_game")


func _on_AboutBtn_pressed() -> void:

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("about")

func _on_SettingsBtn_pressed() -> void:

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("settings")



func _on_HighscoresBtn_pressed() -> void:

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("highscores")


func _on_QuitGameBtn_pressed() -> void:

	Global.main_node.quit_exit_game()
