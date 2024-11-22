extends Node2D


signal http_post_request_done # ne dela
signal session_saved

var btns_clicked: Array = []
var games_played: Array = []


# api
var sheetbook_id: String = "1KfrvMCaqh65EGN_YEUrck8RyKGVbEUERathC6_VnRLQ" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbz76l3icHLNcZdYA7-iWcXOl2KJOjn8SRUvFPBZthCbLJeOXhxrP8-RRruh1jz_Yc5v-w/exec"
# actions ... tukaj, da imam boljšo kontrolo nad njimi
var action_new_row: String = "create_new_row"
var action_save_row: String = "save_existing_row"
var action_fetch_list: String = "fetch_rows_list"


# debug
var post_on_quit_time: float = 4
var session_data: Dictionary = {
	"sheet_name": "SESSION_DATA", # case INsensitive
	"session_id": 0, # na prvi sejv od ApiScripta
	"device_id": "ABC",
	"session_date": "01/12/2024",
	"session_time": "00:00:00",
	"os_name": "OS",
	"os_language": "nn",
	"ui_clicks": "", # on click
	"session_length": 0, # secs ... on session end

	"games_played_count": 0, # on ready
	"games_finished_count": 0, # on GO
	"total_playing_time": 0,
	"games_played": "",
}



func save_game_data(game_parameter = null): # parameter je lahko ime igre, končano/nekončano

	match typeof(game_parameter):
		TYPE_STRING: # izbor ... ime igre
			session_data["games_played_count"] += 1
			# game
			current_game_data["game_name"] = game_parameter
			current_game_data["game_started"] = true
			update_session()
		TYPE_NIL: # štart --- empty
			current_game_data["playing_time"] = Time.get_ticks_msec() / 1000
			# game
			current_game_data["game_played"] = true
		TYPE_ARRAY: # konec ... kančano / nekončano
			session_data["total_playing_time"] += current_game_data["playing_time"]
			# game
			var game_start_time: int = current_game_data["playing_time"]
			current_game_data["playing_time"] = Time.get_ticks_msec() / 1000 - game_start_time
			current_game_data["end_stray_count"] =  game_parameter[1]
			var game_finished: bool = game_parameter[0]
			if game_finished == true:
				session_data["games_finished_count"] += 1
				current_game_data["game_finished"] = true

			session_data["games_played"] += current_game_data["game_name"]
			session_data["games_played"] += " - Fin " + str(current_game_data["game_finished"])
			session_data["games_played"] += ", Strays " + str(current_game_data["end_stray_count"])
			session_data["games_played"] +=", Time " + str(current_game_data["playing_time"]) + "s"
			session_data["games_played"] +="\n"

			update_session()


var current_game_data: Dictionary = { # ime ob zaprtju spremeni v številko in doda v games_played
	"game_name": "",
	"game_started": false,
	"game_played": false,
	"game_finished": false,
	"end_stray_count": 0,
	"playing_time": 0, # če je 0 je prehitro končana igra
}

# on load game
func start_new_session(start_fake: bool = false):

	if Profiles.analytics_mode:
		print("> starting new session")

		var date_dict: Dictionary = Time.get_date_dict_from_system()
		var date_string: String = str(date_dict["day"]) + "/" + str(date_dict["month"]) + "/" + str(date_dict["year"])
		session_data["session_date"] = date_string
		session_data["session_time"] = Time.get_time_string_from_system()
		session_data["device_id"] = OS.get_unique_id()
		session_data["os_language"] = OS.get_locale_language()
		session_data["os_name"] = OS.get_name()
		save_new_row()


# scene change
func update_session(): # kliče main

	if Profiles.analytics_mode:
		print("> mid session")
		save_existing_row(session_data["session_id"])


# on quit game
func end_session(end_fake: bool = false):

	if Profiles.analytics_mode:
		print("> ending session")
		session_data["session_length"] = round(Time.get_ticks_msec() / 1000)
		save_existing_row(session_data["session_id"])


