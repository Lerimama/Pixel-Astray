extends Control


onready var title: Label = $Title
onready var instructions: Control = $Instructions


func _input(event: InputEvent) -> void:
	
			
	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("pause"):
			if not visible:
				pause_game()
			else:
				_on_PlayBtn_pressed()

func _ready() -> void:
	
	visible = false
	modulate.a = 0
	
	# menu btn group
	$Menu/PlayBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/SkipTutBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/RestartBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/QuitBtn.add_to_group(Global.group_menu_cancel_btns)
	
	# update settings btns	
	if Global.sound_manager.game_music_set_to_off:
		$Settings/GameMusicBtn.pressed = false
	else:
		$Settings/GameMusicBtn.pressed = true
	$Settings/GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten
	if Global.sound_manager.game_sfx_set_to_off:
		$Settings/GameSfxBtn.pressed = false
	else:
		$Settings/GameSfxBtn.pressed = true
	if Profiles.camera_shake_on:
		$Settings/CameraShakeBtn.pressed = true
	else:
		$Settings/CameraShakeBtn.pressed = false

	# instructions setup
	instructions.get_instructions_content(Global.hud.current_highscore, Global.hud.current_highscore_owner)
	instructions.shortcuts.hide()
	instructions.title.modulate = Global.color_red
	instructions.title.text += " ... on pause"


func _process(delta: float) -> void:
	
	# pravilno stanje settingsov
	if Global.sound_manager.game_music_set_to_off:
		$Settings/GameMusicBtn.pressed = false
	else:
		$Settings/GameMusicBtn.pressed = true
	
	if Global.sound_manager.game_sfx_set_to_off:
		$Settings/GameSfxBtn.pressed = false
	else:
		$Settings/GameSfxBtn.pressed = true
	
	if Profiles.camera_shake_on:
		$Settings/CameraShakeBtn.pressed = true
	else:
		$Settings/CameraShakeBtn.pressed = false
		
			
func pause_game():
#	instructions.get_instructions_content(Global.hud.current_highscore, Global.hud.current_highscore_owner)
	
	visible = true
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	# pokažem skip tutorial gumb
	var skip_tut_btn: Button = $Menu/SkipTutBtn
	if Global.tutorial_gui != null and Global.tutorial_gui.tutorial_on:
		skip_tut_btn.show()
	else:
		skip_tut_btn.hide()

	Global.focus_without_sfx($Menu/PlayBtn)
	
	var pause_in_time: float = 0.5
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_in_time)
	fade_in_tween.tween_callback(get_tree(), "set_pause", [true])
	fade_in_tween.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik


func play_on():
	
	Global.allow_focus_sfx = false
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	var pause_out_time: float = 0.5
	var fade_out_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_out_time)
	fade_out_tween.tween_callback(self, "hide")
	fade_out_tween.tween_callback(get_tree(), "set_pause", [false])
	fade_out_tween.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik


func play_without_tutorial():
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	var pause_out_time: float = 0.5
	var fade_out_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_out_time)
	fade_out_tween.tween_callback(self, "hide")
	fade_out_tween.tween_callback(get_tree(), "set_pause", [false])
	fade_out_tween.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik
	fade_out_tween.tween_callback(Global.tutorial_gui, "close_tutorial")
#	Global.tutorial_gui.close_tutorial()


# MENU ---------------------------------------------------------------------------------------------
	

func _on_PlayBtn_pressed() -> void:
	
	play_on()


func _on_RestartBtn_pressed() -> void:

	Global.game_manager.game_on = false
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	Global.game_manager.stop_game_elements()
	Global.sound_manager.stop_music("game_music_on_gameover")
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira
	Global.main_node.reload_game()


func _on_SkipTutBtn_pressed() -> void:
	
	play_without_tutorial()

	
func _on_QuitBtn_pressed() -> void:

	Global.game_manager.game_on = false

	Global.game_manager.stop_game_elements()
	Global.sound_manager.stop_music("game_music_on_gameover")
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira
	Global.main_node.game_out(Global.game_manager.game_data["game"])


# SETTINGS BTNZ ---------------------------------------------------------------------------------------------

	
func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_music("game_music")
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.stop_music("game_music")


func _on_GameMusicSlider_value_changed(value: float) -> void:
	
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Profiles.camera_shake_on = true
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Profiles.camera_shake_on = false
