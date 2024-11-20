extends Node2D

signal note_saved
signal note_deleted
signal http_post_done

# sheet data
var sheet_name: String = "data" # tab
var sheetbook_id: String = "1CUGvW2YqWSIrXtWMNF0hcGcFTfonT0DcvO8gU5qIac4" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbxNTByvoBC1IBpTaEWbEjjQ57PJE1iTKHl3wbChj8I_nPJhP1lYvEo4OWr0dEU8sdb5/exec"

# obs
onready var note_title: LineEdit = $NoteTitle
onready var note_text: LineEdit = $NoteText
onready var title = $NoteTitle
onready var note_list: ItemList = $NoteList
onready var note_tags: LineEdit = $NoteTags

# columns
var column_id: String = "SESSION_ID"
var column_title: String = "OS_ID"
var column_base_data: String = "SESSION_START"
# neobvezno
var column_data_1: String = "SESSION_END"

# ACTIONS ... tukaj, da imam boljšo kontrolo nad njimi
var action_new_row: String = "create_new_note"
var action_save_row: String = "save_existing_note"
var action_delete_row: String = "delete_note"
var action_fetch_list: String = "fetch_notes_list"
var action_fetch_content: String = "fetch_notes_content"

# narediš novo kolumno z osnovnimi podatki	
var session_data: Dictionary = {
	"session_id": "0", # pridobi ob sejvanju v google šits
	"session_os_id": "ABC",
	"session_date": "01/12/2024",
	"session_start_time": "00:00.00",
	"session_length": "00:00.00",
	"os_name": "OS",
	"os_language": "nn",
}


# manager funkcije (imitacija gumba)
# ref node = anal_manager
# vedno ko kličem manager funkcijo podam ime tabele in note id

var session_time: float
#var session_os: = 
func _process(delta: float) -> void:
	
	pass


func _ready() -> void: # ker je AL se ob debug štartu zgodi 2x
	
	refresh_note_list()
	
	#	printt ("has_touchscreen", OS.has_touchscreen_ui_hint())
	
	
	


func get_session_start():
	
	print("----------------------------")
	
	session_data["session_start_time"] = OS.get_time()
	session_data["session_date"] = OS.get_date()
	session_data["session_os_id"] = OS.get_unique_id()
	
	# system data
	session_data["os_language"] = OS.get_name()
	session_data["os_name"] = OS.get_locale_language()
	

	save_new_note()
	printt ("get_time", OS.get_time())
	printt ("get_date", OS.get_date())
	printt ("get_unique_id", OS.get_unique_id())
	printt ("get_name", OS.get_name())
	printt ("get_locale_language", OS.get_locale_language())
	printt ("session_id", session_data["session_id"])


# apdejtaš trenutno kolumno z zadnjimi podatki
func get_session_end():
	print("---")
	
	var session_length_hunds: float = OS.get_ticks_msec() / 10
	session_data["session_length"] = Global.get_clock_time(session_length_hunds)
	
	printt ("get_ticks_msec", OS.get_ticks_msec(), session_data["session_length"] )
	
	print("----------------------------")
	
	update_existing_note(int(session_data["session_id"]))
	
	

func save_new_session(note_id = "", table_id = "") -> void: # id se seta v tabeli
#func save_new_note(note_id = "", table_id = "") -> void: # id se seta v tabeli
	
	save_note(action_new_row)
	yield(self, "note_saved")
	fetch_notes_list()
		
func save_data_to_session():
	pass
	
	
# ----------------------------------------------------------------------------------------------------------
	
	
func refresh_note_list(note_id = "", table_id = "") -> void:
	
	fetch_notes_list()


func update_existing_note(note_id: int = -1, table_id = "") -> void:
	
	var selected_id = note_id
	if note_id == -1:
		selected_id = get_selected_note_id()
	
	print(selected_id)
	if selected_id != null:

		save_note(action_save_row, selected_id)
		yield(self, "note_saved")
		fetch_notes_list()
		

