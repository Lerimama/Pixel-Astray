extends HTTPRequest

signal guest_authenticated
signal connection_closed
signal global_saved_to_local


var token: String
var player_id: String
var player_name: String = "" # debug
var global_board_updated: bool = false # false vsakič, ko vpišem nov hs
#var guest_authenticated: bool = true

func _ready() -> void:
	
	timeout = 5.0 # ker je autoload mu ne moram settat settingsih	
	
#func _process(delta: float) -> void:
#	print("global_scores_updated", global_board_updated)
func authenticate_guest_session(player_stats: Dictionary = {}): # kliče LL_cover na open_and_connect

	ConnectCover.open_cover()
	yield(get_tree().create_timer(0.5), "timeout") # _temp
	
	# get player name
	if player_stats.empty():
		player_id = OS.get_unique_id()
	else:
		player_name = player_stats["player_name"]	
		player_id = player_name

	# authenticate guest session
	var url: String = "https://api.lootlocker.io/game/v2/session/guest"
	var header: Array = ["Content-Type: application/json"]
	var method = HTTPClient.METHOD_POST
	var request_body: Dictionary = {
		"game_key": "dev_5a1cab01df0641c0a5f76450761ce292", # lootlocker key
		"game_version": "0.92", # verzija igre (za vedenje kaj je kje)
		"player_identifier": player_id,  # če je prazen je OS id
		"development_mode": true,
	}
	
	request(url, header, false, method, to_json(request_body)) 

	# čakam na odgovor od lootlockerja ... zato dam yield
	# request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray)
	var response = yield(self, "request_completed")[3] 
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
	
	# ni povezave
	if response == null or not "session_token" in response:
		# printt("No internet connection ...", response)
		ConnectCover.cover_label_text = "Connection failed."
		yield(get_tree().create_timer(2), "timeout") # _temp
		ConnectCover.close_cover()
		emit_signal("connection_closed") # tukaj zato, da se zapre tudi popup
	
	else: # je povezava ... if "session_token" in response:
		# printt("Player token connected", token)
		token = response["session_token"]
		ConnectCover.cover_label_text = "Connected."
		yield(get_tree().create_timer(0.5), "timeout") # _temp
		emit_signal("guest_authenticated")


func submit_score_to_lootlocker(new_player_stats: Dictionary):
#
	
	authenticate_guest_session(new_player_stats)
	yield(self, "guest_authenticated")	
	global_board_updated = false
	ConnectCover.cover_label_text = "Publishing_score"
	
	var player_name: String = new_player_stats["player_name"]
	var player_score = new_player_stats["player_points"] # OPT go static
	
	var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/submit" # naslov do LL tabele ... samo ključ tabele se spreminja
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % LootLocker.token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": LootLocker.player_id, # player ID je ime
	}
	
	request(url, header,false, method, to_json(request_data)) 
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed") # to_json(request_body
	yield(get_tree().create_timer(0.8), "timeout") # _temp
	
	get_submited_scores_global_board_and_save(player_name, player_score)
	
	
#	ConnectCover.close_cover()
#	emit_signal("connection_closed") # tukaj zato, da se zapre tudi popup

	
func get_submited_scores_global_board_and_save(new_name: String, new_score: float):
	
	ConnectCover.cover_label_text = "Geting global rank"
	yield(get_tree().create_timer(0.8), "timeout") # _temp

	
##	if not global_board_updated:
#	authenticate_guest_session()
#	yield(self, "guest_authenticated")

#	ConnectCover.cover_label_text = "Getting global scores ..."

	var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/list?count=%s" % str(grab_results_count) # koliko mest rabimo
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % token]
	var method = HTTPClient.METHOD_GET

#		printt("REQ", url, header, false, method) 
	request(url, header, false, method) 
	
	# grab method
	var response = yield(self, "request_completed")[3] 
	# body to string
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
#		printt("RESPONSE", response)

	if "items" in response: # "items" je ime LL slovarja, ki ima podatke o plejerju
		board = response["items"]
		
