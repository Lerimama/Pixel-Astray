extends Node2D


signal row_writen
signal row_deleted
signal http_post_request_done

# sheet data
#var sheet_name: String = "data" # tab
var sheetbook_id: String = "1KfrvMCaqh65EGN_YEUrck8RyKGVbEUERathC6_VnRLQ" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbxLoTTloQte2SX7K4MwNn49knWW115CroDu4ekA6pxdJZJQUJyazp6TN0CI_dVTIJLxJw/exec"

# _obsolete
onready var note_title: LineEdit = $NoteTitle
onready var note_text: LineEdit = $NoteText
onready var title = $NoteTitle
onready var note_list: ItemList = $NoteList
onready var note_tags: LineEdit = $NoteTags

# data columns keys ... usklajeno z appscriptom (case sensitive)
var sheet_name_key: String = "SHEET_NAME"
var column_id_key: String = "SESSION_ID"
var column_title_key: String = "OS_ID"
var column_base_data_key: String = "SESSION_START"
var column_data_1_key: String = "SESSION_END"

# ACTIONS ... tukaj, da imam boljšo kontrolo nad njimi
#var action_new_row: String = "create_new_note"
#var action_save_row: String = "save_existing_note"
#var action_delete_row: String = "delete_note"
#var action_fetch_list: String = "fetch_notes_list"
#var action_fetch_content: String = "fetch_notes_content"
var action_new_row: String = "create_new_row"
var action_save_row: String = "save_existing_row"
var action_delete_row: String = "delete_row"
var action_fetch_list: String = "fetch_rows_list"
var action_fetch_content: String = "fetch_row_content"

var session_table_name: String = "SESSION_DATA"
var game_table_name: String = "GAME_DATA"

var default_session_data: Dictionary = {
	# na prvi sejv od ApiScripta
	"session_id": 0,
	# on session start
	"session_os_id": "ABC",
	"session_date": "01/12/2024",
	"session_start_time": "00:00.00",
	"os_name": "OS",
	"os_language": "nn",
	# on click
	"session_clicks": [],
	# on session end
	"session_length": "0", # secs
}

