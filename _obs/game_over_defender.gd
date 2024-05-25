extends GameOver
		
		
#func set_gameover_title():
#
#	match current_gameover_reason:
#		Global.game_manager.GameoverReason.CLEANED:
#			pass # ni GO ampak level up
#		Global.game_manager.GameoverReason.LIFE:
#			selected_gameover_title = gameover_title_life
#			selected_gameover_jingle = "lose_jingle"
#			name_input_label.text = "But still ... "
#		Global.game_manager.GameoverReason.TIME:
#			selected_gameover_title = gameover_title_time
#			selected_gameover_jingle = "lose_jingle"
#			name_input_label.text = "But still ... "
#	if score_is_ranking:
#		selected_gameover_title.modulate = Global.color_green	
		
		
#func set_game_summary():
#	# namen: druga statistika
#
#	get_tree().set_pause(true) # setano čez celotno GO proceduro
#
#	# setam naslov statistike statistiko
#	gameover_stats_title.text = str(Global.game_manager.game_data["game_name"]) + " stats"
#
#	# napolnim statistiko
#	gameover_stat_game.text %= str(Global.game_manager.game_data["game_name"])
#	if not Global.game_manager.game_data.has("level"):
#		gameover_stat_level.hide()
#	else:
#		gameover_stat_level.text %= str(Global.game_manager.game_data["level"])
#	gameover_stat_points.text %= str(p1_final_stats["player_points"])
#	gameover_stat_time.text %= str(Global.hud.game_timer.absolute_game_time)
#	gameover_stat_cells_traveled.text %= str(p1_final_stats["cells_traveled"])
#	gameover_stat_burst_count.text %= str(p1_final_stats["burst_count"])
#	gameover_stat_pixels_off.text %= str(p1_final_stats["colors_collected"])
#	gameover_stat_skills_used.text %= str(p1_final_stats["skill_count"])
#	gameover_stat_astray_pixels.text %= str(Global.game_manager.strays_in_game_count)
#
#	var current_player_ranking: int
#	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
#		yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
#		show_game_summary()
#	else:
#		if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
#			open_name_input()
#			yield(Global.data_manager, "highscores_updated")
#			get_viewport().set_disable_input(false) # anti dablklik
#			current_player_ranking = Global.data_manager.current_player_ranking
#
#		highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_ranking)
#		show_game_summary() # meni pokažem v tej funkciji
