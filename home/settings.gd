extends Control


onready var randomize_btn: Button = $ColorSchemeOptions/RandomizeBtn
onready var reset_btn: Button = $ColorSchemeOptions/ResetBtn
onready var gradient_icon: TextureRect = $ColorSchemeOptions/RandomizeBtn/GradientIcon
onready var spectrum_icon: TextureRect = $ColorSchemeOptions/RandomizeBtn/SpectrumIcon

onready var intro: Node2D = $"%Intro"
onready var select_level_node: Control = $"../SelectLevel"
onready var select_game_node: Control = $"../SelectGame"
onready var highscores_node: Control = $"../Highscores"
onready var default_focus_node: Control = $MenuMusicBtn


func _ready() -> void:

	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)

	# APP SETTINGS ------------------------------------------------------------------

	# menu music
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicBtn.pressed = false
	else:
		$MenuMusicBtn.pressed = true
	# pregame screen
	if Profiles.default_game_settings["show_game_instructions"] == true:
		$InstructionsBtn.pressed = true
	else:
		$InstructionsBtn.pressed = false
	# color scheme
	if Profiles.use_default_color_theme:
		spectrum_icon.show()
		gradient_icon.hide()
		reset_btn.hide()
	else:
		spectrum_icon.hide()
		gradient_icon.show()
		reset_btn.show()
		gradient_icon.texture.gradient = Global.game_color_theme_gradient
	# data tracking
	if Profiles.analytics_mode:
		$TrackingBtn.pressed = true
	else:
		$TrackingBtn.pressed = false
	# cam shake state
	if Profiles.html5_mode:
		$ResetLocalBtn.hide()
	else:
		$ResetLocalBtn.show()


	# IN-GAME SETTINGS ------------------------------------------------------------------


	# game music state
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.pressed = false
	else:
		$GameMusicBtn.pressed = true
	# game music volume
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten
	# game sfx state
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.pressed = false
	else:
		$GameSfxBtn.pressed = true
	# cam shake state
	if Profiles.camera_shake_on:
		$CameraShakeBtn.pressed = true
	else:
		$CameraShakeBtn.pressed = false
	# touch controlls
	if OS.has_touchscreen_ui_hint():
		$TouchControllerOptions.show()
		for touch_controller in Profiles.TOUCH_CONTROLLER:
			var item_string: String = "Touch controller: " + touch_controller
			$TouchControllerOptions.add_item(item_string, Profiles.TOUCH_CONTROLLER[touch_controller])
		$TouchControllerOptions.selected = Profiles.set_touch_controller
	$TouchSensSlider.value = Profiles.screen_touch_sensitivity
	if Profiles.set_touch_controller > 1:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("settings")


func _on_MenuMusicBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($MenuMusicBtn) # za analitiko

	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu_music")
	else:
		Global.sound_manager.stop_music("menu_music")
		Global.sound_manager.menu_music_set_to_off = true


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($GameMusicBtn) # za analitiko
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
	else:
		Global.sound_manager.game_music_set_to_off = true


func _on_MusicHSlider_value_changed(value: float) -> void:

	Global.grab_focus_nofx($GameMusicSlider) # za analitiko
	Global.sound_manager.set_game_music_volume(value)


func _on_GameMusicSlider_drag_ended(value_changed: bool) -> void: # za analitiko

	Analytics.save_ui_click([$GameMusicSlider, $GameMusicSlider.value])


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($GameSfxBtn) # za analitiko
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($CameraShakeBtn) # za analitiko
	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Profiles.camera_shake_on = true
	else:
		Profiles.camera_shake_on = false


func _on_TrackingBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($TrackingBtn) # za analitiko
	if button_pressed:
		Analytics.update_session()
		Profiles.set_deferred("analytics_mode", true) # deferr da ujame klik

	else:
		Profiles.analytics_mode = false


func _on_InstructionsBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Profiles.default_game_settings["show_game_instructions"] = true
	else:
		Profiles.default_game_settings["show_game_instructions"] = false


func _on_ResetLocalButton_pressed() -> void:

	highscores_node.reset_all_local_scores()


# TOUCH CONTROLS ----------------------------------------------------------------------------------------------------------------


func _on_TouchControllerOptions_item_selected(index: int) -> void:

	var controller_key = Profiles.TOUCH_CONTROLLER.keys()[index]
	Profiles.set_touch_controller = Profiles.TOUCH_CONTROLLER[controller_key]
	Global.sound_manager.play_gui_sfx("btn_confirm")
	$TouchControllerOptions.modulate = Color.white
	Analytics.save_ui_click("TouchController %s" % controller_key)

	# ugasnem za buttons in none
	if Profiles.set_touch_controller > 1:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()

func _on_TouchControllerOptions_focus_entered() -> void:

	$TouchControllerOptions.modulate = Color.white # da je moduliran sivo samo na štartu


func _on_SensSlider_value_changed(value: float) -> void:

	Global.grab_focus_nofx($TouchSensSlider) # za analitiko
	Profiles.screen_touch_sensitivity = value


func _on_SensSlider_drag_ended() -> void:

	Analytics.save_ui_click([$TouchSensSlider, $TouchSensSlider.value])





# COLOR SCHEMES ----------------------------------------------------------------------------------------------------------------


func _on_ResetBtn_pressed() -> void:

	spectrum_icon.show()
	gradient_icon.hide()
	reset_btn.hide()

	Profiles.use_default_color_theme = true
	randomize_btn.grab_focus()

	intro.respawn_title_strays()
	select_level_node.select_level_btns_holder.color_level_btns()
	select_game_node.color_game_btns()


func _on_RandomizeBtn_pressed() -> void:

	spectrum_icon.hide()
	gradient_icon.show()
	reset_btn.show()

	Profiles.use_default_color_theme = false

	var current_color_scheme_gradient: Gradient = Global.get_random_gradient_colors(0) # 0 je za pravilno izbiro rezultata funkcije
	gradient_icon.texture.gradient = current_color_scheme_gradient

	intro.respawn_title_strays()
	select_level_node.select_level_btns_holder.set_level_btns()
	select_game_node.color_game_btns()

