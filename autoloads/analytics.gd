extends Node2D


signal note_saved
signal note_deleted
signal http_post_done


# sheet data
var sheet_name: String = "data" # tab
var sheetbook_id: String = "1f7KK1JhCcN76GkxgkfcRJKXQwuALN50r9yYZQA6Wq2E" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbylJXgZ_PC_OLZc4TgCliwftiD-JIcwLmWk90_B2xZ4e2a5vsnPltUDH5M_R3tLe24T6Q/exec"

onready var note_title: LineEdit = $NoteTitle
onready var note_text: LineEdit = $NoteText
onready var title = $NoteTitle
onready var note_list: ItemList = $NoteList
onready var note_tags: LineEdit = $NoteTags


func _ready() -> void:
	
	fetch_notes_list()


func fetch_notes_list() -> void:
	
	make_http_get_request("fetch_notes_list")


func fetch_notes_text(id: int) -> void:
	
	make_http_get_request("fetch_notes_content", {"id": id})
	
	
func fetch_notes_tagz(id: int) -> void:
	
	make_http_get_request("fetch_notes_content", {"id": id})

	
func save_note(action: String, id = null) -> void: # id rabim samo za apdejtat ... nov filet ID od gugla
	var note_data = {
		"title": title.text,
		"text": note_text.text,
		"tagz": note_tags.text
	}
	if id != null:
		note_data["id"] = id
	
	make_http_post_request(action, note_data)
	yield(self, "http_post_done")
	emit_signal("note_saved") # v3


func delete_note_by_id(id: int) -> void:
	
	var note_data = {
		"id": id
	}
	
	make_http_post_request("delete_note", note_data)
	yield(self, "http_post_done")
	emit_signal("note_deleted") # v3
	

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
	request.request(url)
	# zakaj ni take oblike ... request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	

func make_http_post_request(endpoint: String, data: Dictionary) -> void: # Make a POST request to the API
	
	var url = app_url + "?action=" + endpoint
	var json_data = JSON.print(data) # v3 ... print nemasto strngify
	
	printt("http_post_request", url, json_data)
	
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	request.request(url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, json_data)
	
	emit_signal("http_post_done") # v3
	
	
	
func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion
	# dobiš get data ali dobiš apdejtan post data 
	
	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result # v3
		printt("json_result", json_result)
		
		# wrong aprouč > vlečem podatke za vsebino in samo listo notetov ... kar je kar zanimiv kombo
		if json_result:
			var data = json_result
			if typeof(data) == TYPE_ARRAY:
				note_list.clear()
				for note in data:
					note_list.add_item(str(note["id"]) + ": " + note["title"])
			else:
				# If it's not a list, it is note content , dont make like me , create proper separate functions , here i am just prototyping
				note_text.text = data["text"]
				note_tags.text = data["tagz"]
				title.text = data["title"]
		else:
			print("JSON parse error")
	else:
		print("Error with response code: ", response_code, result, body.get_string_from_utf8())
		
			
# BTNS ---------------------------------------------------------------------------------------------


func _on_UpdateBtn_pressed() -> void:
	
	var selected_id = get_selected_note_id()
	if selected_id != null:
		
		save_note("save_existing_note", selected_id)
		yield(self, "note_saved")
		fetch_notes_list()		
	
		
func _on_RefreshBtn_pressed() -> void:
	
	fetch_notes_list()


func _on_DeleteBtn_pressed() -> void:
	
	var selected_id = get_selected_note_id()
	if selected_id != null:
		
		delete_note_by_id(selected_id)
		yield(self, "note_deleted")
		fetch_notes_list()


func _on_SaveBtn_pressed() -> void:
	
	save_note("create_new_note")
	yield(self, "note_saved")
	fetch_notes_list()


func _on_NoteList_item_selected(index: int) -> void:
	
	var selected_id = get_selected_note_id_from_index(index)
	if selected_id != null:
		fetch_notes_text(selected_id)
