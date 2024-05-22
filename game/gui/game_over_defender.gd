extends GameOver


func show_game_summary():
	# namen: druga statistika game summarya
	
	focus_btn = gameover_menu.get_node("RestartBtn")

	# get stats
	gameover_stats_title.text = str(Global.game_manager.game_data["game_name"]) + " stats"
	gameover_stat_game.text %= str(Global.game_manager.game_data["game_name"])
	if not Global.game_manager.game_data.has("level"):
		gameover_stat_level.hide()
	else:
		gameover_stat_level.text %= str(Global.game_manager.game_data["level"])
	gameover_stat_points.text %= str(p1_final_stats["player_points"])
	gameover_stat_time.text %= str(Global.hud.game_timer.absolute_game_time)
	gameover_stat_cells_traveled.text %= str(p1_final_stats["cells_traveled"])
	gameover_stat_burst_count.text %= str(p1_final_stats["burst_count"])
	gameover_stat_pixels_off.text %= str(p1_final_stats["colors_collected"])
	gameover_stat_skills_used.text %= str(p1_final_stats["skill_count"])
	gameover_stat_astray_pixels.text %= str(Global.game_manager.strays_in_game_count)
	
	game_summary.visible = true	
	game_summary.modulate.a = 0

	# hide title and name_popup > show game summary
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "color:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "hide")
	cross_fade.parallel().tween_callback(gameover_title_holder, "hide")
	cross_fade.parallel().tween_property(game_summary, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.tween_callback(Global, "grab_focus_no_sfx", [focus_btn])

		
func set_game_gameover_title():
		
	match current_gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			pass # ni GO ampak level up
		Global.game_manager.GameoverReason.LIFE:
			selected_gameover_title = gameover_title_life
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
		Global.game_manager.GameoverReason.TIME:
			selected_gameover_title = gameover_title_time
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
	if score_is_ranking:
		selected_gameover_title.modulate = Global.color_green	
