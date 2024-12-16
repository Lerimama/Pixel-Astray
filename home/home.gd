extends Node


enum Screens {INTRO, MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES, SELECT_LEVEL}
var current_screen = Screens.INTRO # se določi z main animacije

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $HomeScreen/Menu
onready var intro: Node2D = $HomeScreen/IntroViewPortContainer/IntroViewport/Intro
onready var intro_viewport: Viewport = $HomeScreen/IntroViewPortContainer/IntroViewport
onready var navigation_hint: Label = $NavigationHint
onready var home_swipe_btn: TouchScreenButton = $HomeSwipeBtn
onready var default_focus_node: Control = $HomeScreen/Menu/SelectGameBtn



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
			Screens.MAIN_MENU:
				return

		get_viewport().set_disable_input(true)
		Analytics.save_ui_click("BackEsc")


func _ready():

	menu.hide()

	# navigation hint
	navigation_hint.modulate.a = 0
	if Profiles.touch_available:
		navigation_hint.text = "Swipe or select to navigate around" # ugasne ga swipe gumb
		home_swipe_btn.show()
	else:
		# navigation_hint.text = "Use keyboard or gamepad to navigate around"
		navigation_hint.hide()

	# btn groups
	menu.get_node("ExitGameBtn").add_to_group(Batnz.group_cancel_btns)
	if Profiles.html5_mode:
		menu.get_node("ExitGameBtn").hide()

	var focused_control: Control = menu.get_focus_owner()


func open_with_intro(): # kliče main.gd -> home_in_intro()

	intro.play_intro() # intro signal na koncu kliče menu_in()
	_load_highscores_on_start()


func open_without_intro(): # debug ... kliče main.gd -> home_in_no_intro()

	intro.finish_intro() # intro signal na koncu kliče menu_in()
	_load_highscores_on_start()


func open_from_game(finished_game: int): # select_game screen ... kliče main.gd -> home_in_from_game()

	animation_player.play("select_game")
	current_screen = Screens.SELECT_GAME

	# premik animacije na konec
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)

	# fokus glede na končano igro
	if finished_game == Profiles.Games.CLEANER:
		$SelectGame/GamesMenu/Cleaner/CleanerBtn.grab_focus()
	elif finished_game == Profiles.Games.HUNTER:
		$SelectGame/GamesMenu/Unbeatables/HunterBtn.grab_focus()
	elif finished_game == Profiles.Games.DEFENDER:
		$SelectGame/GamesMenu/Unbeatables/DefenderBtn.grab_focus()
	elif finished_game == Profiles.Games.SWEEPER:
		$SelectGame/GamesMenu/Sweeper/SweeperBtn.grab_focus()
	elif finished_game == Profiles.Games.THE_DUEL:
		$SelectGame/GamesMenu/TheDuel/TheDuelBtn.grab_focus()
	else: # ERASER_XS, ERASER_S, ERASER_M, ERASER_L, ERASER_XL,
		$SelectGame/GamesMenu/Eraser/SBtn.grab_focus()

	intro.finish_intro()
	_load_highscores_on_start()


func _load_highscores_on_start():
	# tega procesa ne sme nič prekinit!!!

	if not $SelectLevel.select_level_btns_holder.btns_are_set:
		yield ($SelectLevel.select_level_btns_holder, "level_btns_are_set")

	if Profiles.html5_mode:
		$Highscores.call_deferred("load_all_highscore_tables", true, true)
	else:
		$Highscores.call_deferred("load_all_highscore_tables", false)


func menu_in(): # kliče se na koncu intra, na skip intro in ko se vrnem iz drugih ekranov

	yield(get_tree().create_timer(0.5), "timeout")
#	yield(get_tree().create_timer(Global.get_it_time), "timeout")

	current_screen = Screens.MAIN_MENU
	default_focus_node.grab_focus()

	menu.modulate.a = 0
	menu.show()

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 1, 0.5)
	if navigation_hint.visible:
		fade_in.parallel().tween_property(navigation_hint, "modulate:a", 1, 0.5)


func menu_out():

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 0, 0.5)
	fade_in.parallel().tween_property(navigation_hint, "modulate:a", 0, 0.2)
	yield(fade_in,"finished")
	menu.hide()


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
				$SelectGame.default_focus_node.grab_focus()
#				$SelectLevel.select_level_btns_holder.set_level_btns_content()
		"about":
			if not animation_reversed(Screens.ABOUT):
				current_screen = Screens.ABOUT
				$About.default_focus_node.grab_focus()
		"settings":
			if not animation_reversed(Screens.SETTINGS):
				current_screen = Screens.SETTINGS
				$Settings.default_focus_node.grab_focus()
		"highscores":
			if not animation_reversed(Screens.HIGHSCORES):
				current_screen = Screens.HIGHSCORES
				if $Highscores.default_focus_node.disabled:
					ConnectCover.open_cover(false)
				else:
					$Highscores.default_focus_node.grab_focus()
		"select_level":
			if not animation_reversed(Screens.SELECT_LEVEL):
				current_screen = Screens.SELECT_LEVEL
				$SelectLevel.default_focus_node.grab_focus()
				$SelectLevel.select_level_btns_holder.all_level_btns[0].grab_focus()


func animation_reversed(from_screen: int):

	if animation_player.current_animation_position == 0: # pomeni, da je animacija v rikverc končana

		# preverim s katerega ekrana je animirano še preden zamenjam na MAIN_MENU
		match from_screen:
			Screens.SELECT_GAME:
				menu.get_node("SelectGameBtn").grab_focus()
#				menu_in()
			Screens.ABOUT:
				menu.get_node("AboutBtn").grab_focus()
#				menu_in()
			Screens.SETTINGS:
				menu.get_node("SettingsBtn").grab_focus()
#				menu_in()
			Screens.HIGHSCORES:
				menu.get_node("HighscoresBtn").grab_focus()
#				menu_in()
			Screens.SELECT_LEVEL:
				current_screen = Screens.SELECT_GAME
				$SelectGame/GamesMenu/Sweeper/SweeperBtn.grab_focus()

		return true


func _on_AnimationPlayer_animation_started(anim_name: String) -> void:
	# vsaka animacije ja prehod med scenami

	Batnz.allow_ui_sfx = false

	if not current_screen == Screens.MAIN_MENU and not anim_name == "select_level":
		menu_in()
#	if anim_name == "":
#		yield(get_tree().create_timer(0.3), "timeout")
#		$SelectLevel.select_level_btns_holder.call_deferred("set_level_btns_content")
##		$SelectLevel.select_level_btns_holder.set_level_btns_content()


# MENU BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBtn_pressed() -> void:

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_game")


func _on_AboutBtn_pressed() -> void:

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("about")


func _on_SettingsBtn_pressed() -> void:

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("settings")


func _on_HighscoresBtn_pressed() -> void:

	menu_out()
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("highscores")


func _on_QuitGameBtn_pressed() -> void:

	Global.main_node.quit_exit_game()
