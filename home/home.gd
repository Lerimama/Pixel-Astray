extends Node


enum Screens {INTRO, MAIN_MENU, ABOUT, SETTINGS, HIGHSCORES, SELECT_LEVEL, SELECT_ERASER}
var current_screen = Screens.INTRO # se določi z main animacije

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $HomeScreen/Menu
onready var intro: Node2D = $HomeScreen/IntroViewPortContainer/IntroViewport/Intro
onready var intro_viewport: Viewport = $HomeScreen/IntroViewPortContainer/IntroViewport
onready var navigation_hint: Label = $NavigationHint
onready var default_focus_node: Control = $HomeScreen/GamesMenu/HBoxContainer/CleanerBtn
onready var games_menu: Control = $"%GamesMenu"


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_cancel") and not current_screen == Screens.MAIN_MENU:
		_on_BackBtn_pressed()
		get_viewport().set_disable_input(true)
		#		Analytics.save_ui_click("BackEsc")


func _ready():

	menu.hide()
	games_menu.hide()
	navigation_hint.hide()

	# btn groups
	menu.get_node("ExitGameBtn").add_to_group(Batnz.group_cancel_btns)
	if Profiles.html5_mode:
		menu.get_node("ExitGameBtn").hide()

	if not Profiles.debug_mode:
		Global.hide_helper_nodes()


func open_with_intro(): # kliče main.gd -> home_in_intro()

	intro.play_intro() # intro signal na koncu kliče menu_in()
	_load_highscores_on_start()


func open_without_intro(): # debug ... kliče main.gd -> home_in_no_intro()

	intro.finish_intro() # intro signal na koncu kliče menu_in()
	_load_highscores_on_start()


func open_from_game(finished_game: int): # select_game screen ... kliče main.gd -> home_in_from_game()

	#E 0:01:02.240   get_current_animation_length: AnimationPlayer has no current animation
	#  <C++ Error>   Condition "!playback.current.from" is true. Returned: 0
	#  <C++ Source>  scene/animation/animation_player.cpp:1334 @ get_current_animation_length()
	#  <Stack Trace> home.gd:55 @ open_from_game()
	#                main.gd:79 @ home_in_from_game()


	# premik animacije na konec
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)

	current_screen = Screens.MAIN_MENU
	match finished_game:
		Profiles.Games.CLEANER:
			$HomeScreen/GamesMenu/HBoxContainer/CleanerBtn.grab_focus()
		Profiles.Games.HUNTER:
			$HomeScreen/GamesMenu/HBoxContainer/HunterBtn.grab_focus()
		Profiles.Games.DEFENDER:
			$HomeScreen/GamesMenu/HBoxContainer/DefenderBtn.grab_focus()
		Profiles.Games.SWEEPER:
			$HomeScreen/GamesMenu/HBoxContainer/SweeperBtn.grab_focus()
		Profiles.Games.ERASER:
			$HomeScreen/GamesMenu/HBoxContainer/EraserBtn.grab_focus()
		Profiles.Games.THE_DUEL:
			$SelectGame/GamesMenu/HBoxContainer/TheDuelBtn.grab_focus()

	#	# fokus glede na končano igro
	#	if finished_game == Profiles.Games.CLEANER:
	#		$HomeScreen/GamesMenu/HBoxContainer/CleanerBtn.grab_focus()
	#		current_screen = Screens.MAIN_MENU
	#	elif finished_game == Profiles.Games.HUNTER:
	#		$HomeScreen/GamesMenu/HBoxContainer/HunterBtn.grab_focus()
	#		current_screen = Screens.MAIN_MENU
	#	elif finished_game == Profiles.Games.DEFENDER:
	#		$HomeScreen/GamesMenu/HBoxContainer/DefenderBtn.grab_focus()
	#		current_screen = Screens.MAIN_MENU
	#	elif finished_game == Profiles.Games.SWEEPER:
	#		animation_player.play("select_sweeper")
	#		$HomeScreen/GamesMenu/HBoxContainer/SweeperBtn.grab_focus()
	#		current_screen = Screens.SELECT_LEVEL
	#	elif finished_game == Profiles.Games.ERASER:
	#		animation_player.play("select_eraser")
	#		$HomeScreen/GamesMenu/HBoxContainer/EraserBtn.grab_focus()
	#		current_screen = Screens.SELECT_ERASER
	#	elif finished_game == Profiles.Games.THE_DUEL:
	#		$SelectGame/GamesMenu/HBoxContainer/TheDuelBtn.grab_focus()
	#		current_screen = Screens.MAIN_MENU

	intro.finish_intro()
	_load_highscores_on_start()


func _load_highscores_on_start():
	# tega procesa ne sme nič prekinit!!!

	if not $SelectSweeper.select_level_btns_holder.btns_are_set:
		yield ($SelectSweeper.select_level_btns_holder, "level_btns_are_set")

	if Profiles.html5_mode:
		$Highscores.call_deferred("load_all_highscore_tables", true, true)
	else:
		$Highscores.call_deferred("load_all_highscore_tables", false)


