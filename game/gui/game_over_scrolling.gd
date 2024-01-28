extends GameOver


func show_game_summary():
	
	focus_btn = selected_game_summary.get_node("Menu/RestartBtn")

	# get stats
	selected_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
	selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.game_data["level"])
	selected_game_summary.get_node("DataContainer/Points").text %= str(p1_final_stats["player_points"])
	selected_game_summary.get_node("DataContainer/Time").text %= str(Global.hud.game_timer.time_since_start)
	selected_game_summary.get_node("DataContainer/CellsTraveled").text %= str(p1_final_stats["cells_traveled"])
	selected_game_summary.get_node("DataContainer/BurstCount").text %= str(p1_final_stats["burst_count"])
	selected_game_summary.get_node("DataContainer/SkillsUsed").text %= str(p1_final_stats["skill_count"])
	selected_game_summary.get_node("DataContainer/PixelsOff").text %= str(p1_final_stats["colors_collected"])
	selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
	
	selected_game_summary.visible = true	
	game_summary_holder.visible = true	
	game_summary_holder.modulate.a = 0	

	# hide title and name_popup > show game summary
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "color:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "hide")
	cross_fade.parallel().tween_callback(gameover_title_holder, "hide")
	cross_fade.parallel().tween_property(game_summary_holder, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.tween_callback(Global, "grab_focus_no_sfx", [focus_btn])


# TITLES --------------------------------------------------------------	

		
func set_duel_gameover_title():
	
	selected_gameover_title = gameover_title_duel
	selected_gameover_menu = selected_gameover_title.get_node("Menu")
	focus_btn = selected_gameover_menu.get_node("RestartBtn")
	selected_gameover_jingle = "win_jingle"

	var winner_label: Label = selected_gameover_title.get_node("Win/PlayerLabel")
	var winning_reason_label: Label = selected_gameover_title.get_node("Win/ReasonLabel")
	var loser_name: String
	var draw_label: Label = selected_gameover_title.get_node("Draw/DrawLabel")
	
	# če je kdo brez lajfa, zmaga preživeli
	if p1_final_stats["player_life"] == 0 and p2_final_stats["player_life"] > 0: # P1 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 1"
		loser_name = "Player 2"
		winning_reason_label.text = "Player1 cleaned Player2"
		return
	elif p2_final_stats["player_life"] == 0 and p1_final_stats["player_life"] > 0: # P2 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 2"
		loser_name = "Player 1"
		winning_reason_label.text = "Player2 cleaned Player1"
		return
	 
	# če sta oba preživela ali oba umrla
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	if points_difference == 0: # draw
		selected_gameover_title.get_node("Draw").visible = true
		draw_label.text = "You both collected the 0 of points."
	else: # win
		selected_gameover_title.get_node("Win").visible = true
		if points_difference > 0: # P1 zmaga
			winner_label.text = "Player 1"
			loser_name = "Player 2"
		elif points_difference < 0: # P2 zmaga
			winner_label.text = "Player 2"
			loser_name = "Player 1"
		if abs(points_difference) == 1:
			winning_reason_label.text = "Winner did ... well"
		else: 
			winning_reason_label.text =  winner_label.text + " was " + str(abs(points_difference)) + " points better than " + loser_name + ""# + " points."
		
			
func set_game_gameover_title():
	
	match current_gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_gameover_title = gameover_title_cleaned
			selected_gameover_jingle = "win_jingle"
			name_input_label.text = "Great work!"
		Global.game_manager.GameoverReason.LIFE:
			selected_gameover_title = gameover_title_life
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
		Global.game_manager.GameoverReason.TIME:
			selected_gameover_title = gameover_title_time
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
