extends Control


var pause_fade_time: float = 0.5
var pause_on: bool = false # samo za esc


func _input(event: InputEvent) -> void:
	
	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("ui_cancel"):
			if not pause_on:
				pause_game()
			else:
				play_on()
	
	# change focus sounds
	if pause_on:
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


func _ready() -> void:
	
	visible = false
	modulate.a = 0
	
	# apdejt glasnosti na slajderju
	$Settings/GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic"))


func _process(delta: float) -> void:
	
	# pravilno stanje settingsov
	if Global.sound_manager.game_music_set_to_off:
		$Settings/GameMusicCheckBox.pressed = false
	else:
		$Settings/GameMusicCheckBox.pressed = true
	if Global.sound_manager.game_sfx_set_to_off:
		$Settings/GameSfxCheckBox.pressed = false
	else:
		$Settings/GameSfxCheckBox.pressed = true
	if Global.main_node.camera_shake_on:
		$Settings/CamerShakeCheckBox.pressed = true
	else:
		$Settings/CamerShakeCheckBox.pressed = false
		
			
func pause_game():
	
	visible = true
	set_process_input(false)
	pause_on = true
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$Menu/PlayBtn.grab_focus()
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")


func play_on():
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS) # da ga pausa ne ustavi
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_fade_time)
	fade_out_tween.tween_callback(self, "set_visible", [false])
	fade_out_tween.tween_callback(self, "unpause_tree")


func pause_tree():
	
	get_tree().paused = true
	set_process_input(true) # zato da se lahko animacija izvede
		
	
func unpause_tree():
	
	get_tree().paused = false
	pause_on = false
	set_process_input(true)
	
	
# MENU ---------------------------------------------------------------------------------------------
	

func _on_PlayBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	pause_on = false
	play_on()


func _on_RestartBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	pause_on = false
	unpause_tree()
	
	Global.main_node.reload_game()
	
	$Menu/RestartBtn.disabled = true # da ne moreš multiklikat
	
	
func _on_QuitBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	pause_on = false
	unpause_tree()
	Global.main_node.game_out()
	
	$Menu/QuitBtn.disabled = true # da ne moreš multiklikat


# SETTINGS BTNZ ---------------------------------------------------------------------------------------------

	
func _on_GameMusicCheckBox_toggled(button_pressed: bool) -> void:

	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_music("game")
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.stop_music("game")


func _on_GameMusicSlider_value_changed(value: float) -> void:
	
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxCheckBox_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CamerShakeCheckBox_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		Global.main_node.camera_shake_on = true
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")
		Global.main_node.camera_shake_on = false



