extends CanvasLayer
# tukaj prebavimo vse morebitne inupte med tem igra čaka odgovor lootlockerja
# trenutno narejeno samo za HS točke ... apgrejd na bolj modularno zadevo in čas

signal connection_closed

var current_player_stats: Dictionary = {} # pošlje se iz aktivator nodeta

onready var http_request: HTTPRequest = $HTTPRequest

func _input(event: InputEvent) -> void:
	if visible:
		get_tree().set_input_as_handled() # kakršen koli input setamo kot da smo ga procesiral 
	# v nodetu nastavim propagate "stop" 
	
	
func _ready() -> void:
	hide()
	
	
# AUTHENTICATE
	
func open_and_connect(player_stats: Dictionary = {1: "empty dik"}):
	
	current_player_stats = player_stats
	LootLocker.player_name = current_player_stats["player_name"]
	$Label.text = "Connecting to server ..."
	show()
	yield(get_tree().create_timer(1), "timeout") # _temp
	LootLocker.authenticate_player()		
	
	
func on_connected(): # kliče ko je avtentikacija storjena
	
	$Label.text = "Player authentication successful."
	yield(get_tree().create_timer(1), "timeout") # _temp
	submit_new_higscore()

	
# SEND SCORE

func submit_new_higscore():
	
	$Label.text = "Sending your score ..."
	
	var player_name: String = current_player_stats["player_name"]
	var player_score = current_player_stats["player_points"]
	
	var url = "https://api.lootlocker.io/game/leaderboards/PAclassic/submit" # naslov do LL tabele ... samo ključ tabele se spreminja
	var header = ["Content-Type: application/json", "x-session-token: %s" % LootLocker.token]
	var method = HTTPClient.METHOD_POST
	var request_data = {
		"score": player_score,
		"member_id": LootLocker.player_id,
		#		"meta_data": player_name, # ne rabim
	}
	
	http_request.request(url, header,false, method, to_json(request_data)) 
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(http_request, "request_completed") # to_json(request_body

	yield(get_tree().create_timer(1), "timeout") # _temp
	emit_signal("connection_closed")
	hide()

