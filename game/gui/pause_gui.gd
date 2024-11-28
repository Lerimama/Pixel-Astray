extends Control


onready var instructions: Control = $Instructions
onready var title: Label = $Title


func _unhandled_input(event: InputEvent) -> void:

	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("pause"):
			if not visible:
				Analytics.save_ui_click("PauseEsc")
				pause_game()
			else:
				if $TouchControllerPopup.visible:
					$TouchControllerPopup.hide()
				else:
					Analytics.save_ui_click("PlayEsc")
					_on_PlayBtn_pressed()


func _ready() -> void:

	title.modulate = Global.color_red
	title.text = "%s ... on pause" % Global.game_manager.game_data["game_name"]

	visible = false
	modulate.a = 0

	# menu btn group
	$Menu/PlayBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/RestartBtn.add_to_group(Global.group_menu_confirm_btns)
	$Menu/QuitBtn.add_to_group(Global.group_menu_cancel_btns)

	# in-pause game instructions
	instructions.get_instructions_content(Global.hud.current_highscore, Global.hud.current_highscore_owner)
	instructions.shortcuts.hide()


func pause_game():

	$Settings.update_settings_btns()

	visible = true

	Global.sound_manager.play_gui_sfx("screen_slide")

	Global.grab_focus_nofx($Menu/PlayBtn)

	var pause_in_time: float = 0.5
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_in_time)
	fade_in_tween.tween_callback(get_tree(), "set_pause", [true])


func play_on():

	Global.sound_manager.play_gui_sfx("screen_slide")

	var pause_out_time: float = 0.5
	var fade_out_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_out_time)
	fade_out_tween.tween_callback(self, "hide")
	fade_out_tween.tween_callback(get_tree(), "set_pause", [false])


# MENU ---------------------------------------------------------------------------------------------


func _on_PlayBtn_pressed() -> void:

	play_on()


func _on_RestartBtn_pressed() -> void:

	Global.game_manager.game_on = false

#	Global.sound_manager.play_gui_sfx("btn_confirm")

	Global.game_manager.stop_game_elements()
	Global.sound_manager.stop_music("game_music_on_gameover")
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira

	Analytics.save_game_data([false, Global.game_manager.strays_in_game_count])

	Global.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

	Global.game_manager.game_on = false

	Global.game_manager.stop_game_elements()
	Global.sound_manager.stop_music("game_music_on_gameover")
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira

	Analytics.save_game_data([false, Global.game_manager.strays_in_game_count])

	Global.main_node.game_out(Global.game_manager.game_data["game"])
