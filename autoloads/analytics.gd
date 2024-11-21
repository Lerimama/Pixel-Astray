extends Node2D


signal row_writen
signal http_post_request_done

# sheet data
var sheetbook_id: String = "1KfrvMCaqh65EGN_YEUrck8RyKGVbEUERathC6_VnRLQ" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbxN5Jl_i7Ba0a-uUaC1svAd4jeMSMfX5NkZ2lpqzGpgRBCAoIs4QlgA-Jyt4Y25N9q3Hg/exec"
#var test_app_url: String = "https://script.google.com/macros/s/AKfycby81dLgAuhWl_J5RrlTniXCmlacV0O8brOAwHSPrr3k/dev"

# API
# api actions ... tukaj, da imam boljšo kontrolo nad njimi
var action_new_row: String = "create_new_row"
var action_save_row: String = "save_existing_row"
var action_fetch_list: String = "fetch_rows_list"

# data columns keys ... usklajeno z appscriptom (case sensitive)
#var session_table_name: String = "SESSION_DATA"
#var game_table_name: String = "GAME_DATA"
#var os_id_column_key: String = "device_id"
#var column_base_data_key: String = "session_date"
#var column_data_1_key: String = "SESSION_END"

var sheet_name_key: String = "SHEET_NAME"
var id_column_key: String = "session_id"

var default_session_data: Dictionary = { # debug
	"session_id": 0, # na prvi sejv od ApiScripta
	"device_id": "ABC",
	"session_date": "01/12/2024",
	"session_time": "00:00:00",
	"os_name": "OS",
	"os_language": "nn",
	"ui_clicks": ["krbneki"], # on click
	"session_length": 0, # secs ... on session end
}

# narediš novo kolumno z osnovnimi podatki
var session_data: Dictionary = {
}

var game_data: Dictionary = {
	"game_name": "Cleaner",
	"game_over": "00:00.00", # cleaned, time, life, premature
}

var btns_clicked: Array = []
var post_on_quit_time: float = 4

func save_ui_action(ui_action):
	# podatki se nabirajo iz:
	# intro
	# ui gumbov (global)
	# tipkovnice
	# home > ESC input
	# settings > volume slider
	# GO > name_input, publish popup

	var save_string: String
	match typeof(ui_action):
		TYPE_STRING: # key input
			save_string = ui_action.as_text()
		TYPE_OBJECT: # btn
			#			var btn_name: String = ui_action.name
			#			var btn_parent: Node = ui_action.get_parent()
			#			var btn_owner: String = ui_action.owner.name
			save_string = ui_action.name
		TYPE_ARRAY: # toggle/slider >  btn in bool/value
			var btn_name: String = ui_action[0].name
			var btn_bool = ui_action[1]
			save_string = btn_name + " " + str(btn_bool)

	btns_clicked.append(save_string)
	session_data["ui_clicks"].append(save_string)
	printt("all clicks", btns_clicked)


func _ready() -> void:

	# ker je AL se ob debug štartu zgodi 2x
	reset_session_data()


# on load game
func start_new_session(start_fake: bool = false):

	if Profiles.analytics_mode:

		# napolnem start data
		var date_dict: Dictionary = Time.get_date_dict_from_system()
		var date_string: String = str(date_dict["day"]) + "/" + str(date_dict["month"]) + "/" + str(date_dict["year"])
#		session_data["session_id"] = 0
		session_data["session_date"] = date_string
		session_data["session_time"] = Time.get_time_string_from_system()
		session_data["device_id"] = OS.get_unique_id()
		session_data["os_language"] = OS.get_locale_language()
		session_data["os_name"] = OS.get_name()

		# dodam v tabelo
		save_new_row()
		print("starting new session --->")


# scene change
func update_mid_session():

	if Profiles.analytics_mode:
		pass


# on quit game
func end_session(end_fake: bool = false):

	if Profiles.analytics_mode:

		# napolnem end data
		session_data["session_length"] = round(Time.get_ticks_msec() / 1000)

		# apdejtam tabelo
		save_existing_row(session_data["session_id"])
		print("---> ending session")


func reset_session_data():

	session_data = default_session_data
	#	os_input.text = ""
	#	date_input.text = ""
	#	length_input.text = ""
	pass

# AKCIJE ----------------------------------------------------------------------------------------------------------


func save_new_row() -> void: # id se seta v tabeli

	write_row_content(action_new_row)
	yield(self, "row_writen")
	read_row_list() # da dobim ID (zadnje) sejvane vrstice ... list.size() - 1


func save_existing_row(row_id: int) -> void:

	write_row_content(action_save_row, row_id)



# API SCRIPT CALL ---------------------------------------------------------------------------------------------


func read_row_list() -> void:

	make_http_GET_request(action_fetch_list)


func write_row_content(action: String, id = null) -> void:

	var data_for_apiscript: Dictionary = session_data
#		sheet_name_key: "session_data",
	data_for_apiscript[sheet_name_key] = "session_data"
#	var data_for_apiscript: Dictionary = {
##		sheet_name_key: "game_data",
#		sheet_name_key: "session_data",
#		id_column_key: session_data["session_id"],
#		os_id_column_key: session_data["device_id"],
#
#		column_base_data_key: session_data["session_date"],
#		column_data_1_key: session_data["session_length"]
#	}

#	if id != null: # id rabim samo za apdejtat ... nov filet ID od gugla
	if id: # id rabim samo za apdejtat ... nov filet ID od gugla
		data_for_apiscript[id_column_key] = id

	make_http_POST_request(action, data_for_apiscript)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_request_done")
	emit_signal("row_writen") # v3


# HTTP REQUESTS ---------------------------------------------------------------------------------------------


func make_http_GET_request(endpoint: String, params: Dictionary = {}) -> void: # Make a GET request to the API ... endpoint je akcija

	var url = app_url + "?action=" + endpoint
	for key in params.keys():
		url += "&" + key + "=" + str(params[key])

	printt("http_GET_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed") # v3
	# zakaj ni take oblike ... request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	# request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	request.request(url)


func make_http_POST_request(endpoint: String, data: Dictionary) -> void: # Make a POST request to the API

	var url = app_url + "?action=" + endpoint
	var json_data = JSON.print(data) # v3 ... print nemasto stringify

	printt("http_POST_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	var headers = ["Content-Type: application/json"] # ["Content-Length: 0"]?
	request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)

	emit_signal("http_post_request_done") # v3 ... ne dela
	#	print ("emit signal > http_post_request_done")


func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion

	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result # v3
		#		printt("json_result", json_result)
		if json_result:
			var data = json_result
			var last_result_index: int = data.size() - 1
			session_data["session_id"] = int(data[last_result_index][id_column_key]) # _temp
			print("_on_request_completed OK - New session id: ", session_data["session_id"] )
		else:
			print("JSON parse error", res)
	else:
		print("_on_request_completed Error - Response code: ", response_code)
		print(result)
		print(headers)
#		print(body)


# BTNS ---------------------------------------------------------------------------------------------


func _on_EndBtn_pressed() -> void:

	end_session()


func _on_StartBtn_pressed() -> void:

	start_new_session()


func _on_StartFakeBtn_pressed() -> void:

	start_new_session(true)


func _on_EndFakeBtn_pressed() -> void:

	end_session(true)
