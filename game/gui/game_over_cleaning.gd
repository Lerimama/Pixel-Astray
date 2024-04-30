extends GameOver


onready var timeup_label: Label = $GameoverTitle/ReasonTime/TimeupLabel
onready var enigma_game_summary: Control = $EnigmaGameSummary
onready var enigma_highscore_table: VBoxContainer = $EnigmaGameSummary/HighscoreTable

var enigma_solved: bool = false				
				
func _ready() -> void:
	# namen: dodan enigam game summary
	
	Global.gameover_menu = self
	
	visible = false
	gameover_title_holder.visible = false
	game_summary_holder.visible = false
	name_input_popup.visible = false
	enigma_game_summary.visible = false
	

func set_game_gameover_title():
	# namen: sprememba teksta v GO - TIME komentarju glede na to katera igra je
	# namen: opredelim, če je bila enigma rešena
	
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
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
		selected_gameover_menu = selected_gameover_title.get_node("Menu")
		focus_btn = selected_gameover_menu.get_node("QuitBtn")
	elif Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
		match current_gameover_reason:
			Global.game_manager.GameoverReason.CLEANED:
				selected_gameover_title = gameover_title_cleaned
				selected_gameover_jingle = "win_jingle"
				name_input_label.text = "Great work!"
				# write enigma to solved enigmas
				Global.data_manager.write_solved_status_to_file(Global.game_manager.game_data)
			Global.game_manager.GameoverReason.LIFE:
				selected_gameover_title = gameover_title_life
				selected_gameover_jingle = "lose_jingle"
				name_input_label.text = "A bit clumsy, aren't yout?"
			Global.game_manager.GameoverReason.TIME:
				timeup_label.text = "That's not all folks!"
				selected_gameover_title = gameover_title_time
				selected_gameover_jingle = "lose_jingle"
	elif Global.game_manager.game_settings["eternal_mode"]:
		match current_gameover_reason:
			#			Global.game_manager.GameoverReason.CLEANED:
			#				selected_gameover_title = gameover_title_cleaned
			#				selected_gameover_jingle = "win_jingle"
			#				name_input_label.text = "Great work!"
			Global.game_manager.GameoverReason.LIFE:
				selected_gameover_title = gameover_title_life
				selected_gameover_jingle = "lose_jingle"
				name_input_label.text = "But still ... "
			Global.game_manager.GameoverReason.TIME:
				timeup_label.text = "Too colorful?"
				selected_gameover_title = gameover_title_time
				selected_gameover_jingle = "lose_jingle"
				name_input_label.text = "But still ... "
		if score_is_ranking:
			selected_gameover_title.modulate = Global.color_green
	else: # orig
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


func show_gameover_menu():
	# namen: enigma HS table, izločim beleženje HS, če ENIGMA ni končana,
	
	get_tree().set_pause(true) # setano čez celotno GO proceduro
	
	if players_in_game.size() == 2:
		selected_gameover_menu.visible = false
		selected_gameover_menu.modulate.a = 0
		var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		fade_in.tween_callback(selected_gameover_menu, "show")#.set_delay(1)
		fade_in.tween_property(selected_gameover_menu, "modulate:a", 1, 1)
		fade_in.parallel().tween_callback(Global, "grab_focus_no_sfx", [focus_btn])		
	else:	
		
		var current_highscore_type: int = Global.game_manager.game_data["highscore_type"]
		var current_player_ranking: int
		
		if current_highscore_type == Profiles.HighscoreTypes.NO_HS:
			selected_game_summary = game_summary_no_hs
			yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
			show_game_summary()
		else:
			var current_score_points: int = p1_final_stats["player_points"]
			
			var current_score_time: float = Global.hud.game_timer.absolute_game_time
			
			# yield čaka na konec preverke ... tip ni opredeljen, ker je ranking, če ni skora kot objecta, če je ranking
			var score_is_ranking = Global.data_manager.manage_gameover_highscores(current_score_points, current_score_time, Global.game_manager.game_data) 
			
			# če je enigma score štejem samo, če vse spuca
			if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA and not current_gameover_reason == Global.game_manager.GameoverReason.CLEANED: 
				yield(get_tree().create_timer(1), "timeout")
				current_player_ranking = 100 # zazih ni na lestvici
			else:
				if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
					open_name_input()
					yield(Global.data_manager, "highscores_updated")
					get_viewport().set_disable_input(false) # anti dablklik
					current_player_ranking = Global.data_manager.current_player_ranking
			
			if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
				enigma_highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_ranking)
			else:
				highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_ranking)
			selected_game_summary = game_summary_with_hs
			show_game_summary()


func show_game_summary():
	# namen: izbira enigma game summary
	
	var game_summary_to_show: Control
	
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
		# focus btn
		if current_gameover_reason == Global.game_manager.GameoverReason.CLEANED:
			print("SUCC")
			focus_btn = enigma_game_summary.get_node("Menu/NextLevelBtn")
		else:
			print("false")
			focus_btn = enigma_game_summary.get_node("Menu/RestartBtn")
			
		enigma_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
		enigma_game_summary.get_node("DataContainer/Level").text %= "%02d" % Global.game_manager.game_data["level"]
		enigma_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
		enigma_game_summary.visible = true	
		enigma_game_summary.modulate.a = 0	
		game_summary_to_show = enigma_game_summary
	else:
		focus_btn = selected_game_summary.get_node("Menu/RestartBtn")
		selected_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
		if not Global.game_manager.game_data.has("level"):
			selected_game_summary.get_node("DataContainer/Level").hide()
		else:
			selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.game_data["level"])
		selected_game_summary.get_node("DataContainer/Points").text %= str(p1_final_stats["player_points"])
		selected_game_summary.get_node("DataContainer/Time").text %= str(Global.hud.game_timer.absolute_game_time)
		selected_game_summary.get_node("DataContainer/CellsTraveled").text %= str(p1_final_stats["cells_traveled"])
		selected_game_summary.get_node("DataContainer/BurstCount").text %= str(p1_final_stats["burst_count"])
		selected_game_summary.get_node("DataContainer/SkillsUsed").text %= str(p1_final_stats["skill_count"])
		selected_game_summary.get_node("DataContainer/PixelsOff").text %= str(p1_final_stats["colors_collected"])
		selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
		selected_game_summary.visible = true	
		game_summary_holder.visible = true	
		game_summary_holder.modulate.a = 0	
		game_summary_to_show = game_summary_holder

	# hide title and name_popup > show game summary
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "color:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "hide")
	cross_fade.parallel().tween_callback(gameover_title_holder, "hide")
	cross_fade.parallel().tween_property(game_summary_to_show, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.tween_callback(Global, "grab_focus_no_sfx", [focus_btn])


func _on_ExitGameBtn_pressed() -> void:
	get_tree().quit()


func _on_NextLevelBtn_pressed() -> void:
	
	var next_level_number: int = Global.game_manager.game_data["level"] + 1
	Profiles.game_data_enigma["level"] = next_level_number
	Global.main_node.reload_game()