func delete_note(note_id = "", table_id = "") -> void:
	
	var selected_id = get_selected_note_id()
	if selected_id != null:
		
		delete_note_by_id(selected_id)
		yield(self, "note_deleted")
		fetch_notes_list()


func save_new_note(note_id = "", table_id = "") -> void: # id se seta v tabeli
	
	save_note(action_new_row)
	yield(self, "note_saved")
	fetch_notes_list()


func display_note_content(row_index: int) -> void:

	var selected_id = get_selected_note_id_from_index(row_index)
	if selected_id != null:
		fetch_notes_text(selected_id)


# MANAGE NOTES ---------------------------------------------------------------------------------------------


func fetch_notes_list() -> void:
	
	#	print("fetching on google api")
	make_http_get_request(action_fetch_list)


func fetch_notes_text(id: int) -> void:
	
	make_http_get_request(action_fetch_content, {"id": id}) # ta ID more bit ker je v sheet script akciji callback s takim imenom
	
	
func save_note(action: String, id = null) -> void: 
	#	printt("saving on google api (create_new_note)", action, id)
	
#	var note_data = {
#		column_title: title.text,
#		column_base_data: note_text.text,
#		column_data_1: note_tags.text
#	}	
	
	var note_data = {
		column_title: session_data["session_os_id"],
		column_base_data: session_data["session_date"],
		column_data_1: session_data["session_length"]
	}
	
	if id != null: # id rabim samo za apdejtat ... nov filet ID od gugla
		note_data[column_id] = id
		session_data["session_id"] = id
	
	make_http_post_request(action, note_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_done")
	emit_signal("note_saved") # v3
	#	print("note saved signal")


func delete_note_by_id(id: int) -> void:
	
	var note_data = {
		column_id: id 
	}
	
	make_http_post_request(action_delete_row, note_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_done")
	emit_signal("note_deleted") # v3


# UTILITY ---------------------------------------------------------------------------------------------


func get_selected_note_id():
	
	var selected_items = note_list.get_selected_items() # tale vrstica ugotavlja Id noteta v listi, popup lista ga poda avtomatično
	if selected_items.size() > 0:
		var item: String = note_list.get_item_text(selected_items[0])
		var id = item.split(":")[0].strip_edges()
		return int(id)
	return null


func get_selected_note_id_from_index(index: int) -> int:
	
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
	
	#	printt("http_POST_request (url, json)", url, json_data)
	
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	var headers = ["Content-Type: application/json"] # ["Content-Length: 0"]?
	request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)
	
	emit_signal("http_post_done") # v3
	#	print ("emit signal > http_post_done")
	
	
func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion
	# dobiš get data ali dobiš apdejtan post data 
	
	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result # v3
#		printt("json_result", json_result)
		
		# wrong aprouč > vlečem podatke za vsebino in samo listo notetov ... kar je kar zanimiv kombo
		if json_result:
			var data = json_result
			if typeof(data) == TYPE_ARRAY:
				note_list.clear()
				for note in data:
					note_list.add_item(str(note[column_id]) + ": " + str(note[column_title])) # str ... zazihs, če je številka
			else:
				# If it's not a list, it is note content , dont make like me , create proper separate functions , here i am just prototyping
				note_text.text = str(data[column_base_data])
				note_tags.text = str(data[column_data_1])
				title.text = str(data[column_title])
		
		else:
			print("JSON parse error")
	else:
#		print("Error with response code: ", response_code, result, body.get_string_from_utf8())
		print("---")
		print("Error with response code: ", response_code)
		
			
# BTNS ---------------------------------------------------------------------------------------------


func _on_UpdateBtn_pressed() -> void:
	
	update_existing_note()
	
		
func _on_RefreshBtn_pressed() -> void:
	
	refresh_note_list()


func _on_DeleteBtn_pressed() -> void:
	
	delete_note()


func _on_SaveBtn_pressed() -> void:
	
	save_new_note()


func _on_NoteList_item_selected(index: int) -> void:
	
	display_note_content(index)


func _on_EndBtn_pressed() -> void:
	pass # Replace with function body.

	get_session_end()


func _on_StartBtn_pressed() -> void:
	
	get_session_start()