func menu_in(): # kliče se na koncu intra, na skip intro in ko se vrnem iz drugih ekranov

	yield(get_tree().create_timer(0.5), "timeout")

	current_screen = Screens.MAIN_MENU # _temp a rabm na menu in?
	default_focus_node.grab_focus()

	menu.modulate.a = 0
	menu.show()
	games_menu.modulate.a = 0
	games_menu.show()

	var final_text_node: = intro.get_node("Text/Story6")

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(final_text_node, "modulate:a", 0, 0.5)
	fade_in.tween_property(games_menu, "modulate:a", 1, 0.5).set_delay(0.2)
	fade_in.parallel().tween_property(menu, "modulate:a", 1, 0.5).set_delay(0.2)
	if navigation_hint.visible:
		fade_in.parallel().tween_property(navigation_hint, "modulate:a", 1, 0.5)


func menu_out():

	get_viewport().set_disable_input(true) # reseta se na koncu animacije

	var final_text_node: = intro.get_node("Text/Story6")

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 0, 0.5)
	fade_in.parallel().tween_property(games_menu, "modulate:a", 0, 0.5)
	fade_in.parallel().tween_property(final_text_node, "modulate:a", 0, 0.5)
	fade_in.parallel().tween_property(navigation_hint, "modulate:a", 0, 0.2)
	fade_in.tween_callback(menu, "hide")
	fade_in.parallel().tween_callback(games_menu, "hide")
	#	yield(fade_in,"finished")
	#	menu.hide()


# SIGNALI ---------------------------------------------------------------------------------------------------


func _on_Intro_finished_playing() -> void:

	intro_viewport.set_disable_input(true) # dokler se predvaja mora biti, da skipanje deluje

	if not current_screen == Screens.SELECT_ERASER and not current_screen == Screens.SELECT_LEVEL : # v primeru ko se vrnem iz igre
		menu_in()

	if not Global.sound_manager.menu_music_set_to_off: # tale pogoj je možen samo ob vračanju iz igre
		Global.sound_manager.play_music("menu_music")


func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:

	get_viewport().set_disable_input(false)

	match animation_name:
		"about":
			# rikverc
			if animation_player.current_animation_position == 0:
				$HomeScreen/Menu/AboutBtn.grab_focus()
				current_screen = Screens.MAIN_MENU
			else:
				current_screen = Screens.ABOUT
				$About.default_focus_node.grab_focus()
		"settings":
			# rikverc
			if animation_player.current_animation_position == 0:
				$HomeScreen/Menu/SettingsBtn.grab_focus()
				current_screen = Screens.MAIN_MENU
			else:
				current_screen = Screens.SETTINGS
				$Settings.default_focus_node.grab_focus()
		"highscores":
			# rikverc
			if animation_player.current_animation_position == 0:
				$HomeScreen/Menu/HighscoresBtn.grab_focus()
				current_screen = Screens.MAIN_MENU
			else:
				current_screen = Screens.HIGHSCORES
				# če se apdejta poačakm za fokus
				if $Highscores.update_scores_btn.disabled:
					ConnectCover.open_cover(false)
				else:
					$Highscores.default_focus_node.grab_focus()
		"select_sweeper":
			# rikverc
			if animation_player.current_animation_position == 0:
				$HomeScreen/GamesMenu/HBoxContainer/SweeperBtn.grab_focus()
				current_screen = Screens.MAIN_MENU
			else:
				current_screen = Screens.SELECT_LEVEL
				$SelectSweeper.select_level_btns_holder.all_level_btns[0].call_deferred("grab_focus")
		"select_eraser":
			# rikverc
			if animation_player.current_animation_position == 0:
				$HomeScreen/GamesMenu/HBoxContainer/EraserBtn.grab_focus()
				current_screen = Screens.MAIN_MENU
			else:
				current_screen = Screens.SELECT_ERASER
				$SelectEraser.select_level_btns_holder.all_level_btns[0].call_deferred("grab_focus")


func _on_AnimationPlayer_animation_started(anim_name: String) -> void:

	# vsaka animacije ja prehod med scenami
	Batnz.allow_ui_sfx = false


# MENU BTNZ ---------------------------------------------------------------------------------------------------


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


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_cancel")

	match current_screen:
		Screens.ABOUT:
			$About/BackBtn.grab_focus()
			animation_player.play_backwards("about")
		Screens.SETTINGS:
			$Settings/BackBtn.grab_focus()
			animation_player.play_backwards("settings")
		Screens.HIGHSCORES:
			$Highscores/BackBtn.grab_focus()
			animation_player.play_backwards("highscores")
		Screens.SELECT_LEVEL:
			$SelectSweeper/BackBtn.grab_focus()
			animation_player.play_backwards("select_sweeper")
		Screens.SELECT_ERASER:
			$SelectEraser/BackBtn.grab_focus()
			animation_player.play_backwards("select_eraser")
		Screens.MAIN_MENU:
			return

	menu_in()
