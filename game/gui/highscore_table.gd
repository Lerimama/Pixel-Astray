extends VBoxContainer


var sweeper_scorelines: Array
var current_sweeper_table_page: int = 1
var scorelines: Array = []
var scorelines_with_score: Array # array nodetov

onready var hs_table: VBoxContainer = $TableScroller/Table
onready var table_title_label: Label = $Title
onready var table_title_edge: Panel = $Edge

onready var alt_rank_node_name: String = "AltRank"
onready var rank_label_path: String = "Rank"

onready var owner_node_name: String = "Owner"
onready var score_node_name: String = "Score"
onready var scoreline_empty_line_name: String = "NoScoreLine"

var scrollbar_visible: bool = false


func load_highscore_table(current_game_data: Dictionary, current_player_rank: int, lines_to_load_count, global_highscores: bool = false, show_title: bool = true):
	
	reset_table()
	
	# title
	table_title_label.text = "Top " + current_game_data["game_name"] + "s"
	if current_game_data["game"] == Profiles.Games.SWEEPER:
		table_title_label.text += " %02d" % current_game_data["level"]
	
	# naložim globalne z diska
	var current_game_highscores = Global.data_manager.read_highscores_from_file(current_game_data, global_highscores)
	
	# zgradim tabelo
	build_table(lines_to_load_count)
		
	for unfilled_scoreline in scorelines: # scrolline so postavljene in ne nafilane
		fill_scoreline_with_data(unfilled_scoreline, current_game_data, lines_to_load_count, current_game_highscores)

	# označim trenutnega plejerja (game over)
	if current_player_rank > 0 and current_player_rank <= lines_to_load_count:
		var players_scoreline: Control = scorelines[current_player_rank - 1]
		players_scoreline.modulate = Global.color_green
	
	# scrollbar spacing od tabele (če je naslov večji od tabele poravnava se s širino parenta)
	var scrollbar_margin: float = -40
	$TableScroller.rect_min_size.x = hs_table.rect_size.x + scrollbar_margin
#	var tables_scrollbar: ScrollBar = $TableScroller.get_v_scrollbar()
#	tables_scrollbar.self_modulate.a = 1

#	$TableScroller.rect_min_size.x = hs_table.rect_size.x + 32
#	$TableScroller.get_v_scrollbar().self_modulate.a = 0.25
	$TableScroller.get_v_scrollbar().visible = false
#	$TableScroller.get_v_scrollbar().margin_left = -4
	print($TableScroller.get_v_scrollbar().margin_left)
	$TableScroller.get_v_scrollbar().set("margin_left", -4)
	print($TableScroller.get_v_scrollbar().margin_left)
	add_local_to_global(current_game_data)
	
	if not show_title:
		table_title_edge.hide()
		table_title_label.hide()
	
	
func build_table(lines_count: int):
	
	scorelines = hs_table.get_children()

	
	var scoreline_titles_line: Control = scorelines.pop_front()
	scoreline_titles_line.modulate = Global.color_gui_gray
	
	# podupliciram osnovno linijo 
	if scorelines.size() < lines_count:
		var missing_lines_count: int = lines_count - scorelines.size()
		var scoreline_to_duplicate: Control = hs_table.get_child(0)
		for n in missing_lines_count:
			var new_scoreline = scoreline_to_duplicate.duplicate()
			hs_table.add_child(new_scoreline)
			scorelines.append(new_scoreline)	
	
	
				
func fill_scoreline_with_data(scoreline: Control, game_data: Dictionary, lines_count: int, highscores: Dictionary):
	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	var scoreline_index: int = scorelines.find(scoreline)
	var scoreline_position_key: String = "%02d" % (scoreline_index + 1)
	
	# izberem position slovar glede na pozicijo score lineta
	var current_position_dict: Dictionary = highscores[scoreline_position_key]
	var current_position_dict_values: Array = current_position_dict.values()
	var current_position_dict_owners: Array = current_position_dict.keys()
	var current_owner: String = current_position_dict_owners[0]
	
	scoreline.get_node(owner_node_name).text = current_owner
	scoreline.get_node(rank_label_path).text = str(scoreline_index + 1)
	
	var current_position_score: float = current_position_dict_values[0]
	# z rezultatom
	if current_position_score > 0:
		if game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			var current_position_seconds: float = current_position_score
			scoreline.get_node(score_node_name).text = Global.get_clock_time(current_position_seconds)
		elif game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
			var current_position_points: int = current_position_score
			scoreline.get_node(score_node_name).text = str(current_position_points)
		scorelines_with_score.append(scoreline)
		scoreline.modulate = Global.color_almost_white_text
	# brez rezultata
	else:
		add_scoreless_scoreline(scoreline)
	
	# omejitev števila vidnega v tabeli ... pokažem samo lines_to_load_count 		
	if not scoreline_index > lines_count:
		scoreline.show()
	else:
		scoreline.hide()

	
func add_local_to_global(game_data: Dictionary):#, global_game_data: Dictionary):
	# pokaže global rank
	# lokalne obarva
	# če lokalni rezultat nima global rank so "..."
	# namesto ... ima gumb možnost pušanja rezultata
	# nerangirani lokalci so po vrsti in imitiran rezultat 1000 + xx
	
		
	var global_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(game_data, true)
	var local_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(game_data)
	
	# za vsak lokalni skor, ki ni rangiran preverim kateri skor je pred njim
	var new_scoreline_count: int = 0
	for local_scoreline in local_game_highscores:
		
		var local_player_name: String = local_game_highscores[local_scoreline].keys()[0]
		var local_player_score: float = local_game_highscores[local_scoreline][local_player_name]
		
		if local_player_score <= 0: # zazih
			pass
