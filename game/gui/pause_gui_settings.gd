extends Panel


onready var touch_controller_popup: PopupMenu = $"../TouchControllerPopup"
onready var game_outline: HFlowContainer = $"../GameOutline"


func _ready() -> void:

	$TouchPopUpBtn.hide()

	if Profiles.touch_available:
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

	$GameMusicBtn.set_pressed_no_signal(not Global.sound_manager.game_music_set_to_off)
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic"))
	$GameSfxBtn.set_pressed_no_signal(not Global.sound_manager.game_sfx_set_to_off)
	$CameraShakeBtn.set_pressed_no_signal(Profiles.camera_shake_on)
	$BrightnessSlider.value = Profiles.brightness

	# specialci
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

	Global.sound_manager.music_toggle(not button_pressed)


func _on_GameMusicSlider_value_changed(value: float) -> void:

	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	Global.sound_manager.game_sfx_set_to_off = not button_pressed


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	Profiles.camera_shake_on = button_pressed


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

#	Analytics.save_ui_click("TouchControls %s" % controller_key)

	# ugasnem za buttons in none
	if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()

	Global.hud.touch_controls.current_touch_controller = Profiles.set_touch_controller
#	get_parent().game_outline.get_instructions_content() # apdejt slikce
	get_parent().game_outline.call_deferred("get_instructions_content")

func _on_TouchSensSlider_value_changed(value: float) -> void:

	Profiles.screen_touch_sensitivity = value


func _on_BrightnessSlider_value_changed(value: float) -> void:

	Profiles.brightness = value

