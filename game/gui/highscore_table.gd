extends VBoxContainer


onready var highscore_table_title: Label = $Title

func get_highscore_table(current_game_data: Dictionary, current_player_rank: int):
	
	var current_game_hs_type = current_game_data["highscore_type"]
	var current_game_highscores = Global.data_manager.read_highscores_from_file(current_game_data)
	
	# naslov tabele
	var current_game_name: String = current_game_data["game_name"]
	if current_game_data["game"] == Profiles.Games.CLEANER_S:
		highscore_table_title.text = "Top S cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_M:
		highscore_table_title.text = "Top M cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_L:
		highscore_table_title.text = "Top L cleaners"
	elif current_game_data["game"] == Profiles.Games.SWEEPER:
		highscore_table_title.text = "Top %02d " % current_game_data["level"] + current_game_name.to_lower() + "s"
	else:
		highscore_table_title.text = "Top " + current_game_name.to_lower() + "s"
	
	
	# napolnem lestvico
	var scorelines: Array = get_children()
	var scorelines_with_score: Array
	
	# setam labele v prvi liniji, ker so skriti ko v letvici ni rezultata
	scorelines[1].get_node("Owner").clip_text = true
	scorelines[1].get_node("Owner").align = Label.ALIGN_LEFT
	scorelines[1].get_node("Position").show()
	scorelines[1].get_node("Score").show()
	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	for scoreline in scorelines:
		var scoreline_index: int = scorelines.find(scoreline)
		var scoreline_position_key: String = "%02d" % scoreline_index
		
		if scoreline_index != 0: # glava tabele
			# izberem position slovar glede na pozicijo score lineta
			var current_position_dict: Dictionary = current_game_highscores[scoreline_position_key]
			var current_position_dict_values: Array = current_position_dict.values()
			var current_position_dict_owners: Array = current_position_dict.keys()
			scoreline.get_node("Position").text = str(scoreline_index) + "."
			scoreline.get_node("Owner").text = str(current_position_dict_owners[0])
			
			if current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_LOW or current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH:
				var current_position_seconds: float = current_position_dict_values[0]
				if current_position_seconds > 0:
					scoreline.get_node("Score").text = Global.get_clock_time(current_position_seconds)
					scorelines_with_score.append(scoreline)
				# skrijem 0 rezultat
				else:
					scorelines_with_score.erase(scoreline)
					scoreline.hide()
			elif current_game_hs_type == Profiles.HighscoreTypes.HS_POINTS:
				var current_position_points: int = current_position_dict_values[0]
				if current_position_points > 0:
					scorelines_with_score.append(scoreline)
					scoreline.get_node("Score").text = str(current_position_dict_values[0])
				# skrijem 0 rezultat
				else:
					scorelines_with_score.erase(scoreline)
					scoreline.hide()
		# povdarim trenuten rezultat
		if scoreline_index == current_player_rank and not scoreline_index == 0: # 0 je da izločim naslov
			scoreline.modulate = Global.color_green
	
	# če v lestvici ni rezultata
	if scorelines_with_score.empty():
		scorelines[1].get_node("Position").hide()
		scorelines[1].get_node("Owner").clip_text = false
		scorelines[1].get_node("Owner").text = "Still no score ..."
		scorelines[1].get_node("Owner").align = Label.ALIGN_CENTER
		scorelines[1].get_node("Score").hide()
		scorelines[1].show()
			
