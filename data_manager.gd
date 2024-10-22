extends Node


signal scores_saved

var data_file: = File.new()
var current_player_rank: int


func _ready() -> void:
	
	Global.data_manager = self

	
func get_top_highscore(current_game_data: Dictionary):
	
	# load highscore
	var loaded_game_highscores = read_highscores_from_file(current_game_data) # ... v odprtem filetu se potem naloži highscore
	
	# current higscore in lastnik
	var all_scores: Array = []
	var all_score_owners: Array = []
	
	for hs_position_key in loaded_game_highscores:
		# dodam vrednost s pozicijo
		var current_position_dict = loaded_game_highscores[hs_position_key]
		all_scores += current_position_dict.values()
		all_score_owners += current_position_dict.keys()
		
	# setam top score glede na tip HSja
	var current_highscore: float
	match current_game_data["highscore_type"]:
		Profiles.HighscoreTypes.POINTS:
			# izberem najvišjega
			current_highscore = all_scores.max()
		Profiles.HighscoreTypes.TIME:
			# naberem vse rezultate, ki niso 0 in izberem minimalnega
			var valid_scores: Array
			for score in all_scores:
				if score > 0:
					valid_scores.append(score)
			if valid_scores.empty(): # prevent error, kadar so same 0
				current_highscore = 0
			else:
				current_highscore = valid_scores.min()

	var current_highscore_index: int = all_scores.find(current_highscore)
	var current_highscore_owner: String = all_score_owners[current_highscore_index]
	
	# za GM hud
	return [current_highscore, current_highscore_owner]


func check_player_ranking(current_score: float, current_game_data: Dictionary):

	# vsakič, ko preverjam, resetiram
	current_player_rank = 0
	
	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	var current_game_highscores: Dictionary = read_highscores_from_file(current_game_data) # ... v odprtem filetu se potem naloži highscore
	# current_score_time je že zaokrožen na 2 decimalki
	
	# poberemo lestvico v arraye
	for hs_position_key in current_game_highscores:
		var current_position_dict = current_game_highscores[hs_position_key]
		all_ranking_scores += current_position_dict.values()
		all_ranking_score_owners += current_position_dict.keys()

	# izračun uvrstitve na lestvico ... preštejem pozicije pred plejerjem 
	var better_positions_count: int = 0
	for ranking_score in all_ranking_scores:
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: # edinkrat ko se šteje nižje število
			if ranking_score <= current_score and not ranking_score <= 0:
				better_positions_count += 1				
		else:
			if ranking_score >= current_score:
				better_positions_count += 1
	
	current_player_rank = better_positions_count + 1 # za označitev linije na lestvici
	
	if better_positions_count >= all_ranking_scores.size():
		current_player_rank = 0
	
	return current_player_rank

	
# READ & WRITE ------------------------------------------------------------------------------------------------------------------------ 	


func write_highscores_to_file(write_game_data: Dictionary, new_game_highscores: Dictionary, global_highscores: bool = false):

	# get hs name
	var write_game_name: String
	if write_game_data["game"] == Profiles.Games.SWEEPER:
		write_game_name = Profiles.Games.keys()[write_game_data["game"]] + "_" + str(write_game_data["level"])
	else:
		write_game_name = Profiles.Games.keys()[write_game_data["game"]]
	
	# če je global HS
	if global_highscores:
		write_game_name += "_Global"
	
	# podam novi HS v json obliko
	var json_string = JSON.print(new_game_highscores)
	
	# če fileta ni, ga funkcija ustvari iz File.new()
	data_file.open("user://%s_highscores.save" % write_game_name, File.WRITE) # vsak game ma svoj filet
	
	# vnesem novi HS
	data_file.store_line(to_json(new_game_highscores))
	data_file.close()

		
func read_highscores_from_file(read_game_data: Dictionary, global_highscores: bool = false):

	var read_game_name: String
	var lines_to_read_count: int
	
	if read_game_data["game"] == Profiles.Games.SWEEPER: # OPT preveč vrstic
		if global_highscores:
			lines_to_read_count = Profiles.global_highscores_count
			read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_" + str(read_game_data["level"]) + "_Global"
		else:
			read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_" + str(read_game_data["level"])
			lines_to_read_count = Profiles.local_highscores_count
	else:
		if global_highscores:
			lines_to_read_count = Profiles.global_highscores_count
			read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_Global"
		else:
			read_game_name = Profiles.Games.keys()[read_game_data["game"]]
			lines_to_read_count = Profiles.local_highscores_count
		
	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
	if error != OK: # če fileta ni, ga ustvarim in zapišem default HS dict
		data_file.open("user://%s_highscores.save" % read_game_name, File.WRITE)
		var default_highscores: Dictionary = build_default_highscores(lines_to_read_count)
		data_file.store_line(to_json(default_highscores))
		data_file.close()
	# odprem filet za branje
	data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
		
	# prepiši podatke iz fileta v igro
	var current_game_highscores = parse_json(data_file.get_line())
	data_file.close()
	
	return current_game_highscores


func save_player_score(current_score: float, current_game_data: Dictionary):
	# med izvajanjem te kode GM čaka
	# poberem trenutno lestvico (potem generiram novo z dodanim trenutnim skorom)
	
	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	var current_game_highscores: Dictionary = read_highscores_from_file(current_game_data) # ... v odprtem filetu se potem naloži highscore
	for hs_position_key in current_game_highscores:
		var current_position_dict = current_game_highscores[hs_position_key]
		all_ranking_scores += current_position_dict.values()
		all_ranking_score_owners += current_position_dict.keys()
	
	# ime plejerja
	var current_score_owner_name: String = Global.gameover_gui.p1_final_stats["player_name"]
	current_score_owner_name = current_score_owner_name

	# zgradim novo lestvico z dodanim plejerjem in scorom
	all_ranking_scores.insert(current_player_rank - 1, current_score)
	all_ranking_score_owners.insert(current_player_rank - 1, current_score_owner_name)
	# odstranim zadnjega ... najnižjega
	all_ranking_scores.pop_back()
	all_ranking_score_owners.pop_back()
	
	# sestavim nov slovar za lestvico
	var new_game_highscores: Dictionary
	var highscore_index = 0
	for ranking_score in all_ranking_scores:
		var highscores_position_key: String = "%02d" % (highscore_index + 1)
		var highscores_value: float = ranking_score
		var highscores_owner: String = all_ranking_score_owners[highscore_index]
		var position_dict: Dictionary = {
			highscores_owner: highscores_value,	
		}
		new_game_highscores[highscores_position_key] = position_dict
		highscore_index += 1
		
	# sejvam hs slovar v filet
	write_highscores_to_file(current_game_data, new_game_highscores)
	
	emit_signal("scores_saved") # OPT trenutno se ne uporablja, čeprav bi bilo dobra praksa


func build_default_highscores(lines_to_build_count: int):
	
	var new_highscores: Dictionary
	for n in lines_to_build_count:
		var highscore_line_key_as_rank: String = "%02d" % (n + 1)	
		new_highscores[highscore_line_key_as_rank] = {Profiles.default_highscore_line_name: 0}
	
	return new_highscores
