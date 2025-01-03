extends Control



var touch_outline_size_y: float = 376 # ne uspem resizat avtomatično
var def_outline_size_y: float = 336

onready var title: Label = $Title
onready var game_outline: HFlowContainer = $GameOutline


func _unhandled_input(event: InputEvent) -> void:

	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("pause"):
			if not visible:
#				Analytics.save_ui_click("PauseEsc")
				pause_game()
			else:
				if $TouchControllerPopup.visible:
					$TouchControllerPopup.hide()
				else:
#					Analytics.save_ui_click("PlayEsc")
					_on_PlayBtn_pressed()


func _ready() -> void:

	title.text = "%s ... on pause" % Global.game_manager.game_data["game_name"]

	visible = false
	modulate.a = 0

	# menu btn group
	$Menu/RestartBtn.add_to_group(Batnz.group_cancel_btns)
	$Menu/RestartBtn.add_to_group(Batnz.group_critical_btns)
	$Menu/QuitBtn.add_to_group(Batnz.group_cancel_btns)
	$Menu/QuitBtn.add_to_group(Batnz.group_critical_btns)

	# in-pause game instructions
	game_outline.get_instructions_content() # ne prifejda


func pause_game():

	$Settings.update_settings_btns()

	visible = true

	Global.sound_manager.play_gui_sfx("screen_slide")

	$Menu/PlayBtn.grab_focus()
	#	Batnz.grab_focus_nofx($Menu/PlayBtn)

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
	Global.game_manager.stop_game_elements()
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira

#	Analytics.save_selected_game_data([false, Global.game_manager.strays_in_game_count])

	Global.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

	Global.game_manager.game_on = false
	Global.game_manager.stop_game_elements()
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira

#	Analytics.save_selected_game_data([false, Global.game_manager.strays_in_game_count])

	Global.main_node.game_out(Global.game_manager.game_data["game"])
