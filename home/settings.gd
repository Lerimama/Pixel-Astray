extends Control


func _ready() -> void:
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # za_poenoten slajder v settingsih in pavzi
	
	
func _process(delta: float) -> void:
	
	# pravilno stanje settingsov
	
	# menu music
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicCheckBox.pressed = false
	else:
		$MenuMusicCheckBox.pressed = true

	# game music
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicCheckBox.pressed = false
	else:
		$GameMusicCheckBox.pressed = true
	
	# game sfx
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxCheckBox.pressed = false
	else:
		$GameSfxCheckBox.pressed = true
	
	# camera shake
	if Global.main_node.camera_shake_on:
		$CamerShakeCheckBox.pressed = true
	else:
		$CamerShakeCheckBox.pressed = false
	

func _on_MenuMusicCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu")
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.stop_music("menu")
		Global.sound_manager.menu_music_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")

	
func _on_GameMusicCheckBox_toggled(button_pressed: bool) -> void: 
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_MusicHSlider_value_changed(value: float) -> void:
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxCheckBox_toggled(button_pressed: bool) -> void:
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.game_sfx_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_CamerShakeCheckBox_toggled(button_pressed: bool) -> void:
	
	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.main_node.camera_shake_on = true
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.main_node.camera_shake_on = false
		Global.sound_manager.play_gui_sfx("btn_cancel")


#func _on_StrayCountOptionButton_item_selected(index: int) -> void:
#	match index:
#		0: Profiles.level_data["stray_pixels_count"] = Profiles.settings_strays_amount_1
#		1: Profiles.level_data["stray_pixels_count"] = Profiles.settings_strays_amount_2
#		2: Profiles.level_data["stray_pixels_count"] = Profiles.settings_strays_amount_3
#		3: Profiles.level_data["stray_pixels_count"] = Profiles.settings_strays_amount_4
#		4: Profiles.level_data["stray_pixels_count"] = Profiles.settings_strays_amount_5
