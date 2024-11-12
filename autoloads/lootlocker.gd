extends HTTPRequest

signal guest_authenticated # zase
signal leaderboard_updated # pove kdaj je konec celotnega procesa "apdejtanja"
signal connection_closed # pove kdaj je konec celotnega procesa "apdejtanja"
signal unpublished_score_published # na vrsti je naslednji score

var player_id: String # setam pred avtentikacijo
var session_token: String # dobim ob avtentikaciji
var lootlocker_leaderboard: Array
var guest_is_authenticated: bool = false
var anonymous_guest_name: String = "anonymous" # ko čekiraš HS v home
var final_panel_open_time: float = 1 
var multipublish_count: int = 0	# da ve kdaj je prvi in ga avtenticira ...


func _ready() -> void:
	
	timeout = 5.0 # ker je autoload mu ne moram settat settingsih	
	

func publish_score_to_lootlocker(player_name: String, player_score: float, game_data: Dictionary): # ko objaviš nov skor z novim imenom, se je potrebno pononvno povezat
	
	guest_is_authenticated = false
	
	var game_leaderboard_key = Profiles.Games.keys()[game_data["game"]]
	if game_data["game"] == Profiles.Games.SWEEPER: # OPT iskanja brez sweeperja
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + str(game_data["level"])
	#	printt("LL publish key:", game_leaderboard_key)
	authenticate_guest_session(player_name, true)
	yield(self, "guest_authenticated")	
	
	ConnectCover.cover_label_text = "Publishing ..."
	
	var url: String = "https://api.lootlocker.io/game/leaderboards/%s/submit" % game_leaderboard_key
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": player_id, # player ID je ime opredeljeno pred avtentikacijo
	}
	
	request(url, header,false, method, to_json(request_data)) 
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed")
	
	update_lootlocker_leaderboard(game_data)
	

func multipublish_scores_to_lootlocker(player_name: String, player_score: float, game_data: Dictionary, last_in_row: bool = false): # ko objaviš nov skor z novim imenom, se je potrebno pononvno povezat
	
	multipublish_count += 1
	guest_is_authenticated = false
	
	var game_leaderboard_key = Profiles.Games.keys()[game_data["game"]]
	if game_data["game"] == Profiles.Games.SWEEPER: # OPT iskanja brez sweeperja
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + str(game_data["level"])
		printt ("game_leaderboard_key", game_leaderboard_key, game_data["level"])
	
	if multipublish_count == 1: # avtenticiram na ime prvega rezultata v vrsti
		authenticate_guest_session(player_name, true)
		yield(self, "guest_authenticated")
	
	ConnectCover.cover_label_text = "Publishing score %s" % str(multipublish_count)
	
	var url: String = "https://api.lootlocker.io/game/leaderboards/%s/submit" % game_leaderboard_key
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": player_name, # player ID je ime opredeljeno pred avtentikacijo
		#		"member_id": player_id, # player ID je ime opredeljeno pred avtentikacijo
	}
	
	request(url, header,false, method, to_json(request_data)) 
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed") 
	
	if last_in_row:
		multipublish_count = 0
		
	emit_signal("unpublished_score_published")
		

