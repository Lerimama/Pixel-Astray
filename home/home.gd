extends Node


enum Screens {MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES, SELECT_LEVEL}
var current_screen = Screens.MAIN_MENU # se določi z main animacije

var current_esc_hint: HBoxContainer
var allow_ui_sfx: bool = false # za kontrolo defolt focus soundov

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $Menu
onready var intro: Node2D = $IntroViewPortContainer/IntroViewport/Intro
onready var intro_viewport: Viewport = $IntroViewPortContainer/IntroViewport


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		match current_screen:
			Screens.SELECT_GAME:
				$SelectGame._on_BackBtn_pressed()
			Screens.ABOUT:
				$About._on_BackBtn_pressed()
			Screens.SETTINGS:
				$Settings._on_BackBtn_pressed()
			Screens.HIGHSCORES:
				$Highscores._on_BackBtn_pressed()
			Screens.SELECT_LEVEL:
				$SelectLevel._on_BackBtn_pressed()
	
	if Input.is_action_just_pressed("n"): 
		Global.sound_manager.change_menu_music()
		
			
func _ready():
	
	$Settings/EscHint.modulate.a = 0
	$Highscores/EscHint.modulate.a = 0
	$About/EscHint.modulate.a = 0
	$SelectGame/EscHint.modulate.a = 0
	$SelectLevel/EscHint.modulate.a = 0
	
	
func open_with_intro(): # kliče main.gd -> home_in_intro()
	intro.play_intro() # intro signal na koncu kliče menu_in()
	
	
func open_without_intro(): # debug ... kliče main.gd -> home_in_no_intro()
	intro.finish_intro() # intro signal na koncu kliče menu_in()


func open_from_game(finished_game: int): # select_game screen ... kliče main.gd -> home_in_from_game()

	# mute game efektov, da se ne sliši spawnanje naslovnih pixlov
	AudioServer.set_bus_mute(AudioServer.get_bus_index("GameSfx"), true)
		
	if finished_game == Profiles.Games.SWEEPER:
		animation_player.play("select_level")
		current_screen = Screens.SELECT_LEVEL
	else:
		animation_player.play("select_game")
		current_screen = Screens.SELECT_GAME
	
	# premik animacije na konec
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)
	
	intro.finish_intro()
	
	yield(get_tree().create_timer(1), "timeout") # počaka, da se vsi spawnajo
	if not Global.sound_manager.game_sfx_set_to_off:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("GameSfx"), false)
	
	
func menu_in(): # kliče se na koncu intra, na skip intro in ko se vrnem iz drugih ekranov
	
	menu.visible = true

	current_screen = Screens.MAIN_MENU
	
	Global.grab_focus_no_sfx($Menu/SelectGameBtn)
		
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 1, 1).from(0.0)


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
			if animation_reversed(Screens.SELECT_GAME):
				Global.grab_focus_no_sfx($Menu/SelectGameBtn)
				return
			current_screen = Screens.SELECT_GAME
			current_esc_hint = $SelectGame/EscHint
			Global.grab_focus_no_sfx($SelectGame/GamesMenu/Tutorial/TutorialBtn)
		"about":
			if animation_reversed(Screens.ABOUT):
				Global.grab_focus_no_sfx($Menu/AboutBtn)
				return
			current_screen = Screens.ABOUT
			current_esc_hint = $About/EscHint
			Global.grab_focus_no_sfx($About/BackBtn)
		"settings":
			if animation_reversed(Screens.SETTINGS):
				Global.grab_focus_no_sfx($Menu/SettingsBtn)
				return
			current_screen = Screens.SETTINGS
			current_esc_hint = $Settings/EscHint
			Global.grab_focus_no_sfx($Settings/MenuMusicBtn)
		"highscores":
			if animation_reversed(Screens.HIGHSCORES):
#			if animation_reversed("highscores"):
				Global.grab_focus_no_sfx($Menu/HighscoresBtn)
				return
			current_screen = Screens.HIGHSCORES
			current_esc_hint = $Highscores/EscHint
			Global.grab_focus_no_sfx($Highscores/SweeperArrows/RightBtn)
		"select_level":
			if animation_reversed(Screens.SELECT_LEVEL):
				current_screen = Screens.SELECT_GAME
				Global.grab_focus_no_sfx($SelectGame/GamesMenu/Sweeper/SweeperBtn)
				return
			current_screen = Screens.SELECT_LEVEL
			current_esc_hint = $SelectLevel/EscHint
			Global.grab_focus_no_sfx($SelectLevel/BtnsHolder.get_child(0))
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
				Global.grab_focus_no_sfx($Menu/SelectGameBtn)
				menu_in()
			Screens.ABOUT:
				Global.grab_focus_no_sfx($Menu/AboutBtn)
				menu_in()
			Screens.SETTINGS:
				Global.grab_focus_no_sfx($Menu/SettingsBtn)
				menu_in()
			Screens.HIGHSCORES:
				Global.grab_focus_no_sfx($Menu/HighscoresBtn)
				menu_in()
			Screens.SELECT_LEVEL:
				Global.grab_focus_no_sfx($SelectGame/GamesMenu/Sweeper/SweeperBtn)
		return true
			


# MENU BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_game")
	get_viewport().set_disable_input(true)


func _on_AboutBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("about")
	get_viewport().set_disable_input(true)


func _on_SettingsBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("settings")
	get_viewport().set_disable_input(true)
	

func _on_HighscoresBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("highscores")
	get_viewport().set_disable_input(true)


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
