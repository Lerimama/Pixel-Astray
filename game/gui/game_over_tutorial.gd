extends GameOver

		
func set_game_gameover_title():
	# namen:  tutorial GO title

	var gameover_title_tutorial: Control = $GameoverTitle/Tutorial
	match current_gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			gameover_title_tutorial.get_node("Finished").show()
			selected_gameover_title = gameover_title_tutorial
			selected_gameover_jingle = "win_jingle"
		Global.game_manager.GameoverReason.LIFE:
			gameover_title_tutorial.get_node("NotFinished").show()
			selected_gameover_title = gameover_title_tutorial
			selected_gameover_jingle = "lose_jingle"
	gameover_menu = selected_gameover_title.get_node("Menu")
	focus_btn = gameover_menu.get_node("QuitBtn")


func set_gameover_summary():
	# namen: ni sumarija, samo meni, ki ima prikazane posebne gumbe

	# vidnost gumbov v meniju glede na igro
	gameover_menu.get_node("NextLevelBtn").hide()
	gameover_menu.get_node("RestartBtn").hide()
	gameover_menu.get_node("RematchBtn").hide()
	gameover_menu.get_node("$Menu/LearnBtn").show()
	gameover_menu.get_node("$Menu/RealGameBtn").show()
			
	get_tree().set_pause(true) # setano čez celotno GO proceduro
	
	gameover_menu.visible = false
	gameover_menu.modulate.a = 0
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(gameover_menu, "show")#.set_delay(1)
	fade_in.tween_property(gameover_menu, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global, "grab_focus_no_sfx", [focus_btn])		

	
func _on_RealGameBtn_pressed() -> void:
	
	Global.main_node.game_out(Global.game_manager.game_data["game"])


func _on_LearnBtn_pressed() -> void:
	
	Global.main_node.reload_game()
