extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer

enum Screens {MAIN_MENU, SELECT_GAME, ABOUT, SETTINGS, CREDITS}
var current_screen = Screens.MAIN_MENU


func _ready():
	$Menu/PlayBtn.grab_focus()
	pass


func _process(delta: float) -> void:
	
	# change focus sounds
	if current_screen == Screens.MAIN_MENU:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_sfx("btn_focus_change")
	elif current_screen == Screens.SELECT_GAME: # or current_screen == Screens.SETTINGS:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_sfx("btn_focus_change")	
		if Input.is_action_just_pressed("ui_up"):
			Global.sound_manager.play_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_down"):
			Global.sound_manager.play_sfx("btn_focus_change")
			
			
# MAIN MENU ---------------------------------------------------------------------------------------------------


func _on_AnimationPlayer_animation_finished(animation_name: String) -> void:
	
	match animation_name:
		"select_game":
			if animation_reversed("select_game"):
				return
			current_screen = Screens.SELECT_GAME
			$SelectGame/Game1/SelectGameBtn.grab_focus()
			
		"about":
			if animation_reversed("about"):
				return
			current_screen = Screens.ABOUT
			$About/BackBtn.grab_focus()
		"settings":
			if animation_reversed("settings"):
				return
			current_screen = Screens.SETTINGS
			$Settings/BackBtn.grab_focus()
		"credits":
			if animation_reversed("credits"):
				return
			current_screen = Screens.CREDITS
			$Credits/BackBtn.grab_focus()
	

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
			"credits":
				$Menu/CreditsBtn.grab_focus()
		current_screen = Screens.MAIN_MENU
		return true


func _on_PlayBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?

func _on_SelectGameBtn_pressed() -> void:
	Global.sound_manager.play_sfx("screen_slide")
	Global.sound_manager.play_sfx("btn_confirm")
	animation_player.play("select_game")


func _on_AboutBtn_pressed() -> void:
	Global.sound_manager.play_sfx("screen_slide")
	Global.sound_manager.play_sfx("btn_confirm")
	animation_player.play("about")


func _on_SettingsBtn_pressed() -> void:
	Global.sound_manager.play_sfx("screen_slide")
	Global.sound_manager.play_sfx("btn_confirm")
	animation_player.play("settings")


func _on_CreditsBtn_pressed() -> void:
	Global.sound_manager.play_sfx("screen_slide")
	Global.sound_manager.play_sfx("btn_confirm")
	animation_player.play("credits")


# BACK BTNZ ---------------------------------------------------------------------------------------------------


func _on_SelectGameBackBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_cancel")
	Global.sound_manager.play_sfx("screen_slide")
	animation_player.play_backwards("select_game")

func _on_AboutBackBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_cancel")
	Global.sound_manager.play_sfx("screen_slide")
	animation_player.play_backwards("about")

	
func _on_SettingsBackBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_cancel")
	Global.sound_manager.play_sfx("screen_slide")
	animation_player.play_backwards("settings")
	
	
func _on_CreditsBackBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_cancel")
	Global.sound_manager.play_sfx("screen_slide")
	animation_player.play_backwards("credits")


# SELECT GAME ---------------------------------------------------------------------------------------------------

	
func _on_SelectGame1Btn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?


func _on_SelectGame2Btn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	Global.main_node.home_out() 
