extends Control


onready var randomize_btn: Button = $Content/ColorSchemeOptions/RandomizeBtn
onready var reset_btn: Button = $Content/ColorSchemeOptions/SchemeResetBtn
onready var gradient_icon: TextureRect = $Content/ColorSchemeOptions/RandomizeBtn/GradientIcon
onready var spectrum_icon: TextureRect = $Content/ColorSchemeOptions/RandomizeBtn/SpectrumIcon

onready var intro: Node2D = $"%Intro"
onready var select_level_node: Control = $"../SelectLevel"
onready var select_game_node: Control = $"../SelectGame"
onready var highscores_node: Control = $"../Highscores"
onready var default_focus_node: Control = $Content/MenuMusicBtn


func _input(event: InputEvent) -> void:

	if $TouchControllerPopup.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			$TouchControllerPopup.hide()
			get_parent().home_swipe_btn.show()
			get_tree().set_input_as_handled()

	if $ResetDataPopup.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			$ResetDataPopup.hide()
			get_parent().home_swipe_btn.show()
			get_tree().set_input_as_handled()


func _ready() -> void:

	# menu btn group
	$BackBtn.add_to_group(Batnz.group_cancel_btns)

	# APP SETTINGS ------------------------------------------------------------------

	# menu music
	default_focus_node.set_pressed_no_signal(not Global.sound_manager.menu_music_set_to_off)
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
	$Content/ContrastSlider.value = Profiles.brightness
	$Content/VsyncBtn.set_pressed_no_signal(Profiles.vsync_on)
	$Content/InvertBtn.set_pressed_no_signal(Global.main_node.inverted_scheme.visible)

	# GAME SETTINGS ------------------------------------------------------------------

	$Content/GameMusicBtn.set_pressed_no_signal(not Global.sound_manager.game_music_set_to_off)
	$Content/GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten
	$Content/InstructionsBtn.set_pressed_no_signal(Profiles.pregame_screen_on)
	$Content/GameSfxBtn.set_pressed_no_signal(not Global.sound_manager.game_sfx_set_to_off)
	$Content/CameraShakeBtn.set_pressed_no_signal(Profiles.camera_shake_on)
	# controler type
	if Profiles.touch_available:
		# btn
		$Content/TouchPopUpBtn.show()
		var selected_controller_content: Dictionary = Profiles.touch_controller_content.values()[Profiles.set_touch_controller]
		var selected_controller_key: String = selected_controller_content.keys()[0]
		$Content/TouchPopUpBtn.text = "Touch controls: %s" % selected_controller_key
		# popup
		for controller_count in Profiles.TOUCH_CONTROLLER.size():
			var controller_content: Dictionary = Profiles.touch_controller_content.values()[controller_count]
			var controller_title_key: String = controller_content.keys()[0]
			var controller_description: String = controller_content[controller_title_key]
			$TouchControllerPopup.add_item(controller_description, controller_count)
		# sensi-slider
		if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
			$Content/TouchSensSlider.show()
		else:
			$Content/TouchSensSlider.hide()
	else:
		$Content/TouchPopUpBtn.hide()
		$Content/TouchSensSlider.hide()

	# RED ZONE ------------------------------------------------------------------

	if Profiles.html5_mode:
		$Content/ResetLocalBtn.hide()
		$Content/TrackingBtn.hide()
		$Content/HSeparator2.hide()
	else:
		# data tracking
		$Content/TrackingBtn.set_pressed_no_signal(Profiles.analytics_mode)
		# reset local data
		$Content/ResetLocalBtn.show()
		$ResetDataPopup.add_item("About to reset local scores ...", 0)
		$ResetDataPopup.add_item("Maybe later", 1)
		$ResetDataPopup.add_item("Do it!", 2)
		$ResetDataPopup.set_item_disabled(0, true)
		$ResetDataPopup.set_current_index(1)


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("settings")


# APP SETTINGS ----------------------------------------------------------------------------------------------------------------


