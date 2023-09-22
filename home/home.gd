extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer

enum Screens {MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, HIGHSCORES}
var current_screen = Screens.MAIN_MENU


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
	$Menu/PlayBtn.grab_focus()
			
			
# MAIN MENU ---------------------------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:
	
	match animation_name:
		"select_game":
			if animation_reversed("select_game"):
				return
			current_screen = Screens.SELECT_GAME
			$SelectGame/SelectGameBtn1.grab_focus()
			
		"about":
			if animation_reversed("about"):
				return
			current_screen = Screens.ABOUT
			$About/AboutBackBtn.grab_focus()
		"settings":
			if animation_reversed("settings"):
				return
			current_screen = Screens.SETTINGS
			$Settings/MenuMusicCheckBox.grab_focus()
		"highscores":
			if animation_reversed("highscores"):
				return
			current_screen = Screens.HIGHSCORES
			$Highscores/HighscoresBackBtn.grab_focus()


func animation_reversed(from_screen: String):
	
	# pomeni da se odpre main menu
	if animation_player.current_animation_position == 0:
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
		return true


func _on_PlayBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	
	$Menu/PlayBtn.disabled = true # da ne moreš multiklikat

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
	$Highscores/HighscoreTable.get_highscore_table(100) # številka je ranking izven lesvice in nič ni označeno
	animation_player.play("highscores")


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

	
func _on_SelectGameBtn1_pressed() -> void:
	Profiles.default_level_stats["stray_pixels_count"] = Profiles.settings_strays_amount_1
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	$SelectGame/SelectGameBtn1.disabled = true # da ne moreš multiklikat

func _on_SelectGame2Btn_pressed() -> void:
	Profiles.default_level_stats["stray_pixels_count"] = Profiles.settings_strays_amount_2
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	$SelectGame/SelectGameBtn2.disabled = true # da ne moreš multiklikat

func _on_SelectGame3Btn_pressed() -> void:
	Profiles.default_level_stats["stray_pixels_count"] = Profiles.settings_strays_amount_3
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	$SelectGame/SelectGameBtn3.disabled = true # da ne moreš multiklikat

func _on_SelectGame4Btn_pressed() -> void:
	Profiles.default_level_stats["stray_pixels_count"] = Profiles.settings_strays_amount_4
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	$SelectGame/SelectGameBtn4.disabled = true # da ne moreš multiklikat

func _on_SelectGame5Btn_pressed() -> void:
	Profiles.default_level_stats["stray_pixels_count"] = Profiles.settings_strays_amount_5
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
	$SelectGame/SelectGameBtn5.disabled = true # da ne moreš multiklikat