#	print("BOARD", board)
	global_board_updated = true
	
	update_and_save_global_highscores_to_local(Profiles.game_data_classic)
	printt(self, "global_saved_to_local")
#	yield(self, "global_saved_to_local")
#	yield(LootLocker, "global_saved_to_local")
	printt("no")
#
	var global_rank: int = 99
#
	for item in board:
		if item["member_id"] == new_name and item["score"] == new_score:
			global_rank = item["rank"]
			break
#
#		# dodam level name za ime save fileta in sejvam
#	var current_game_data_global = current_game_data.duplicate()
#	current_game_data_global["level"] = "Global"
#	Global.data_manager.write_highscores_to_file(current_game_data_global, global_game_highscores)
#	print ("emit_signal global_saved_to_local")
#	emit_signal("global_saved_to_local")
	
	
	
	ConnectCover.cover_label_text = "Published. Global rank %s" %str(global_rank)
	yield(get_tree().create_timer(2), "timeout")
	ConnectCover.close_cover()
#		global_highscore_table = build_global_game_leaderboard(board)
	emit_signal("connection_closed")

	
var board
var grab_results_count: int = 99 # če bi blo več, ne paše na %02d 


func get_lootlocker_leaderboard():
	
#	authenticate_guest_session()
#	yield(self, "guest_authenticated")

	ConnectCover.cover_label_text = "Getting global scores ..."

	var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/list?count=%s" % str(grab_results_count) # koliko mest rabimo
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % token]
	var method = HTTPClient.METHOD_GET

#		printt("REQ", url, header, false, method) 
	request(url, header, false, method) 
	
	# grab method
	var response = yield(self, "request_completed")[3] 
	# body to string
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
#		printt("RESPONSE", response)

	if "items" in response: # "items" je ime LL slovarja, ki ima podatke o plejerju
		board = response["items"]
#		print("BOARD", board)
		
	global_board_updated = true
	yield(get_tree().create_timer(2), "timeout")
	ConnectCover.close_cover()
#		global_highscore_table = build_global_game_leaderboard(board)
	emit_signal("connection_closed")
#	else:
			
	print("LL bord", board.size())
#	emit_signal("connection_closed") # tukaj zato, da se zapre tudi popup

		
#	printt("BOARD", board)
#	return global_highscore_table
#	return board

	
	
func update_and_save_global_highscores_to_local(current_game_data: Dictionary):
	
	if not global_board_updated:
		authenticate_guest_session()
		yield(self, "guest_authenticated")
	# pogrebam board s spleta
	# spremenim board v slovar kot so lokalne HS
	# shranim v filet igre (dodam level Global)
	
	# če je že apdejtan, samo shrani trenutni board v obliko slovarja
#	if not global_board_updated:
	
		# pogrebam leaderboard z neta
		get_lootlocker_leaderboard() # Dictionary ali object
		
		print ("authenticating non updated")
		yield(self, "connection_closed")
	
	# spremenim board v HS slovar 
	var new_board = board # Dictionary ali object	
	printt ("board size", new_board.size())
	var global_game_highscores: Dictionary = {} 
	for item in new_board:
		var item_dictionary: Dictionary = item
		var item_player_name: String = item_dictionary["member_id"]
		var item_player_score = item_dictionary["score"]
		var item_player_rank = "%02d" % item_dictionary["rank"]
		
		var highscores_player_name: String = str(item_player_name)
		var highscores_player_line: Dictionary 
		highscores_player_line[highscores_player_name] = item_player_score
		
		# add player dict to higscores dict
		global_game_highscores[item_player_rank] = highscores_player_line
	
	# dodam level name za ime save fileta in sejvam
	var current_game_data_global = current_game_data.duplicate()
	current_game_data_global["level"] = "Global"
	Global.data_manager.write_highscores_to_file(current_game_data_global, global_game_highscores)
	emit_signal("global_saved_to_local")
	print ("emit_signal global_saved_to_local")
	
#	classic_table.get_local_to_global_ranks(current_game_data, current_game_data_global) # _temp
#	classic_table_glo.get_highscore_table(current_game_data_global, fake_player_ranking, 15) # _temp