# narediš novo kolumno z osnovnimi podatki
var session_data_gd: Dictionary = {
#	# na prvi sejv od ApiScripta
#	"session_id": "0",
#	# on session start
#	"session_os_id": "ABC",
#	"session_date": "01/12/2024",
#	"session_start_time": "00:00.00",
#	"os_name": "OS",
#	"os_language": "nn",
#	# on click
#	"session_clicks": [],
#	# on session end
#	"session_length": "00:00.00",
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
	session_data_gd["session_clicks"].append(save_string)
	printt("all clicks", btns_clicked)


func _ready() -> void: # ker je AL se ob debug štartu zgodi 2x

	refresh_row_list()


# on load game
func start_new_session():

	session_data_gd = default_session_data

	if Profiles.analytics_mode:
		# session data
		session_data_gd["session_start_time"] = Time.get_time_string_from_system()

		var date_dict: Dictionary = Time.get_date_dict_from_system()
		var date_string: String = str(date_dict["day"]) + "/" + str(date_dict["month"]) + "/" + str(date_dict["year"])
		session_data_gd["session_date"] = date_string

		session_data_gd["session_os_id"] = OS.get_unique_id()
		# system data
		session_data_gd["os_language"] = OS.get_name()
		session_data_gd["os_name"] = OS.get_locale_language()
		# settings

		save_new_row()
		print("starting new session")


# scene change
func update_mid_session():

	if Profiles.analytics_mode:

		# click data
		pass


# on quit game
func end_session():

	if Profiles.analytics_mode:

		# end data
#		var session_length_secs: float = OS.get_ticks_msec() / 10
#		session_data_gd["session_length"] = Global.get_clock_time(session_length_hunds)
		session_data_gd["session_length"] = Time.get_ticks_msec() / 1000
		update_existing_row(session_data_gd["session_id"])
		print("ending session")


func upload_session_data():
	pass


func upload_game_data():
	pass


# AKCIJE ----------------------------------------------------------------------------------------------------------


func save_new_row(note_id = "", table_id = "") -> void: # id se seta v tabeli

	write_row_content(action_new_row)
	yield(self, "row_writen")
	read_row_list()


func update_existing_row(note_id: int = -1, table_id = "") -> void:

	var selected_id = note_id
	if note_id == -1:
		selected_id = get_selected_row_id()

	#	print(selected_id)
	if selected_id != null:

		write_row_content(action_save_row, selected_id)
		yield(self, "row_writen")
		read_row_list()


func delete_row(note_id = "", table_id = "") -> void:

	var selected_id = get_selected_row_id()
	if selected_id != null:

		delete_row_by_id(selected_id)
		yield(self, "row_deleted")
		read_row_list()


func refresh_row_list(note_id = "", table_id = "") -> void:

	read_row_list()


func display_row_content(row_index: int) -> void:

	var selected_id = get_selected_row_id_from_index(row_index)
	if selected_id != null:
		read_row_content(selected_id)


# API SCRIPT CALL ---------------------------------------------------------------------------------------------


func read_row_list() -> void:

	#	print("fetching on google api")
	make_http_get_request(action_fetch_list)


func read_row_content(id: int) -> void:

	var note_data = {
		"ID": id
	}
	make_http_get_request(action_fetch_content, {"id": id}) # ta ID more bit ker je v sheet script akciji callback s takim imenom


func write_row_content(action: String, id = null) -> void:
	#	printt("saving on google api (create_new_note)", action, id)

	# original
	#	var note_data = {
	#		column_title: title.text,
	#		column_base_data: note_text.text,
	#		column_data_1: note_tags.text
	#	}

	var session_data = {
#		sheet_name_key: "game_data",
#		sheet_name_key: "session_data",
#		column_id_key: session_data_gd["session_id"],
#		column_title_key: session_data_gd["session_os_id"],
#		column_base_data_key: session_data_gd["session_date"],
#		column_data_1_key: session_data_gd["session_length"]
		column_title_key: title.text,
		column_base_data_key: note_text.text,
		column_data_1_key: note_tags.text
	}

	if id != null: # id rabim samo za apdejtat ... nov filet ID od gugla
		session_data[column_id_key] = id

	make_http_post_request(action, session_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_request_done")
	emit_signal("row_writen") # v3
	#	print("note saved signal")


func delete_row_by_id(id: int) -> void:

	var note_data = {
		column_id_key: id
	}

	make_http_post_request(action_delete_row, note_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_request_done")
	emit_signal("row_deleted") # v3


# UTILITI ---------------------------------------------------------------------------------------------


func get_selected_row_id():

	var selected_items = note_list.get_selected_items() # tale vrstica ugotavlja Id noteta v listi, popup lista ga poda avtomatično
	if selected_items.size() > 0:
		var item: String = note_list.get_item_text(selected_items[0])
		var id = item.split(":")[0].strip_edges()
		return int(id)
	return null


func get_selected_row_id_from_index(index: int) -> int:

	var item: String = note_list.get_item_text(index)
	var id = item.split(":")[0].strip_edges()
	return int(id)


# HTTP REQUESTS ---------------------------------------------------------------------------------------------


func make_http_get_request(endpoint: String, params: Dictionary = {}) -> void: # Make a GET request to the API ... endpoint je akcija

	var url = app_url + "?action=" + endpoint
	for key in params.keys():
		url += "&" + key + "=" + str(params[key])

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed") # v3
	# zakaj ni take oblike ... request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	# request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	request.request(url)


func make_http_post_request(endpoint: String, data: Dictionary) -> void: # Make a POST request to the API

	var url = app_url + "?action=" + endpoint
	var json_data = JSON.print(data) # v3 ... print nemasto stringify

	printt("http_POST_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	var headers = ["Content-Type: application/json"] # ["Content-Length: 0"]?
#	printt("json_data", json_data)
	request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)


#	print(json_data.keys())
#	session_data_gd["session_id"] = json_data[column_id_key]
	emit_signal("http_post_request_done") # v3 ... ne dela
	#	print ("emit signal > http_post_request_done")


func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion
	# dobiš get data ali dobiš apdejtan post data

	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result # v3
#		printt("json_result", json_result)

		# wrong aprouč > vlečem podatke za vsebino in samo listo notetov ... kar je kar zanimiv kombo
		if json_result:
			var data = json_result
			# If it's not a list, it is note content , dont make like me , create proper separate functions , here i am just prototyping
			if typeof(data) == TYPE_ARRAY:
				note_list.clear()
				for note in data:
					note_list.add_item(str(note[column_id_key]) + ": " + str(note[column_title_key])) # str ... zazihs, če je številka
			else:
				note_text.text = str(data[column_base_data_key])
				note_tags.text = str(data[column_data_1_key])
				title.text = str(data[column_title_key])
			var last_result_index: int = data.size() - 1# current session id
			session_data_gd["session_id"] = int(data[last_result_index][column_id_key])
			printt ("new session id saved", session_data_gd["session_id"] )
		else:
			printt("JSON parse error  ")#, body)
	else:
#		print("Error with response code: ", response_code, result, body.get_string_from_utf8())
		print("---")
		print("Error with response code: ", response_code)


# BTNS ---------------------------------------------------------------------------------------------


func _on_UpdateBtn_pressed() -> void:

	update_existing_row()


func _on_RefreshBtn_pressed() -> void:

	refresh_row_list()


func _on_DeleteBtn_pressed() -> void:

	delete_row()


func _on_SaveBtn_pressed() -> void:

	save_new_row()


func _on_NoteList_item_selected(index: int) -> void:

	display_row_content(index)


func _on_EndBtn_pressed() -> void:

	end_session()


func _on_StartBtn_pressed() -> void:

	start_new_session()