func _on_MenuMusicBtn_toggled(button_pressed: bool) -> void:

	Global.sound_manager.menu_music_set_to_off = not button_pressed

	if Global.sound_manager.menu_music_set_to_off:
		Global.sound_manager.stop_music("menu_music")
	else:
		Global.sound_manager.play_music("menu_music")


func _on_SchemeResetBtn_pressed() -> void:

	spectrum_icon.show()
	gradient_icon.hide()
	reset_btn.hide()

	Profiles.use_default_color_theme = true
	randomize_btn.grab_focus()

	intro.respawn_title_strays()
	select_level_node.select_level_btns_holder.colorize_level_btns()
	select_game_node.colorize_game_btns()


func _on_RandomizeBtn_pressed() -> void:

	if not intro.creating_strays:
		spectrum_icon.hide()
		gradient_icon.show()
		reset_btn.show()

		Profiles.use_default_color_theme = false

		var current_color_scheme_gradient: Gradient = Global.get_random_gradient_colors(0) # 0 je za pravilno izbiro rezultata funkcije
		gradient_icon.texture.gradient = current_color_scheme_gradient

		intro.respawn_title_strays()
#		select_level_node.select_level_btns_holder.colorize_level_btns()
		select_game_node.colorize_game_btns()


func _on_VsyncBtn_toggled(button_pressed: bool) -> void:

	Profiles.vsync_on = button_pressed


func _on_ContrastBtn_value_changed(value: float) -> void:

	Profiles.brightness = value


# IN-GAME SETTINGS ----------------------------------------------------------------------------------------------------------------


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	Global.sound_manager.game_music_set_to_off = not button_pressed


func _on_InstructionsBtn_toggled(button_pressed: bool) -> void:

	Profiles.pregame_screen_on = button_pressed


func _on_MusicHSlider_value_changed(value: float) -> void: # home settinsih je disebjlan

	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	Global.sound_manager.game_sfx_set_to_off = not button_pressed


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	Profiles.camera_shake_on = button_pressed


# TOUCH CONTROLS ----------------------------------------------------------------------------------------------------------------


func _on_TouchPopUpBtn_pressed() -> void:

	$TouchControllerPopup.set_current_index(Profiles.set_touch_controller)
	get_parent().home_swipe_btn.hide()
	$TouchControllerPopup.popup_centered()


func _on_TouchControllerPopup_index_pressed(index: int) -> void:

	Profiles.set_touch_controller = index
	var controller_content: Dictionary = Profiles.touch_controller_content.values()[index]
	var controller_key: String = controller_content.keys()[0]

	$Content/TouchPopUpBtn.text = "Touch controls: %s" % controller_key
	Global.sound_manager.play_gui_sfx("btn_confirm")

	Analytics.save_ui_click("TouchControls %s" % controller_key)

	get_parent().home_swipe_btn.show()

	# ugasnem za buttons in none
	if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
		$Content/TouchSensSlider.show()
	else:
		$Content/TouchSensSlider.hide()


func _on_TouchControllerPopup_id_focused(id: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_focus_change")


func _on_SensSlider_value_changed(value: float) -> void:

	Profiles.screen_touch_sensitivity = value


# DANGER ZONE ----------------------------------------------------------------------------------------------------------------


func _on_TrackingBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Profiles.analytics_mode = true
	else:
		Analytics.update_session()
		Profiles.set_deferred("analytics_mode", false) # deferr da ujame klik


func _on_ResetLocalButton_pressed() -> void:

	get_parent().home_swipe_btn.hide()
	$ResetDataPopup.popup_centered()


func _on_ResetDataPopup_index_pressed(index: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_confirm")
	if index == 2:
		highscores_node.reset_all_local_scores()
	get_parent().home_swipe_btn.show()


func _on_ResetDataPopup_id_focused(id: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_focus_change")


func _on_InvertBtn_toggled(button_pressed: bool) -> void:

	var fade_time: float = 1
	Global.main_node.invert_colors(fade_time)

	# disejbl, da se ne da klikat
	$Content/InvertBtn.disabled = true
	yield(get_tree().create_timer(fade_time), "timeout")
	$Content/InvertBtn.disabled = false