#			print ("merge loc and glo ... lokal skor je 0, preskočim")
		else:	
			
			var better_ranked_player_count: int = 0
			for line_with_score in scorelines_with_score:
#			for global_scoreline in global_game_highscores:
#				var global_player_name: String = global_game_highscores[global_scoreline].keys()[0]
#				var global_player_score: float = global_game_highscores[global_scoreline][global_player_name]
				var global_player_name: String = line_with_score.get_node(owner_node_name).text
				var global_player_score: int = int(line_with_score.get_node(score_node_name).text)
				
				# če je ža na global lestvici neham
				if global_player_name == local_player_name and global_player_score == local_player_score:
					line_with_score.modulate = Global.color_blue		
					better_ranked_player_count = 0
				# naberem bolje rangirane	
				elif game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: 
					if global_player_score < local_player_score: # manjši je boljši
						better_ranked_player_count += 1
				elif game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS: 
					if global_player_score > local_player_score: # večji je boljši
						better_ranked_player_count += 1
			
			printt ("____RANKS", better_ranked_player_count)
			if not better_ranked_player_count == 0:
				var local_player_rank: int = better_ranked_player_count + 1
					
				# naredim linijo ... dupliciram prvo že narejeno in jo napolnim
				var new_local_scoreline: Control = scorelines_with_score[0].duplicate()
	#					var new_local_scoreline: Control = hs_table.get_children()[0].duplicate()
				hs_table.add_child(new_local_scoreline)
				
				# napolnem podatke
				new_local_scoreline.get_node(rank_label_path).text = "-" #%d" % local_player_rank
				new_local_scoreline.get_node(owner_node_name).text = local_player_name
				new_local_scoreline.get_node(score_node_name).text = str(local_player_score)
				new_local_scoreline.modulate = Global.color_green		

				# premaknem
				hs_table.move_child(new_local_scoreline, local_player_rank + new_scoreline_count)
				new_scoreline_count += 1 	


# tabela z GR in LR
# prebere data iz diska, zato morajo biti lokalni in globalni prej zgrajeni	
func load_local_to_global_ranks(local_game_data: Dictionary):#, global_game_data: Dictionary):
	# pokaže global rank
	# lokalne obarva
	# če lokalni rezultat nima global rank so "..."
	# namesto ... ima gumb možnost pušanja rezultata
	# nerangirani lokalci so po vrsti in imitiran rezultat 1000 + xx
		
	var global_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(local_game_data, true)
	var local_game_highscores: Dictionary = Global.data_manager.read_highscores_from_file(local_game_data)
	var scorelines_with_global_rank: Array = [] # za označit ne povezane
	
	# za vsak global score večji > 0 preverim vse lokalne scoreline
	for global_highscore_line in global_game_highscores:
		
		var global_highscore_player_name: String = global_game_highscores[global_highscore_line].keys()[0]
		var global_highscore_player_score: float = global_game_highscores[global_highscore_line][global_highscore_player_name]
		var global_highscore_player_rank: int = int(global_highscore_line)
		
		if global_highscore_player_score > 0:
		
			for key in local_game_highscores:
				var highscore_line_dict: Dictionary = local_game_highscores[key] #"%02d" % (scorelines_with_score.find(highscore_line) + 1)
				var line_key_as_name: String = highscore_line_dict.keys()[0]
				var line_score: int = highscore_line_dict[line_key_as_name]
				# preverim enakost imena in skora
				if global_highscore_player_name == line_key_as_name and global_highscore_player_score == line_score:
					var current_hs_scoreline: Control = scorelines[int(key) - 1]
					current_hs_scoreline.get_node(rank_label_path).text = str(global_highscore_player_rank)
					scorelines_with_global_rank.append(current_hs_scoreline)
					break
					
			# če ni global skora
			for scoreline in scorelines_with_score:
				if not scorelines_with_global_rank.has(scoreline):
					scoreline.get_node(rank_label_path).text = "..."	
	



func add_scoreless_scoreline(empty_scoreline: Control):
	
	empty_scoreline.get_node(rank_label_path).text = "_________________________"
	empty_scoreline.get_node(rank_label_path).visible_characters = 25
	empty_scoreline.get_node(owner_node_name).hide()
	empty_scoreline.get_node(score_node_name).hide()
#	empty_scoreline.get_node(rank_label_path).text = "__"
#	empty_scoreline.get_node(owner_node_name).text = "__________"
#	empty_scoreline.get_node(score_node_name).text = "_________"
	empty_scoreline.modulate = Global.color_gui_gray	
	empty_scoreline.modulate.a = 0.1

	
func reset_table():
	
	var highscore_table_children: Array = hs_table.get_children()
	if highscore_table_children.size() > 1: # pomeni, da ni resetirana, ali pa ima debug linije
		for child in highscore_table_children:
			if not child == highscore_table_children[0]:
				hs_table.remove_child(child)
	scorelines.clear()
	scorelines_with_score.clear()	
