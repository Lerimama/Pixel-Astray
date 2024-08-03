extends Node


enum Screens {MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES, SELECT_LEVEL}
var current_screen = Screens.MAIN_MENU # se določi z main animacije

var current_esc_hint: HBoxContainer
var allow_ui_sfx: bool = false # za kontrolo defolt focus soundov

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $Menu
onready var intro: Node2D = $IntroViewPortContainer/IntroViewport/Intro
onready var intro_viewport: Viewport = $IntroViewPortContainer/IntroViewport


func _unhandled_input(event: InputEvent) -> void:
	#func _input(event: InputEvent) -> void:
	
	#	if Input.is_action_just_pressed("next"): 
	#		Global.sound_manager.change_menu_music()
	
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
	
			
func _ready():
	
	#visibility
	menu.hide()
	$Settings/EscHint.modulate.a = 0
	$Highscores/EscHint.modulate.a = 0
	$About/EscHint.modulate.a = 0
	$SelectGame/EscHint.modulate.a = 0
	$SelectLevel/EscHint.modulate.a = 0
	
	# btn groups
	$Menu/SelectGameBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/SettingsBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/HighscoresBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/AboutBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/ExitGameBtn.add_to_group(Global.group_menu_cancel_btns)

	if Profiles.html5_mode:
		$Menu/ExitGameBtn.hide()
		# dela brez spodnjega ... čudno ...
		#		$Menu/QuitBtn.focus_neighbour_left = "../RestartBtn"
		#		$Menu/RestartBtn.focus_neighbour_right = "../QuitBtn"		
	
	
func open_with_intro(): # kliče main.gd -> home_in_intro()
	intro.play_intro() # intro signal na koncu kliče menu_in()
	
	
func open_without_intro(): # bugfixing ... kliče main.gd -> home_in_no_intro()
	intro.finish_intro() # intro signal na koncu kliče menu_in()


func open_from_game(finished_game: int): # select_game screen ... kliče main.gd -> home_in_from_game()

	animation_player.play("select_game")
	current_screen = Screens.SELECT_GAME
	
	# premik animacije na konec
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)
	
	# fokus glede na končano igro
	if finished_game == Profiles.Games.CLASSIC:
		Global.focus_without_sfx($SelectGame/GamesMenu/Classic/ClassicBtn)
	elif finished_game == Profiles.Games.CHASER:
		Global.focus_without_sfx($SelectGame/GamesMenu/Timeless/EraserBtn)
	elif finished_game == Profiles.Games.DEFENDER:
		Global.focus_without_sfx($SelectGame/GamesMenu/Timeless/DefenderBtn)
	elif finished_game == Profiles.Games.SWEEPER:
		Global.focus_without_sfx($SelectGame/GamesMenu/Sweeper/SweeperBtn)
	elif finished_game == Profiles.Games.THE_DUEL:
		Global.focus_without_sfx($SelectGame/GamesMenu/TheDuel/TheDuelBtn)
	else: # CLEANER_XS, CLEANER_S, CLEANER_M, CLEANER_L, CLEANER_XL,
		Global.focus_without_sfx($SelectGame/GamesMenu/Cleaner/CleanerSBtn)
	
	intro.finish_intro()
	yield(get_tree().create_timer(1), "timeout") # počaka, da se vsi spawnajo
	
	
func menu_in(): # kliče se na koncu intra, na skip intro in ko se vrnem iz drugih ekranov

	menu.visible = true
	current_screen = Screens.MAIN_MENU
	Global.focus_without_sfx($Menu/SelectGameBtn)
		
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 1, 0.32).from(0.0)


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
			#			if animation_reversed(Screens.SELECT_GAME):
			#				return
			if not animation_reversed(Screens.SELECT_GAME):
				current_screen = Screens.SELECT_GAME
				current_esc_hint = $SelectGame/EscHint
				Global.focus_without_sfx($SelectGame/GamesMenu/Classic/ClassicBtn)
		"about":
			#			if animation_reversed(Screens.ABOUT):
			#				return
			if not animation_reversed(Screens.ABOUT):
				current_screen = Screens.ABOUT
				current_esc_hint = $About/EscHint
				Global.focus_without_sfx($About/BackBtn)
		"settings":
			#			if animation_reversed(Screens.SETTINGS):
			#				return
			if not animation_reversed(Screens.SETTINGS):
				current_screen = Screens.SETTINGS
				current_esc_hint = $Settings/EscHint
				Global.focus_without_sfx($Settings/MenuMusicBtn)
		"highscores":
			#			if animation_reversed(Screens.HIGHSCORES):
			#				return
			if not animation_reversed(Screens.HIGHSCORES):
				current_screen = Screens.HIGHSCORES
				current_esc_hint = $Highscores/EscHint
#				Global.focus_without_sfx($Highscores/Tabs/ClassicTab)
				Global.focus_without_sfx($Highscores.selected_tab_btn)
		"select_level":
			#			if animation_reversed(Screens.SELECT_LEVEL):
			#				return
			if not animation_reversed(Screens.SELECT_LEVEL):
				current_screen = Screens.SELECT_LEVEL
				current_esc_hint = $SelectLevel/EscHint
				Global.focus_without_sfx($SelectLevel.select_level_btns_holder.all_level_btns[0])
		"play_game":
			Global.main_node.home_out()
		"play_level":
			Global.main_node.home_out()
	
	#	if current_esc_hint != null:
	#		var hint_fade_in = get_tree().create_tween()
	#		hint_fade_in.tween_property(current_esc_hint, "modulate:a", 1, 0.32)
		

func animation_reversed(from_screen: int):
	
	if animation_player.current_animation_position == 0: # pomeni, da je animacija v rikverc končana
		current_esc_hint.modulate.a = 0
			
		# preverim s katerega ekrana je animirano še preden zamenjam na MAIN_MENU
		match from_screen:
			Screens.SELECT_GAME:
				Global.focus_without_sfx($Menu/SelectGameBtn)
				menu_in()
			Screens.ABOUT:
				Global.focus_without_sfx($Menu/AboutBtn)
				menu_in()
			Screens.SETTINGS:
				Global.focus_without_sfx($Menu/SettingsBtn)
				menu_in()
			Screens.HIGHSCORES:
				Global.focus_without_sfx($Menu/HighscoresBtn)
				menu_in()
			Screens.SELECT_LEVEL:
				current_screen = Screens.SELECT_GAME
				Global.focus_without_sfx($SelectGame/GamesMenu/Sweeper/SweeperBtn)
				
		return true
			

# MENU BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_game")
	Global.focus_without_sfx($SelectGame/GamesMenu/Classic/ClassicBtn)


func _on_AboutBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("about")


func _on_SettingsBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("settings")
	

func _on_HighscoresBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("highscores")


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
