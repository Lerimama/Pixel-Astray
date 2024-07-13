extends HTTPRequest

var board

func get_lootlocker_leaderboard():
	
	ConnectCover.start_connecting()
	
	var url = "https://api.lootlocker.io/game/leaderboards/PAclassic/list?count=10" #koliko mest rabimo
#	var url = "https://api.lootlocker.io/game/leaderboards/testpoints/list?count=10" #koliko mest rabimo
	var header = ["Content-Type: application/json", "x-session-token: %s" % LootLocker.token]
	var method = HTTPClient.METHOD_GET
	
	request(url, header, false, method) 
	# request(url, header,false, method, to_json(request_body)) 
	var response = yield(self, "request_completed")[3] # to_json(request_body
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key
	print(response)
	
	if "items" in response:
		board = response["items"]
	
	print(board)
	return board
