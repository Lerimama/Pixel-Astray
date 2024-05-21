extends VBoxContainer


onready var highscore_table_title: Label = $Title

func get_highscore_table(current_game_data: Dictionary, current_player_ranking: int):
	
	var current_game_hs_type = current_game_data["highscore_type"]
	var current_game_highscores = Global.data_manager.read_highscores_from_file(current_game_data)
	
	# naslov tabele
	var current_game_name: String = current_game_data["game_name"]
	if current_game_data["game"] == Profiles.Games.CLEANER_S:
		highscore_table_title.text = "Top S CLEANERS"
	elif current_game_data["game"] == Profiles.Games.CLEANER_M:
		highscore_table_title.text = "Top M CLEANERS"
	elif current_game_data["game"] == Profiles.Games.CLEANER_L:
		highscore_table_title.text = "Top L CLEANERS"
	elif current_game_data["game"] == Profiles.Games.SWEEPER:
		highscore_table_title.text = "Top " + current_game_name + "s " + "%02d" % current_game_data["level"]

	else:
		highscore_table_title.text = "Top " + current_game_name + "s"
	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	var score_lines: Array = get_children()
	for scoreline in score_lines:
		var scoreline_index: int = score_lines.find(scoreline)
		var scoreline_position_key: String = "%02d" % scoreline_index
		
		if scoreline_index != 0: # glava tabele
			# izberem position slovar glede na pozicijo score lineta
			var current_position_dict: Dictionary = current_game_highscores[scoreline_position_key]
			var current_position_dict_values: Array = current_position_dict.values()
			var current_position_dict_owners: Array = current_position_dict.keys()
			scoreline.get_node("Position").text = str(scoreline_index) + "."
			scoreline.get_node("Owner").text = str(current_position_dict_owners[0])
			
			if current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_LOW or current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH:
#				scoreline.get_node("Score").text = str(current_position_dict_values[0]) + "s"
				scoreline.get_node("Score").text = Global.get_clock_time(float(current_position_dict_values[0]))
				
			elif current_game_hs_type == Profiles.HighscoreTypes.HS_POINTS:
				scoreline.get_node("Score").text = str(current_position_dict_values[0])
		
		# povdarim trenuten rezultat
		if scoreline_index == current_player_ranking and not scoreline_index == 0: # 0 je da izločim naslov
			scoreline.modulate = Global.color_green
			
