extends Control


var table_game_data: Dictionary# = {}

var scorelines: Array = []
var empty_scorelines_after_build: Array		
var unpublished_local_scores: Array = [] # za naknadno objavo

var empty_table_text: String = "No score to show ...\nPlay your first game\nor update global scores."
var rank_label_name: String = "Rank"
var owner_label_name: String = "Owner"
var score_label_name: String = "Score"	

onready var hs_table: VBoxContainer = $TableScroller/Table
onready var table_title_label: Label = $Title
onready var table_title_edge: Panel = $Edge
onready var table_scroller: ScrollContainer = $TableScroller
onready var default_scoreline: HBoxContainer = $TableScroller/Table/ScoreLine
onready var table_scroller_default_x = table_scroller.rect_position.x


func build_highscore_table(current_game_data: Dictionary, current_player_rank: int, show_title: bool = true, separate_local_scores: bool = true):
	
	table_game_data = current_game_data.duplicate() # nujno duplikat .. še kje?
	
	reset_table()
	
	# nafilam podatke
	var current_game_highscores = Global.data_manager.read_highscores_from_file(table_game_data)
	
	# spawnam scoreline
	add_scorelines(current_game_highscores.size())
	for scoreline in scorelines:
		fill_scoreline_with_data(scoreline, current_game_highscores)
	
	# zbrišem nenapolnjene scoreline 
	for empty_scoreline in empty_scorelines_after_build:
		scorelines.erase(empty_scoreline)
		empty_scoreline.queue_free()
	empty_scorelines_after_build.clear()
	
	
	# dodam lokalne rezultate
	var offset_current_player_rank: int = add_local_to_global_scores(separate_local_scores, current_player_rank)
	
	# označim current player scoreline
	if current_player_rank > 0:
		current_player_rank = offset_current_player_rank
		var new_player_scoreline_index: int = scorelines.find(current_player_rank)
		scorelines[new_player_scoreline_index - 1].modulate = Global.color_green
				
	# table title
	if show_title:
		table_title_label.text = "Top " + table_game_data["game_name"] + "s"
		if table_game_data["game"] == Profiles.Games.SWEEPER:
			table_title_label.text += " %02d" % table_game_data["level"]
	else:
		table_title_edge.hide()
		table_title_label.hide()
		table_scroller.rect_size.y -= 5 - table_scroller.rect_position.y
		table_scroller.rect_position.y = 5
	
	# default scoreline 
	# first line no score msg
	if scorelines.empty():
		# na vrhu s sporočilom
		default_scoreline.get_node(rank_label_name).text = empty_table_text
		default_scoreline.get_node(score_label_name).hide()
		default_scoreline.get_node(owner_label_name).hide()
		default_scoreline.modulate = Global.color_gui_gray
		default_scoreline.show()
	# last line ... scroller dummy
	else:	
		# na dnu, prazna, da se skrol lepo zaključi 
		default_scoreline.get_node(rank_label_name).hide()
		default_scoreline.get_node(score_label_name).hide()
		default_scoreline.get_node(owner_label_name).hide()
		hs_table.move_child(default_scoreline,hs_table.get_child_count() - 1)
		default_scoreline.show()
	
	var table_scrollbar: VScrollBar = $TableScroller.get_v_scrollbar()
	if not table_scrollbar.modulate.a == 0:
		table_scrollbar.modulate.a = 0
		table_scroller.rect_position.x += 7
	
						 
func add_scorelines(lines_count: int):
	
	if scorelines.size() < lines_count:
		var missing_lines_count: int = lines_count - scorelines.size()
		var scoreline_to_duplicate: Control = hs_table.get_child(0)
		for n in missing_lines_count:
			var new_scoreline = scoreline_to_duplicate.duplicate()
			hs_table.add_child(new_scoreline)
			scorelines.append(new_scoreline)	
	
	
func fill_scoreline_with_data(scoreline: Control, highscores: Dictionary):
	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	var scoreline_index: int = scorelines.find(scoreline)
	var scoreline_position_key: String = "%02d" % (scoreline_index + 1)
	
	# izberem position slovar glede na pozicijo score lineta
	var current_position_dict: Dictionary = highscores[scoreline_position_key]
	var current_position_dict_values: Array = current_position_dict.values()
	var current_position_dict_owners: Array = current_position_dict.keys()
	var current_owner: String = current_position_dict_owners[0]
	
	scoreline.get_node(owner_label_name).text = current_owner
	scoreline.get_node(rank_label_name).text = str(scoreline_index + 1)
	
	var current_position_score: float = current_position_dict_values[0]
	if current_position_score == 0:
		empty_scorelines_after_build.append(scoreline)
	else:
		if table_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			var current_position_seconds: float = current_position_score
			scoreline.get_node(score_label_name).text = Global.get_clock_time(current_position_seconds)
		elif table_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
			var current_position_points: int = current_position_score
			scoreline.get_node(score_label_name).text = str(current_position_points)
		
		scoreline.modulate = Global.color_almost_white_text
		scoreline.show()
		
	
