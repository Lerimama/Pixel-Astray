extends HTTPRequest

signal guest_authenticated

var player_id: String # setam pred avtentikacijo
var session_token: String # dobim ob avtentikaciji
var lootlocker_leaderboard: Array

var global_results_count: int = 99 # če bi blo več, ne paše na %02d 
var guest_is_authenticated: bool = false
var anonymous_guest_name: String = "anonymous" # ko čekiraš HS v home


func _ready() -> void:
	
	timeout = 5.0 # ker je autoload mu ne moram settat settingsih	
	

func publish_score_to_lootlocker(new_player_stats: Dictionary): # ko objaviš nov skor z novim imenom, se je potrebno pononvno povezat
	
	guest_is_authenticated = false
	
	var player_name: String = new_player_stats["player_name"]
	var player_score = new_player_stats["player_points"] # OPT go static

	authenticate_guest_session(player_name)
	yield(self, "guest_authenticated")	
	
	ConnectCover.cover_label_text = "Publishing your score"
	
	var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/submit" # naslov do LL tabele ... samo ključ tabele se spreminja
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": player_id, # player ID je ime opredeljeno pred avtentikacijo
	}
	
	request(url, header,false, method, to_json(request_data)) 
	
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed")
	yield(get_tree().create_timer(0.8), "timeout") # _temp ... cover timer
	
	update_lootlocker_leaderboard(Profiles.game_data_classic) # OPT Profiles.game_data_classic odstrani


func update_lootlocker_leaderboard(current_game_data: Dictionary): 
	# update = get and save
	# pogrebam leaderboard z neta
	# sejvam leaderboard v obliki lokalnih HS
	
	if not guest_is_authenticated:
		authenticate_guest_session(anonymous_guest_name)
		print("tuki")
		yield(self, "guest_authenticated")

	ConnectCover.cover_label_text = "Updating global leaderboards"

	var url: String = "https://api.lootlocker.io/game/leaderboards/PAclassic/list?count=%s" % str(global_results_count) # koliko mest rabimo
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_GET

	request(url, header, false, method) 
	
	# čakam ... get method ... convert body to string
	var response = yield(self, "request_completed")[3] 
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key

	if "items" in response: # "items" je ime LL slovarja, ki ima podatke o plejerju
		lootlocker_leaderboard = response["items"]
		
	save_global_highscores_to_local(current_game_data)
	
	ConnectCover.cover_label_text = "Updated"
	yield(get_tree().create_timer(0.5), "timeout") #_temo LL timer
	ConnectCover.close_cover() # odda signal, ko se zapre	
		

func save_global_highscores_to_local(current_game_data: Dictionary):
	
	# spremenim board v HS slovar 
	var new_leaderboard: Array = lootlocker_leaderboard # Dictionary ali object	
	
	var global_game_highscores: Dictionary = {} 
	for item in new_leaderboard:
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
	
	print ("LL leaderboard updated ... get&save")


func authenticate_guest_session(player_name: String):

	ConnectCover.cover_label_text = "Connecting to server"
	ConnectCover.open_cover()
	yield(get_tree().create_timer(0.5), "timeout") # _temp ... cover timer
	
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
	var response = yield(self, "request_completed")[3] 
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
	
	# CONNECTION FAILED
	if response == null or not "session_token" in response:
		ConnectCover.cover_label_text = "Connection failed"
		yield(get_tree().create_timer(1), "timeout") # _temp ... cover timer
		ConnectCover.close_cover() # odda signal, ko se zapre
	# CONNECTED
	else:
		session_token = response["session_token"]
		ConnectCover.cover_label_text = "Connected"
		
		yield(get_tree().create_timer(0.5), "timeout") # _temp ... cover timer
		guest_is_authenticated = true
		emit_signal("guest_authenticated")
