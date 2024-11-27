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
		$TouchPopUpBtn.show()
		for touch_controller in Profiles.TOUCH_CONTROLLER:
			touch_controller_popup.add_item(touch_controller, Profiles.TOUCH_CONTROLLER[touch_controller])
		var current_controller: String = Profiles.TOUCH_CONTROLLER.keys()[Profiles.set_touch_controller]
		$TouchPopUpBtn.text = "TOUCH CONTROLS\n%s" % current_controller


func update_settings_btns():

	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.pressed = false
	else:
		$GameMusicBtn.pressed = true

	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten

	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.pressed = false
	else:
		$GameSfxBtn.pressed = true

	if Profiles.camera_shake_on:
		$CameraShakeBtn.pressed = true
	else:
		$CameraShakeBtn.pressed = false

	# specialci

	if $ShowHintBtn.visible:
		if Global.current_tilemap.solution_line.visible:
			$ShowHintBtn.pressed = true
		else:
			$ShowHintBtn.pressed = false

	if $TouchPopUpBtn.visible:
		$TouchSensSlider.value = Profiles.screen_touch_sensitivity
		if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.COMBO:
			$TouchSensSlider.show()
		else:
			$TouchSensSlider.hide()
	else:
		$TouchSensSlider.hide()


# SETTINGS BTNZ ---------------------------------------------------------------------------------------------


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($GameMusicBtn) # za analitiko

	if button_pressed:
		Global.sound_manager.music_toggle(false)
	else:
		Global.sound_manager.music_toggle(true)


func _on_GameMusicSlider_value_changed(value: float) -> void:

	Global.sound_manager.set_game_music_volume(value)


func _on_GameMusicSlider_drag_ended(value_changed: bool) -> void: # za analitiko

	Analytics.save_ui_click([$GameMusicSlider, $GameMusicSlider.value])


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($GameSfxBtn) # za analitiko
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:

	Global.grab_focus_nofx($CameraShakeBtn) # za analitiko
	if button_pressed:
		Profiles.camera_shake_on = true
	else:
		Profiles.camera_shake_on = false


func _on_ShowHintBtn_toggled(button_pressed: bool) -> void:

	var solution_line: Line2D = Global.current_tilemap.solution_line

	Global.grab_focus_nofx($ShowHintBtn) # za analitiko
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
	var controller_key: String = Profiles.TOUCH_CONTROLLER.keys()[index]
	$TouchPopUpBtn.text = "TOUCH CONTROLS\n%s" % controller_key
	Global.sound_manager.play_gui_sfx("btn_confirm")

	Analytics.save_ui_click("TouchController %s" % controller_key)

	# ugasnem za buttons in none
	if Profiles.set_touch_controller >= Profiles.TOUCH_CONTROLLER.COMBO:
		$TouchSensSlider.show()
	else:
		$TouchSensSlider.hide()

	Global.hud.touch_controls.current_touch_controller = Profiles.set_touch_controller



func _on_SensSlider_value_changed(value: float) -> void:

	Global.grab_focus_nofx($TouchSensSlider) # za analitiko
	Profiles.screen_touch_sensitivity = value


func _on_SensSlider_drag_ended() -> void:

	Analytics.save_ui_click([$TouchSensSlider, $TouchSensSlider.value])

