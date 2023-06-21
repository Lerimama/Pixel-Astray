extends Node


var data_file: = File.new()

func _ready() -> void:
	Global.data_manager = self

	
func get_top_highscore(current_level):
	
	# load highscore
	var loaded_level_highscores = read_highscores_from_file(current_level) # ... v odprtem filetu se potem naloži highscore
	
	
	# current higscore in lastnik
	var all_scores: Array # = loaded_level_highscores.values()
	var all_score_owners: Array # = loaded_level_highscores.keys()
	
	for hs_position_key in loaded_level_highscores:
		# dodam vrednost s pozicija
		var current_position_dict = loaded_level_highscores[hs_position_key]
		
		all_scores += current_position_dict.values()
		all_score_owners += current_position_dict.keys()
		
		
	# setam top score
	var current_highscore: float = all_scores.max()
	var current_highscore_index: int = all_scores.find(current_highscore)
	var current_highscore_owner: String = all_score_owners[current_highscore_index]
	
	# _temp za GM hud
	printt ("DM - get_top_hs", current_highscore, current_highscore_owner, loaded_level_highscores)
	
	return [current_highscore, current_highscore_owner]


func manage_gameover_highscores(player_points, current_level): # iz GM
	
	# med izvajanjem te kode GM čaka na RESUME 1
	
	var all_scores: Array
	var all_score_owners: Array
	var current_level_highscores: Dictionary # zaenkrat samo pri GO
	var new_score_position: int
	var better_positions_count: int
	
	current_level_highscores = read_highscores_from_file(current_level) # ... v odprtem filetu se potem naloži highscore
	
	# poberemo lestvico v arraye
	for hs_position_key in current_level_highscores:
		
		var current_position_dict = current_level_highscores[hs_position_key]
		all_scores += current_position_dict.values()
		all_score_owners += current_position_dict.keys()
	
	# izračun uvrstitve ... štejem pozicije pred mano
	better_positions_count = 0 # 0 je 1. mesto
	for score in all_scores:
		# če je score večji od trenutih točk igralca
		if score >= player_points:
			better_positions_count += 1
	
	# NI na lestvici
	if better_positions_count >= all_scores.size():
		return false
	# JE na lestvici
	else:
	
		# YIELD 2 
		print ("DM - YIELD 2")
		yield(Global.gameover_menu, "name_input_finished")
		
		# ... čaka na novo ime, ki bo prišlo iz GM, ki ga dobi od GO
		
		# RESUME 2
		print ("DM - RESUME 2")
		
		# nova highscore lestvica		
		var current_score_owner = Global.game_manager.player_stats["player_name"]
		
		# dodam plejer score v array
		all_scores.insert(better_positions_count, player_points)
		all_score_owners.insert(better_positions_count, current_score_owner)

		# odstranim zadnjega ... najnižjega
		all_scores.pop_back()
		all_score_owners.pop_back()
		
		# sestavim nov hs slovar
		var new_level_highscores: Dictionary
		var highscore_index = 0
		for score in all_scores:
			var highscores_position_key: String = str(highscore_index + 1)
			var highscores_value: float = score
			var highscores_owner: String = all_score_owners[highscore_index]
			var position_dict: Dictionary = {
				highscores_owner: highscores_value,	
			}

			new_level_highscores[highscores_position_key] = position_dict
			highscore_index += 1

		# sejvam hs slovar v filet
		write_highscores_to_file(current_level, new_level_highscores)
		
		# prikažem hs tabelo, ki sama naloži hs iz fileta (tako je bolj modularna=
		Global.gameover_menu.highscore_table.open_highscore_table()


# READ / WRITE

func read_highscores_from_file(current_level_no: int):
	
	
	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://level%s_highscores.save" % current_level_no, File.READ)
	# The file is created if it does not exist, and truncated if it does.
	
	# če fileta ni, ga ustvarim in zapišem default hs dict
	if error != OK: # OK je 0
#		printt("Error loading file", error)
		data_file.open("user://level%s_highscores.save" % current_level_no, File.WRITE) # vsak level ma svoj filet
		# vnesem default HS
		data_file.store_line(to_json(Profiles.default_level_highscores))
		data_file.close()
#		printt("Default file created", data_file)
		# ko je filet ustvarjen grem naprej na podajanje vse HSjev
	
	data_file.open("user://level%s_highscores.save" % current_level_no, File.READ)
#	printt("File loaded", data_file)
		
	# prepiši podatke iz fileta v igro
	var current_level_highscores = parse_json(data_file.get_line())
	data_file.close()
	
#	printt("HS loaded and sent to GM", current_level_highscores)
	return current_level_highscores
	
	

func write_highscores_to_file(current_level_no: int, new_level_highscores: Dictionary):
	
	# podam novi HS v json obliko
	var json_string = JSON.print(new_level_highscores)
#	printt("save json_string", json_string)
	
	# preverjam obstoj fileta ... v tem primeru že obstaja, ker ga igra ustvari ob prvem nalaganju
	var error = data_file.open("user://level%s_highscores.save" % current_level_no, File.READ)
	
	# če fileta ni, ga ustvarim in zapišem novi HS
	if error != OK:
#		printt("Error opening file", error)
		data_file.open("user://level%s_highscores.save" % current_level_no, File.WRITE) # vsak level ma svoj filet
#		printt("Empty file created", data_file)
	else:
#		printt("File opened", error)
		data_file.open("user://level%s_highscores.save" % current_level_no, File.WRITE) # vsak level ma svoj filet
	
	# vnesem novi HS
	data_file.store_line(to_json(new_level_highscores))
	
	data_file.close()
		