func add_local_to_global_scores(separate_local_scores: bool, current_score_rank: int = 0):
	
	
	var local_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(table_game_data, true)
	var new_scorelines: Array = []
	
	for local_score_data in local_game_highscores:
		
		var local_player_name: String = local_game_highscores[local_score_data].keys()[0]
		var local_player_score: float = local_game_highscores[local_score_data][local_player_name]
		
		if local_player_score == 0: # zazih
			continue
		
		var better_ranked_player_count: int = 0
		for line_with_score in scorelines:
			var global_player_name: String = line_with_score.get_node(owner_label_name).text
			var global_player_score: int = int(line_with_score.get_node(score_label_name).text)
			# če je lokalni skor že na globalni lestvici, ga samo označim obarvam
			if global_player_name == local_player_name and global_player_score == local_player_score:
				if separate_local_scores:
					line_with_score.modulate = Global.color_yellow
				better_ranked_player_count = -1 # predno pride do enakega rezultata, jih je že nekaj preštel
			# če ga še ni ... preverim bolje rangirane (in globalni skor ni 0)
			if not global_player_score == 0:
				if table_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: 
					if global_player_score < local_player_score: # manjši je boljši
						better_ranked_player_count += 1
				elif table_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS: 
					if global_player_score > local_player_score: # večji je boljši
						better_ranked_player_count += 1
		
		# spawn nove scoreline
		if not better_ranked_player_count == -1 :
			# spawn
			var new_local_scoreline: Control = default_scoreline.duplicate()
			hs_table.add_child(new_local_scoreline)
			if separate_local_scores:
				new_local_scoreline.modulate = Global.color_yellow
			new_local_scoreline.show()
			# data
			var local_player_rank: int = better_ranked_player_count # + 1
			new_local_scoreline.get_node(rank_label_name).text = "..."
			new_local_scoreline.get_node(owner_label_name).text = local_player_name
			if table_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: 
				new_local_scoreline.get_node(score_label_name).text = Global.get_clock_time(local_player_score)
			elif table_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
				new_local_scoreline.get_node(score_label_name).text = str(local_player_score)

			hs_table.move_child(new_local_scoreline, local_player_rank + new_scorelines.size())
			new_scorelines.append(new_local_scoreline)
			unpublished_local_scores.append(local_score_data)
			
			# preverim score rank
			if better_ranked_player_count < current_score_rank:
				current_score_rank += 1
			
	scorelines.append_array(new_scorelines)
	
	return current_score_rank
	
	
func publish_unpublished_scores():

	var score_published_count: int = 0
	for score_rank in unpublished_local_scores:
		
		var local_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(table_game_data, true)
		var local_player_name: String = local_game_highscores[score_rank].keys()[0]
		var local_player_score: float = local_game_highscores[score_rank][local_player_name]
		
		var all_scores_size: int = unpublished_local_scores.size()
		score_published_count += 1
		if score_published_count < unpublished_local_scores.size():
			LootLocker.multipublish_scores_to_lootlocker(local_player_name, local_player_score, table_game_data)
			yield(LootLocker, "unpublished_score_published")
		else: # če je zadnji
			LootLocker.multipublish_scores_to_lootlocker(local_player_name, local_player_score, table_game_data, true)
			yield(LootLocker, "unpublished_score_published")
			LootLocker.update_lootlocker_leaderboard(table_game_data, true, "", true)
	unpublished_local_scores.clear()


func reset_table():
	# ohrani samo def_score_line
	
	for label in default_scoreline.get_children():
		label.show()
		
	var highscore_table_children: Array = hs_table.get_children()
	highscore_table_children.erase(default_scoreline)
	
	if not highscore_table_children.empty(): # pomeni, da ni resetirana, ali pa ima debug linije
		for child in highscore_table_children:
			hs_table.remove_child(child) # more bit za pravo zaporedje vrinjenih lokalnih
			child.queue_free()
			
	scorelines.clear()
