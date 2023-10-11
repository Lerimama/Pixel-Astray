extends VBoxContainer

	
func get_highscore_table(current_level, current_player_ranking):
	
	# malo spremenjeno, ko sem dal lestvico v meni ... če bodo level bo treba malce drugače 
	# var current_level_highscores = Global.data_manager.read_highscores_from_file(Global.game_manager.game_stats["level"])
#	var current_level_highscores = Global.data_manager.read_highscores_from_file(Profiles.default_level_stats["level"])
	var current_level_highscores = Global.data_manager.read_highscores_from_file(current_level)
	
	var score_lines: Array = get_children()
	
	# za vsako pozicijo vpišemo vrenodst, ime in pozicijo
	for scoreline in score_lines:
		var scoreline_index: int = score_lines.find(scoreline)
		var scoreline_position_key: String = str(scoreline_index)
		
		if scoreline_index != 0: # glava tabele
			# izberem position slovar glede na pozicijo score lineta
			var current_position_dict: Dictionary = current_level_highscores[scoreline_position_key]
			var current_position_dict_values: Array = current_position_dict.values()
			var current_position_dict_owners: Array = current_position_dict.keys()
			scoreline.get_node("Position").text = str(scoreline_index) + "."
			scoreline.get_node("Score").text = str(current_position_dict_values[0])
			scoreline.get_node("Owner").text = str(current_position_dict_owners[0])
		
		# povdarim tvoj rezultat
		if scoreline_index == current_player_ranking:
			scoreline.modulate = Global.color_green
			
