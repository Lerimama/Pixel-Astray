extends GameOver

		
func set_gameover_title():
	# namen:  tutorial GO title, vedno razlog CLEANED

	var gameover_title_tutorial: Control = $GameoverTitle/Tutorial
	gameover_title_tutorial.show()
	selected_gameover_title = gameover_title_tutorial
	selected_gameover_jingle = "win_jingle"


func show_gameover_title():
	# namen: preskočim summary in menu takoj (kot duel), odfejdam čekpojnte

	visible = true
	selected_gameover_title.visible = true
	gameover_title_holder.modulate.a = 0
	
	var background_fadein_transparency: float = 0.85 # cca 217
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title_holder, "show")
	fade_in.tween_property(gameover_title_holder, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property(background, "color:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	fade_in.parallel().tween_callback(self, "show_menu")
	
	
func show_menu():
	# namen: drugi teksti v gumbih, Quit btn fokus
	
	gameover_menu.get_node("RestartBtn").text = "LEARN AGAIN"
	gameover_menu.get_node("QuitBtn").text = "PLAY A REAL GAME"
	
	var focus_btn: Button = gameover_menu.get_node("QuitBtn")
	gameover_menu.modulate.a = 0
	gameover_menu.visible = true
		
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(gameover_menu, "show")
	fade_in.tween_property(gameover_menu, "modulate:a", 1, 0.5).from(0.0)
	fade_in.parallel().tween_callback(Global, "grab_focus_no_sfx", [focus_btn])	
