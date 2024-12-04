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


#func _unhandled_input(event: InputEvent) -> void:
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
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicBtn.set_pressed_no_signal(false)
	else:
		$MenuMusicBtn.set_pressed_no_signal(true)
	# pregame screen
	if Profiles.pregame_screen_on:
		$InstructionsBtn.set_pressed_no_signal(true)
	else:
		$InstructionsBtn.set_pressed_no_signal(false)
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
		$TrackingBtn.set_pressed_no_signal(true)
	else:
		$TrackingBtn.set_pressed_no_signal(false)
	# reset data
	if Profiles.html5_mode:
		$ResetLocalBtn.hide()
	else:
		$ResetLocalBtn.show()
		$ResetDataPopup.add_item("About to reset local scores ...", 0)
		$ResetDataPopup.add_item("Maybe later", 1)
		$ResetDataPopup.add_item("Do it!", 2)
		$ResetDataPopup.set_item_disabled(0, true)
		$ResetDataPopup.set_current_index(1)

	# IN-GAME SETTINGS ------------------------------------------------------------------

	# game music state
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.set_pressed_no_signal(false)
	else:
		$GameMusicBtn.set_pressed_no_signal(true)
	# game music volume
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten
	# game sfx state
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.set_pressed_no_signal(false)
	else:
		$GameSfxBtn.set_pressed_no_signal(true)
	# cam shake state
	if Profiles.camera_shake_on:
		$CameraShakeBtn.set_pressed_no_signal(true)
	else:
		$CameraShakeBtn.set_pressed_no_signal(false)

	# touch controlls type
	if OS.has_touchscreen_ui_hint():
		# btn
		$TouchPopUpBtn.show()
		var selected_controller_content: Dictionary = Profiles.touch_controller_content.values()[Profiles.set_touch_controller]
		var selected_controller_key: String = selected_controller_content.keys()[0]
		$TouchPopUpBtn.text = "Touch controls: %s" % selected_controller_key
		# popup
		for controller_count in Profiles.TOUCH_CONTROLLER.size():
			var controller_content: Dictionary = Profiles.touch_controller_content.values()[controller_count]
			var controller_title_key: String = controller_content.keys()[0]
			var controller_description: String = controller_content[controller_title_key]
			$TouchControllerPopup.add_item(controller_description, controller_count)
		# sensi-slider
		if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
			$TouchSensSlider.show()
		else:
			$TouchSensSlider.hide()
	else:
		$TouchPopUpBtn.hide()
		$TouchSensSlider.hide()


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("settings")


# APP SETTINGS ----------------------------------------------------------------------------------------------------------------


func _on_MenuMusicBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu_music")
	else:
		Global.sound_manager.menu_music_set_to_off = true
		Global.sound_manager.stop_music("menu_music")


func _on_TrackingBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Analytics.update_session()
		Profiles.set_deferred("analytics_mode", true) # deferr da ujame klik

	else:
		Profiles.analytics_mode = false


func _on_InstructionsBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Profiles.pregame_screen_on = true
	else:
		Profiles.pregame_screen_on = false


func _on_ResetLocalButton_pressed() -> void:

	get_parent().home_swipe_btn.hide()
	$ResetDataPopup.popup_centered()


func _on_ResetDataPopup_index_pressed(index: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_confirm")
	if index == 1:
		Analytics.save_ui_click("ResetData-No")
	elif index == 2:
		highscores_node.reset_all_local_scores()
		Analytics.save_ui_click("ResetData-Yes")
	get_parent().home_swipe_btn.show()


func _on_ResetDataPopup_id_focused(id: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_focus_change")


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


# IN-GAME SETTINGS ----------------------------------------------------------------------------------------------------------------


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
	else:
		Global.sound_manager.game_music_set_to_off = true


func _on_MusicHSlider_value_changed(value: float) -> void:

	Global.sound_manager.set_game_music_volume(value)


func _on_GameMusicSlider_drag_ended(value_changed: bool) -> void: # za analitiko

	Analytics.save_ui_click([$GameMusicSlider, $GameMusicSlider.value])


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Profiles.camera_shake_on = true
	else:
		Profiles.camera_shake_on = false


# TOUCH CONTROLS ----------------------------------------------------------------------------------------------------------------


func _on_TouchPopUpBtn_pressed() -> void:

	$TouchControllerPopup.set_current_index(Profiles.set_touch_controller)
	get_parent().home_swipe_btn.hide()
	$TouchControllerPopup.popup_centered()


func _on_TouchControllerPopup_index_pressed(index: int) -> void:

	Profiles.set_touch_controller = index
	var controller_content: Dictionary = Profiles.touch_controller_content.values()[index]
	var controller_key: String = controller_content.keys()[0]

	$TouchPopUpBtn.text = "Touch controls: %s" % controller_key
	Global.sound_manager.play_gui_sfx("btn_confirm")

	get_parent().home_swipe_btn.show()
	Analytics.save_ui_click("TouchController %s" % controller_key)

	# ugasnem za buttons in none
	if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()


func _on_TouchControllerPopup_id_focused(id: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_focus_change")


func _on_SensSlider_value_changed(value: float) -> void:

	Profiles.screen_touch_sensitivity = value


func _on_SensSlider_drag_ended(value_changed: bool) -> void:

	Analytics.save_ui_click([$TouchSensSlider, $TouchSensSlider.value])
