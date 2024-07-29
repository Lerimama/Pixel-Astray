extends VBoxContainer


var sweeper_scorelines: Array
var current_sweeper_table_page: int = 1

onready var highscore_table_title: Label = $Title
	

func get_highscore_table(current_game_data: Dictionary, current_player_rank: int, lines_to_show_count: int = 10):
	
	var current_game_hs_type = current_game_data["highscore_type"]
	var current_game_highscores = Global.data_manager.read_highscores_from_file(current_game_data)
	
	# naslov tabele
	var current_game_name: String = current_game_data["game_name"]
	if current_game_data["game"] == Profiles.Games.CLEANER_XS:
		highscore_table_title.text = "Best XS cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_S:
		highscore_table_title.text = "Best S cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_M:
		highscore_table_title.text = "Best M cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_L:
		highscore_table_title.text = "Best L cleaners"
	elif current_game_data["game"] == Profiles.Games.CLEANER_XL:
		highscore_table_title.text = "Best XL cleaners"
	else:
		highscore_table_title.text = "Best " + current_game_name.to_lower() + "s"

	
	# napolnem lestvico
	var scorelines: Array = get_children()
	var scorelines_with_score: Array


	if scorelines.size() < lines_to_show_count:
		var missing_lines_count: int = lines_to_show_count - scorelines.size()
		var scoreline_to_duplicate: Control = scorelines[scorelines.size() - 1] # zadnji def scorline
		for n in missing_lines_count:
			var new_scoreline = scoreline_to_duplicate.duplicate()
			add_child(new_scoreline)
			scorelines.append(new_scoreline)	

	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	for scoreline in scorelines:
		var scoreline_index: int = scorelines.find(scoreline)
		var scoreline_position_key: String = "%02d" % (scoreline_index + 1)
		
		# izberem position slovar glede na pozicijo score lineta
		var current_position_dict: Dictionary = current_game_highscores[scoreline_position_key]
		var current_position_dict_values: Array = current_position_dict.values()
		var current_position_dict_owners: Array = current_position_dict.keys()
		scoreline.get_node("Position").text = str(scoreline_index + 1) + "."
		scoreline.get_node("Owner").text = str(current_position_dict_owners[0])
		
		if current_game_hs_type == Profiles.HighscoreTypes.TIME:# or current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH:
			var current_position_seconds: float = current_position_dict_values[0]
			# skorlinije, ki niso skrite v hometu, se prikažejo
			if current_position_seconds > 0:# and not scoreline_index >= lines_to_show_count: # and scoreline_index > lines_to_show_count:
				scoreline.get_node("NoScoreLine").hide()
				scoreline.get_node("Score").text = Global.get_clock_time(current_position_seconds)
				scorelines_with_score.append(scoreline)
			# skrijem 0 rezultat
			elif current_position_seconds == 0:
				scorelines_with_score.erase(scoreline)
				scoreline.get_node("Position").hide()
				scoreline.get_node("Owner").hide()
				scoreline.get_node("Score").hide()
				scoreline.get_node("NoScoreLine").show()
				
		elif current_game_hs_type == Profiles.HighscoreTypes.POINTS:
			var current_position_points: int = current_position_dict_values[0]
#				if current_position_points > 0 and not scoreline_index >= lines_to_show_count: # bug =
			if current_position_points > 0:
				scoreline.get_node("NoScoreLine").hide()
				scoreline.get_node("Score").text = str(current_position_dict_values[0])
				scorelines_with_score.append(scoreline)
			# skrijem 0 rezultat
			else:
				scorelines_with_score.erase(scoreline)
				scoreline.get_node("Position").hide()
				scoreline.get_node("Owner").hide()
				scoreline.get_node("Score").hide()
				scoreline.get_node("NoScoreLine").show()
				# scoreline.hide()
		
		# pokažem samo lines_to_show_count 		
		if not scoreline_index > lines_to_show_count:
			scoreline.show()
		else:
			scoreline.hide()
				
		# povdarim trenuten rezultat
		if scoreline_index == current_player_rank and not scoreline_index == 0: # 0 je da izločim naslov
			scoreline.modulate = Global.color_green
	
	# če v lestvici ni rezultata, priredim prvo vrstico, če ne jo vrnem v planiran položaj
	if scorelines_with_score.empty():
		scorelines[0].show() # 0 je title
		scorelines[0].get_node("Owner").clip_text = false
		scorelines[0].get_node("Owner").text = "Still no score ..."
		scorelines[0].get_node("Owner").align = Label.ALIGN_CENTER
		scorelines[0].get_node("Owner").modulate = Global.color_almost_white_text
		scorelines[0].get_node("Owner").show()
		scorelines[0].get_node("Position").hide()
		scorelines[0].get_node("Score").hide()
		scorelines[0].get_node("NoScoreLine").hide()
	else: # zazih
		scorelines[0].get_node("Owner").clip_text = true
		scorelines[0].get_node("Owner").align = Label.ALIGN_LEFT
		scorelines[0].get_node("Position").show()
		scorelines[0].get_node("Score").show()
		
			