func save_ui_click(ui_action):
	# podatki se nabirajo iz ui gumbov (global), keyboard input
	# specials: intro, home ESC keyboard input, settings volume slider, GO name_input & publish

	var save_string: String
	match typeof(ui_action):
		TYPE_STRING: # key input
			save_string = ui_action
		TYPE_OBJECT: # btn
			save_string = ui_action.name
		TYPE_ARRAY: # toggle/slider >  btn in bool/value
			var btn_name: String = ui_action[0].name
			var btn_bool = ui_action[1]
			save_string = btn_name + " " + str(btn_bool)

	if session_data["ui_clicks"] == "":
		session_data["ui_clicks"] += save_string
	session_data["ui_clicks"] +=" > " + save_string
	printt("ui_clicks", session_data["ui_clicks"])
	btns_clicked.append(save_string)


func reset_session_data():

	#	os_input.text = ""
	#	date_input.text = ""
	#	length_input.text = ""
	session_data = {
		"session_id": 0, # pravega poda sheet api na prvi sejv od ApiScripta
		"device_id": "ABC",
		"session_date": "01/12/2024",
		"session_time": "00:00:00",
		"os_name": "OS",
		"os_language": "nn",
		"ui_clicks": ["none"],
		"session_length": 0,
	}


# ROW ACTIONS --------------------------------------------------------------------------------------------------


func save_new_row() -> void: # id se seta v tabeli

	write_row_content(action_new_row)
	yield(self, "session_saved")
	read_row_list() # da dobim ID (zadnje) sejvane vrstice ... list.size() - 1


func save_existing_row(row_id: int) -> void:

	write_row_content(action_save_row, row_id)


# API SCRIPT CALL ---------------------------------------------------------------------------------------------


func read_row_list() -> void:

	make_http_GET_request(action_fetch_list)


func write_row_content(action: String, id = null) -> void:

	print("GD ", current_game_data)
	if id: # id rabim samo za apdejt ... nov filet dobi ID od gugla
		session_data["session_id"] = id

	make_http_POST_request(action, session_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_request_done") # OPT ...post signal ne dela
	emit_signal("session_saved")


# HTTP REQUESTS ---------------------------------------------------------------------------------------------


func make_http_GET_request(endpoint: String, params: Dictionary = {}) -> void: # Make a GET request to the API ... endpoint je akcija

	var url = app_url + "?action=" + endpoint
	for key in params.keys():
		url += "&" + key + "=" + str(params[key])

	printt("http_GET_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	# zakaj ni take oblike ... request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	request.request(url)


func make_http_POST_request(endpoint: String, data: Dictionary) -> void: # Make a POST request to the API

	var url = app_url + "?action=" + endpoint
	var json_data = JSON.print(data)

	#	printt("http_POST_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	var headers = ["Content-Type: application/json"]
	request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)

	emit_signal("http_post_request_done") # ... ne dela
	#	print ("emit signal > http_post_request_done")


func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion

	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result
		#		printt("json_result", json_result)
		if json_result:
			var returned_data = json_result
			# preverim id trenutne seanse na google tabeli (last row id)
			var current_row_index = returned_data.size() - 1
			var current_session_id: int = returned_data[current_row_index]["session_id"]
			session_data["session_id"] = current_session_id
			print("OK! _on_request_completed")
			#			print("New session id: ", session_data["session_id"] )
		else:
			print("Error! JSON parse")
			print("Result UTF8: ", res)
	else:
		print("Error! _on_request_completed")
		if response_code != 405:
			print("Response code: ", response_code)
			print("Result: ", result)
			print("Headers: ", headers.size())
			#		print("Bs", body)

	print("--- request end ---")


# BTNS ---------------------------------------------------------------------------------------------


func _on_EndBtn_pressed() -> void:

	end_session()


func _on_StartBtn_pressed() -> void:

	start_new_session()


func _on_StartFakeBtn_pressed() -> void:

	start_new_session(true)


func _on_EndFakeBtn_pressed() -> void:

	end_session(true)
