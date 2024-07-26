extends HTTPRequest

signal guest_authenticated
signal connection_closed


var token: String
var player_id: String
var player_name: String = "" # debug
var global_scores_updated: bool = false # false vsakič, ko vpišem nov hs
#var guest_authenticated: bool = true

func _ready() -> void:
	
	timeout = 5.0 # ker je autoload mu ne moram settat settingsih	
	
	
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
		ConnectCover.cover_label_text = "Connected ..."
		yield(get_tree().create_timer(0.5), "timeout") # _temp
		emit_signal("guest_authenticated")


func submit_score_to_lootlocker(new_player_stats: Dictionary):
	
	global_scores_updated = false
	
	authenticate_guest_session(new_player_stats)
	yield(self, "guest_authenticated")	
	
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
	ConnectCover.close_cover()
	emit_signal("connection_closed") # tukaj zato, da se zapre tudi popup
	
	
var board
var grab_results_count: int = 99 # če bi blo več, ne paše na %02d 


func get_lootlocker_leaderboard():
	
	if not global_scores_updated:
		authenticate_guest_session()
		yield(self, "guest_authenticated")
	
		ConnectCover.cover_label_text = "Getting global scores ..."

		var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/list?count=%s" % str(grab_results_count) # koliko mest rabimo
		var header: Array = ["Content-Type: application/json", "x-session-token: %s" % token]
		var method = HTTPClient.METHOD_GET

		printt("REQ", url, header, false, method) 
		request(url, header, false, method) 
		
		# grab method
		var response = yield(self, "request_completed")[3] 
		# body to string
		response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
		printt("RESPONSE", response)

		if "items" in response: # "items" je ime LL slovarja, ki ima podatke o plejerju
			board = response["items"]
			
		global_scores_updated = true
		yield(get_tree().create_timer(2), "timeout")
		ConnectCover.close_cover()
#		global_highscore_table = build_global_game_leaderboard(board)
	emit_signal("connection_closed")
#	else:
			
#	print(board)
#	emit_signal("connection_closed") # tukaj zato, da se zapre tudi popup

		
#	printt("BOARD", board)
#	return global_highscore_table
#	return board
