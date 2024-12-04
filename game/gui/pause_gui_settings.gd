extends Panel


onready var touch_controller_popup: PopupMenu = $"../TouchControllerPopup"


func _ready() -> void:

	# settings btns
	$ShowHintBtn.hide()
	$TouchPopUpBtn.hide()
	#	elif Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
	#		$ShowHintBtn.show()
	# touch controlls
	if OS.has_touchscreen_ui_hint():
#		$TouchPopUpBtn.show()
#		for touch_controller in Profiles.TOUCH_CONTROLLER:
#			touch_controller_popup.add_item(touch_controller, Profiles.TOUCH_CONTROLLER[touch_controller])
#		var current_controller: String = Profiles.TOUCH_CONTROLLER.keys()[Profiles.set_touch_controller]
#		$TouchPopUpBtn.text = "TOUCH CONTROLS\n%s" % current_controller


		# btn
		$TouchPopUpBtn.show()
		var selected_controller_content: Dictionary = Profiles.touch_controller_content.values()[Profiles.set_touch_controller]
		var selected_controller_key: String = selected_controller_content.keys()[0]
		$TouchPopUpBtn.text = "TOUCH CONTROLS\n%s" % selected_controller_key
		# popup
		for controller_count in Profiles.TOUCH_CONTROLLER.size():
			var controller_content: Dictionary = Profiles.touch_controller_content.values()[controller_count]
			var controller_title_key: String = controller_content.keys()[0]
			var controller_description: String = controller_content[controller_title_key]
			touch_controller_popup.add_item(controller_description, controller_count)

func update_settings_btns():

	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.set_pressed_no_signal(false)
	else:
		$GameMusicBtn.set_pressed_no_signal(true)

	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten

	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.set_pressed_no_signal(false)
	else:
		$GameSfxBtn.set_pressed_no_signal(true)

	if Profiles.camera_shake_on:
		$CameraShakeBtn.set_pressed_no_signal(true)
	else:
		$CameraShakeBtn.set_pressed_no_signal(false)

	# specialci

	if $ShowHintBtn.visible:
		if Global.current_tilemap.solution_line.visible:
			$ShowHintBtn.set_pressed_no_signal(true)
		else:
			$ShowHintBtn.set_pressed_no_signal(false)

	if $TouchPopUpBtn.visible:
		$TouchSensSlider.value = Profiles.screen_touch_sensitivity
		if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
			$TouchSensSlider.show()
		else:
			$TouchSensSlider.hide()
	else:
		$TouchSensSlider.hide()


# SETTINGS BTNZ ---------------------------------------------------------------------------------------------


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.music_toggle(false)
	else:
		Global.sound_manager.music_toggle(true)


func _on_GameMusicSlider_value_changed(value: float) -> void:

	Global.sound_manager.set_game_music_volume(value)


func _on_GameMusicSlider_drag_ended(value_changed: bool) -> void: # za analitiko

	Analytics.save_ui_click([$GameMusicSlider, $GameMusicSlider.value])


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Profiles.camera_shake_on = true
	else:
		Profiles.camera_shake_on = false


func _on_ShowHintBtn_toggled(button_pressed: bool) -> void:

	var solution_line: Line2D = Global.current_tilemap.solution_line

	if button_pressed:
		Global.current_tilemap.solution_line.show()
	else:
		Global.current_tilemap.solution_line.hide()


func _on_TouchPopUpBtn_pressed() -> void:

	touch_controller_popup.set_current_index(Profiles.set_touch_controller)
	touch_controller_popup.popup_centered()


func _on_TouchControllerPopup_id_focused(id: int) -> void:

	Global.sound_manager.play_gui_sfx("btn_focus_change")


func _on_TouchControllerPopup_index_pressed(index: int) -> void:

	Profiles.set_touch_controller = index
	var controller_content: Dictionary = Profiles.touch_controller_content.values()[index]
	var controller_key: String = controller_content.keys()[0]

	$TouchPopUpBtn.text = "TOUCH CONTROLS\n%s" % controller_key
	Global.sound_manager.play_gui_sfx("btn_confirm")

	Analytics.save_ui_click("TouchController %s" % controller_key)

	# ugasnem za buttons in none
	if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()

	Global.hud.touch_controls.current_touch_controller = Profiles.set_touch_controller


func _on_TouchSensSlider_value_changed(value: float) -> void:

	Profiles.screen_touch_sensitivity = value


func _on_TouchSensSlider_drag_ended(value_changed: bool) -> void:

	Analytics.save_ui_click([$TouchSensSlider, $TouchSensSlider.value])
