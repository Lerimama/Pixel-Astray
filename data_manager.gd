extends Node


signal highscores_updated # ko je vnešeno ime igralca

var data_file: = File.new()
var current_player_ranking: int # da ob rendriranju HS, lahko označim aktualni rezultat ... v GM
var all_games_key
var default_highscores: Dictionary = { # slovar, ki se uporabi, če še ni nobenega v filetu
	"01": {"Mr.Nobody": 0,},
	"02": {"Mr.Nobody": 0,},
	"03": {"Mr.Nobody": 0,},
	"04": {"Mr.Nobody": 0,},
	"05": {"Mr.Nobody": 0,},
	"06": {"Mr.Nobody": 0,},
	"07": {"Mr.Nobody": 0,},
	"08": {"Mr.Nobody": 0,},
	"09": {"Mr.Nobody": 0,},
	"10": {"Mr.Nobody": 0,},
}

func _ready() -> void:
	
	Global.data_manager = self

# highscores ------------------------------------------------------------------------------------------------------------------------

	
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
		Profiles.HighscoreTypes.HS_POINTS:
			current_highscore = all_scores.max()
		Profiles.HighscoreTypes.HS_TIME_LOW:
			var valid_scores: Array # vsi, ki niso 0
			for score in all_scores:
				if score > 0:
					valid_scores.append(score)
			if valid_scores.empty(): # prevent error, kadar so same 0
				current_highscore = 0
			else:
				current_highscore = valid_scores.min()
		Profiles.HighscoreTypes.HS_TIME_HIGH:
			current_highscore = all_scores.max()


	var current_highscore_index: int = all_scores.find(current_highscore)
	var current_highscore_owner: String = all_score_owners[current_highscore_index]
	
	# za GM hud
	return [current_highscore, current_highscore_owner]


func manage_gameover_highscores(current_score: float, current_game_data: Dictionary): # iz GM
	# med izvajanjem te kode GM čaka na RESUME 1

	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	var current_game_highscores: Dictionary = read_highscores_from_file(current_game_data) # ... v odprtem filetu se potem naloži highscore
	# current_score_time je že zaokrožen na 2 decimalki
	
	# poberemo lestvico v arraye
	for hs_position_key in current_game_highscores:
		var current_position_dict = current_game_highscores[hs_position_key]
		all_ranking_scores += current_position_dict.values()
		all_ranking_score_owners += current_position_dict.keys()
	
	# izračun uvrstitve na lestvico ... štejem pozicije pred mano 
	var better_positions_count: int = 0
	for ranking_score in all_ranking_scores:
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW: # edinkrat ko se šteje nižje število
			if ranking_score <= current_score and not ranking_score <= 0:
				better_positions_count += 1				
		else:
			if ranking_score >= current_score:
				better_positions_count += 1				
		
	current_player_ranking = better_positions_count + 1 # za označitev linije na lestvici
	
	# NI na lestvici
	if better_positions_count >= all_ranking_scores.size():
		return false
	# JE na lestvici
	else:
		# YIELD 2 ... čaka na novo ime, ki bo prišlo iz GM, ki ga dobi od GO
		yield(Global.gameover_gui, "name_input_finished")
		
		# RESUME 2
		# nova highscore lestvica		
		var current_score_owner_name: String = Global.gameover_gui.p1_final_stats["player_name"]
		current_score_owner_name = current_score_owner_name.capitalize()

		# dodam plejer score v array
		all_ranking_scores.insert(better_positions_count, current_score)
		all_ranking_score_owners.insert(better_positions_count, current_score_owner_name)

		# odstranim zadnjega ... najnižjega
		all_ranking_scores.pop_back()
		all_ranking_score_owners.pop_back()
		
		# sestavim nov hs slovar
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
		
		emit_signal("highscores_updated")


func write_highscores_to_file(write_game_data: Dictionary, new_game_highscores: Dictionary):

	# load highscore
	var write_game_name: String
	if write_game_data.has("level"):
		write_game_name = Profiles.Games.keys()[write_game_data["game"]] + "_" + str(write_game_data["level"])
	else:
		write_game_name = Profiles.Games.keys()[write_game_data["game"]]
	
	# podam novi HS v json obliko
	var json_string = JSON.print(new_game_highscores)
	
	# če fileta ni, ga funkcija ustvari iz File.new()
	data_file.open("user://%s_highscores.save" % write_game_name, File.WRITE) # vsak game ma svoj filet
	
	# vnesem novi HS
	data_file.store_line(to_json(new_game_highscores))
	data_file.close()


func read_highscores_from_file(read_game_data: Dictionary):

	var read_game_name: String
	if read_game_data.has("level"):
		read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_" + str(read_game_data["level"])
	else:
		read_game_name = Profiles.Games.keys()[read_game_data["game"]]
	
	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
	if error != OK: # če fileta ni, ga ustvarim in zapišem default HS dict
		data_file.open("user://%s_highscores.save" % read_game_name, File.WRITE)
		data_file.store_line(to_json(default_highscores))
		data_file.close()
	# odprem filet za branje
	data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
		
	# prepiši podatke iz fileta v igro
	var current_game_highscores = parse_json(data_file.get_line())
	data_file.close()
	
	return current_game_highscores
	
		
# sweeper solved status ------------------------------------------------------------------------------------------------------------------------


func write_solved_status_to_file(write_game_data: Dictionary): # kadar je klican, pomeni, da je uganka rešena

	# load highscore
	var write_game_name: String = Profiles.Games.keys()[write_game_data["game"]]
	var solved_level: int = write_game_data["level"]
	
	# sestavim array vseh rešenih levelov
	var all_solved_levels: Array = read_solved_status_from_file(write_game_data) # če fileta ni ga funckija ustvari in zapiše prazen array
	# zapišem samo če še ne obstaja
	if not solved_level in all_solved_levels:
		all_solved_levels.append(solved_level)
		var json_string = JSON.print(all_solved_levels) # v json obliko
		data_file.open("user://%s_solved.save" % write_game_name, File.WRITE) # 
		data_file.store_line(to_json(all_solved_levels))
	data_file.close()
		
		
func read_solved_status_from_file(read_game_data: Dictionary):

	var read_game_name: String = Profiles.Games.keys()[read_game_data["game"]]

	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://%s_solved.save" % read_game_name, File.READ)
	# če fileta ni, ga ustvarim in pustim praznega
	if error != OK:
		data_file.open("user://%s_solved.save" % read_game_name, File.WRITE)
		data_file.store_line(to_json([]))
		data_file.close()

	# prepiši podatke iz fileta
	data_file.open("user://%s_solved.save" % read_game_name, File.READ)
	var solved_levels_array = parse_json(data_file.get_line()) 
	data_file.close()
	
	return solved_levels_array