func update_lootlocker_leaderboard(game_data: Dictionary, last_in_row: bool = true, update_string: String = "", update_in_background: bool = false): 
	
	if not guest_is_authenticated:
		authenticate_guest_session(anonymous_guest_name, last_in_row, update_in_background)
		yield(self, "guest_authenticated")
	else:	
		ConnectCover.open_cover(update_in_background)
		
		
	ConnectCover.cover_label_text = "Updating " + update_string

	var game_leaderboard_key = Profiles.Games.keys()[game_data["game"]]
	if game_data["game"] == Profiles.Games.SWEEPER: # OPT iskanja brez sweeperja
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + str(game_data["level"])
	#	printt("LL update key:", game_leaderboard_key)
	
	var url_without_count: String = "https://api.lootlocker.io/game/leaderboards/%s/list?count=" % game_leaderboard_key
	var url: String = url_without_count + str(Profiles.global_highscores_count)
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_GET

	request(url, header, false, method) 
	
	# čakam ... get method ... convert body to string
	var response = yield(self, "request_completed")[3] 
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
	
	if response == null:
		if last_in_row:	
			on_connection_failed(last_in_row)
	else:	
		if "items" in response:
			if response["items"] == null: # če v tabeli ni items arraya, generiram enega fejk 
				var item: Dictionary = {"member_id": "No score", "rank": 1,"score": 0,}
				response["items"] = [item]
			lootlocker_leaderboard = response["items"]
		# dodam items brez rezultata, da jih bo toliko kot jih potegnem dol
		var missing_results_count: int = Profiles.global_highscores_count - lootlocker_leaderboard.size()
		if missing_results_count > 0:
			for n in missing_results_count:
				var empty_line_rank = lootlocker_leaderboard.size() + 1
				var empty_line_name: String = Profiles.default_highscore_line_name
				var new_item: Dictionary = {
					"member_id": empty_line_name,
					"rank": empty_line_rank,
					"score": 0,
				} 
				lootlocker_leaderboard.append(new_item)
		
		save_lootlocker_leadebroard_to_local_highscore(game_data)
		
		printt ("Leaderboard updated (get,save)", game_leaderboard_key)
		
		if last_in_row:	
			emit_signal("connection_closed")
		else:
			emit_signal("leaderboard_updated")
		

func save_lootlocker_leadebroard_to_local_highscore(game_data: Dictionary):
	
	# spremenim board v HS slovar 
	var global_game_highscores: Dictionary = {} 
	var new_leaderboard: Array = lootlocker_leaderboard # Dictionary ali object	

	for item in new_leaderboard:
		# poberem podatke iz borda
		var item_dictionary: Dictionary = item
		var item_player_name: String = item_dictionary["member_id"]
		var item_player_score = item_dictionary["score"]
		var item_player_rank = "%02d" % item_dictionary["rank"]
		# zapišem v obliko kokalnih HS 
		var highscores_player_name: String = str(item_player_name)
		var highscores_player_line: Dictionary 
		highscores_player_line[highscores_player_name] = item_player_score
		# add player dict to higscores dict
		global_game_highscores[item_player_rank] = highscores_player_line
	
	# dodam level name za ime save fileta in sejvam
	Global.data_manager.write_highscores_to_file(game_data, global_game_highscores)
	

func authenticate_guest_session(player_name: String, last_attempt_in_row: bool, update_in_background: bool = false):

	ConnectCover.cover_label_text = "Connecting ..."
	ConnectCover.open_cover(update_in_background)
	
	player_id = player_name
	
	# authenticate guest session
	var url: String = "https://api.lootlocker.io/game/v2/session/guest"
	var header: Array = ["Content-Type: application/json"]
	var method = HTTPClient.METHOD_POST
	var request_body: Dictionary = {
		"game_key": Profiles.lootlocker_game_key, # lootlocker key
		"game_version": Profiles.lootlocker_game_version, # verzija igre (za vedenje kaj je kje)
		"player_identifier": player_id,  # če je prazen je OS id
		"development_mode": Profiles.lootlocker_development_mode,
	}
	request(url, header, false, method, to_json(request_body))

	# čakam na odgovor od lootlockerja ... zato dam yield
	var response = yield(self, "request_completed")[3] 
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
	
	# CONNECTION FAILED
	if response == null or not "session_token" in response:
		on_connection_failed(last_attempt_in_row)
	# CONNECTED
	else:
		session_token = response["session_token"]
		ConnectCover.cover_label_text = "Connected to server"
		yield(get_tree().create_timer(final_panel_open_time), "timeout")
		guest_is_authenticated = true
		emit_signal("guest_authenticated")


func on_connection_failed(last_attempt_in_row: bool):
		
		printt("Connection failed:", last_attempt_in_row)
		if last_attempt_in_row:
			ConnectCover.cover_label_text = "Connecting failed" # tukaj zato, da prepiše tekst pozitivne reštve 
			yield(get_tree().create_timer(final_panel_open_time), "timeout")
			emit_signal("connection_closed")
		else:
			emit_signal("leaderboard_updated")