func get_sweeper_highscore_table(current_game_data: Dictionary, scoreline_level_to_get: int = 0):
	# poberem top score od tabele vsakega sweeper levela
	
	# naslov tabele
	highscore_table_title.text = "Best sweepers"
	
	# scorelines
	var scorelines: Array = get_children()
	
	# če je linij premalo, dodam nove
	if scorelines.size() < Profiles.sweeper_level_tilemap_paths.size():
		var missing_lines_count: int = Profiles.sweeper_level_tilemap_paths.size() - scorelines.size()
		var scoreline_to_duplicate: Control = scorelines[scorelines.size() - 1] # zadnji def scorline
		for n in missing_lines_count:
			var new_scoreline = scoreline_to_duplicate.duplicate()
			add_child(new_scoreline)
			scorelines.append(new_scoreline)
	
	# napolnem lestvico ... za linijo najdem top skor pripadajočega levela
	sweeper_scorelines = scorelines
	for scoreline in scorelines:
			
		# level HS data
		var scoreline_index: int = scorelines.find(scoreline)
		current_game_data["level"] = scoreline_index + 1
		var current_level_highscores = Global.data_manager.read_highscores_from_file(current_game_data)
		
		# level top HS
		var scoreline_position_key: String = "01"
		var current_level_top_score_line: Dictionary = current_level_highscores[scoreline_position_key]
		var current_top_score: float = current_level_top_score_line.values()[0]
		var current_top_score_owner: String = current_level_top_score_line.keys()[0]
	
		# to text
		scoreline.get_node("Score").hide()
		scoreline.get_node("Position").text = "Sweeper %02d: " % current_game_data["level"]
		scoreline.get_node("Owner").clip_text = false
		if current_top_score == 0:
			scoreline.get_node("Owner").hide()
			scoreline.get_node("NoScoreLine").show()
		else:
			
			var record_time_seconds: int = floor(current_top_score)
			var record_hunds: float = floor((current_top_score - record_time_seconds) * 100)
			current_top_score = record_time_seconds + record_hunds / 100
			scoreline.get_node("Owner").text = str(current_top_score) + "s by %s" % current_top_score_owner
	
	load_sweeper_table_page(0)
	
	if scoreline_level_to_get > 0:
		return scorelines[scoreline_level_to_get]


func load_sweeper_table_page(next_or_prev_page: int): # +1 ali -1
		
		var per_page_count: float = 5
		var scorelines_count: int = sweeper_scorelines.size()
	
		var pages_count: float = ceil(scorelines_count / per_page_count)
		current_sweeper_table_page += next_or_prev_page
		if current_sweeper_table_page > pages_count:
			current_sweeper_table_page = 1
		elif current_sweeper_table_page < 1:
			current_sweeper_table_page = pages_count
		
		var first_scoreline_to_show_index = per_page_count * (current_sweeper_table_page - 1)
#		var first_scoreline_to_show_index = 1 + per_page_count * (current_sweeper_table_page - 1)
		var level_to_show_range: Array = [first_scoreline_to_show_index , first_scoreline_to_show_index + per_page_count]
		
		for scoreline in sweeper_scorelines:
			var scoreline_index = sweeper_scorelines.find(scoreline)
			if scoreline_index >= level_to_show_range[0] and scoreline_index < level_to_show_range[1]:
				scoreline.show()
			else:
				scoreline.hide()
				
#		printt ("TS", current_game_data["level"], get_child_count())
		
#		var current_position_seconds: float = current_position_dict_values[0]
#		# skorlinije, ki niso skrite v hometu, se prikažejo
#		if current_position_seconds > 0:# and not scoreline_index >= lines_to_show_count: # and scoreline_index > lines_to_show_count:
#			scoreline.get_node("NoScoreLine").hide()
#			scoreline.get_node("Score").text = Global.get_clock_time(current_position_seconds)
#			scorelines_with_score.append(scoreline)
#		# skrijem 0 rezultat
#		elif current_position_seconds == 0:
#			scorelines_with_score.erase(scoreline)
#			scoreline.get_node("Position").hide()
#			scoreline.get_node("Owner").hide()
#			scoreline.get_node("Score").hide()
#			scoreline.get_node("NoScoreLine").show()
#
#
#		scoreline.show()
#		if not scoreline_index > lines_to_show_count:
#			scoreline.show()
#		else:
#			scoreline.hide()
#
#		# povdarim trenuten rezultat
#		if scoreline_index == current_player_rank and not scoreline_index == 0: # 0 je da izločim naslov
#			scoreline.modulate = Global.color_green
#
#	# če v lestvici ni rezultata
#	if scorelines_with_score.empty():
#		scorelines[1].show() # 0 je title
#		scorelines[1].get_node("Owner").clip_text = false
#		scorelines[1].get_node("Owner").text = "Still no score ..."
#		scorelines[1].get_node("Owner").align = Label.ALIGN_CENTER
#		scorelines[1].get_node("Owner").modulate = Global.color_almost_white_text
#		scorelines[1].get_node("Owner").show()
#		scorelines[1].get_node("Position").hide()
#		scorelines[1].get_node("Score").hide()
#		scorelines[1].get_node("NoScoreLine").hide()
			
