extends Node


enum Screens {MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES}
var current_screen # se določi z main animacije

var current_esc_hint: HBoxContainer

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var menu: HBoxContainer = $Menu
onready var intro: Node2D = $IntroViewPortContainer/Viewport/Intro
onready var intro_viewport: Viewport = $IntroViewPortContainer/Viewport

onready var tutorial_btn: Button = $SelectGame/TutorialBtn
onready var cleaner_btn: Button = $SelectGame/CleanerBtn
onready var pointer_btn: Button = $SelectGame/PointerBtn
onready var riddler_btn: Button = $SelectGame/RiddlerBtn


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		match current_screen:
			Screens.MAIN_MENU:
				 pass
			Screens.SELECT_GAME:
				_on_SelectGameBackBtn_pressed()
			Screens.ABOUT:
				_on_AboutBackBtn_pressed()
			Screens.SETTINGS:
				_on_SettingsBackBtn_pressed()
			Screens.HIGHSCORES:
				_on_HighscoresBackBtn_pressed()
	
	if current_screen == Screens.MAIN_MENU:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
	elif current_screen == Screens.SELECT_GAME or current_screen == Screens.SETTINGS:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")	
		elif Input.is_action_just_pressed("ui_up"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_down"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_focus_next"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_focus_prev"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
					
					
func _ready():
	
	menu.visible = false
	$Settings/EscHint.modulate.a = 0
	$SelectGame/EscHint.modulate.a = 0
	$Highscores/EscHint.modulate.a = 0
	$About/EscHint.modulate.a = 0
	
	# games buttons text
#	$SelectGame/SelectGameBtn1.text = "Only " + str(Profiles.game_data_S["game"]) + " pixels astray"
#	$SelectGame/SelectGameBtn2.text = str(Profiles.game_data_M["game"]) + " pixels astray"
#	$SelectGame/SelectGameBtn3.text = str(Profiles.game_data_L["game"]) + " pixels astray"
#	$SelectGame/SelectGameBtn4.text = str(Profiles.game_data_XL["game"]) + " pixels astray"
#	$SelectGame/SelectGameBtn5.text = str(Profiles.game_data_XXL["game"]) + " pixels astray"

	
func open_with_intro(): # ... kliče main.gd -> home_in_intro()
	intro.play_intro() # intro signal na koncu kliče home_in()
	
	
func open_without_intro(): # temp ... debug ... kliče main.gd -> home_in_no_intro()
	intro.end_intro() # intro signal na koncu kliče home_in()


func open_from_game(): # select_game screen ... kliče main.gd -> home_in_from_game()
	
	intro.end_intro() # da se prikaže samo naslov ... intro signal na koncu kliče home_in()
	current_screen = Screens.SELECT_GAME # tole blokira menu_in() 
	
	# animacija na konec
	animation_player.play("select_game")
	var animation_length: float = animation_player.get_current_animation_length()
	animation_player.advance(animation_length)
	
	
func menu_in(): # kliče se na koncu intra (tudi na skip)
	
	menu.visible = true
	menu.modulate.a = 0
	intro_viewport.gui_disable_input = true # dokler se predvaja mora biti, da skipanje deluje
	
	if current_screen == Screens.SELECT_GAME:
		return
	
	current_screen = Screens.MAIN_MENU
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(menu, "modulate:a", 1, 1)
	fade_in.tween_callback($Menu/SelectGameBtn, "grab_focus")
	fade_in.tween_callback(Global.sound_manager, "play_music", ["menu"])


# SIGNALI ---------------------------------------------------------------------------------------------------


func _on_Intro_finished_playing() -> void:
	menu_in()
	
	
func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:
	
	
	match animation_name:
		"select_game":
			if animation_reversed("select_game"):
				return
			current_screen = Screens.SELECT_GAME
			tutorial_btn.grab_focus()
			current_esc_hint = $SelectGame/EscHint
		"about":
			if animation_reversed("about"):
				return
			current_screen = Screens.ABOUT
			$About/AboutBackBtn.grab_focus()
			current_esc_hint = $About/EscHint
		"settings":
			if animation_reversed("settings"):
				return
			current_screen = Screens.SETTINGS
			$Settings/MenuMusicCheckBox.grab_focus()
			current_esc_hint = $Settings/EscHint
		"highscores":
			if animation_reversed("highscores"):
				return
			current_screen = Screens.HIGHSCORES
			$Highscores/HighscoresBackBtn.grab_focus()
			current_esc_hint = $Highscores/EscHint
		"play":
			Global.main_node.home_out()

	if current_esc_hint != null:
		var hint_fade_in = get_tree().create_tween()
		hint_fade_in.tween_property(current_esc_hint, "modulate:a", 1, 1)
		

func animation_reversed(from_screen: String):
	
	if animation_player.current_animation_position == 0: # pomeni da se odpre main menu
		# set focus
		match from_screen:
			"select_game":
				$Menu/SelectGameBtn.grab_focus()
			"about":
				$Menu/AboutBtn.grab_focus()
			"settings":
				$Menu/SettingsBtn.grab_focus()
			"highscores":
				$Menu/HighscoresBtn.grab_focus()
		current_screen = Screens.MAIN_MENU
		current_esc_hint.modulate.a = 0
		
		return true


# MENU BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("select_game")


func _on_AboutBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("about")


func _on_SettingsBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("settings")


func _on_HighscoresBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
#	var fake_player_ranking: int = 100
#	$Highscores.load_all_highscores(fake_player_ranking)
	animation_player.play("highscores")


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
	
	
# BACK BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBackBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")


func _on_AboutBackBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("about")


func _on_SettingsBackBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("settings")


func _on_HighscoresBackBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")


# SELECT GAME ---------------------------------------------------------------------------------------------------


func _on_TutorialBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.TUTORIAL)
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("play") # home out je signal na koncu animacije
	
	tutorial_btn.disabled = true # da ne moreš multiklikat

# cleaner

func _on_CleanerSBtn_pressed() -> void:
	
	Profiles.set_game_data(Profiles.Games.CLEANER_S)
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("play") # home out je signal na koncu animacije


func _on_CleanerMBtn_pressed() -> void:
	Profiles.set_game_data(Profiles.Games.CLEANER_M)
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("play")


func _on_CleanerLBtn_pressed() -> void:

	Profiles.set_game_data(Profiles.Games.CLEANER_L)
	Global.sound_manager.play_gui_sfx("screen_slide")
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("play")
	
	
func _on_CleanerBtn_pressed() -> void:
	pass # Replace with function body.


func _on_PointerBtn_pressed() -> void:
	pass # Replace with function body.


func _on_RiddlerBtn_pressed() -> void:
	pass # Replace with function body.



