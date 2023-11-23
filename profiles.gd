extends Node


# STATS ---------------------------------------------------------------------------------------------------------

var default_player_stats: Dictionary = { # bo verjetno za vsak mode drugačen
	"player_name" : "Moe", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life" : 0, # se opredeli iz game_settings
	"player_energy" : 0, # se opredeli iz game_settings
	"player_points": 0,
	"colors_collected": 0,
	"skill_count" : 0,
	"burst_count" : 0,
	"cells_traveled" : 0,
}


var game_data_sprinter: Dictionary = { 
	"game": Games.SPRINTER,
	"tilemap_path": "res://game/tilemaps/test_tilemap.tscn",
	"game_time_limit": 600,
	"strays_start_count": 500,
}



# SETTINGS ---------------------------------------------------------------------------------------------------------


var game_settings: Dictionary = {
	# scoring
	"all_cleaned_points": 500,
	"color_picked_points": 10,
	"color_picked_energy": 20,
	"stacked_color_picked_points": 20,
	"stacked_color_picked_energy": 20,
	"cell_traveled_points": -1,
	"cell_traveled_energy": -1,
	"skill_used_points": 0,
	"skill_used_energy": 0,
	# player
	"player_start_life": 1, # če je samo en lajf, potem se ikone skrijejo v hudu
	"player_start_energy": 192, # GM
	"player_start_color": Color("#141414"),
	"step_time_fast": 0.09, # default hitrost
	"step_time_slow": 0.15, # minimalna hitrost
	"tired_energy_level": 20, # pokaže steps warning popup in hud oabrva rdeče
	"slowdown_mode": true, # hitrost je odvisna od energije
	"slowdown_rate": 18,
	# game
	"skilled_energy_drain_mode" : false,
	"skilled_energy_drain_speed": 0.1, # pavza predvsakim odvzemom točke
	"timer_mode_countdown" : true,
	"gameover_countdown_duration": 5,
	"suddent_death_mode": false,
	"sudden_death_limit" : 20,
	"lose_life_on_hit": false, # uskladi s količino lajfov
	"reset_energy_on_lose_life": true,
	"pick_neighbor_mode": false,
	"minimap_on": false,
	"start_countdown_on": true, # game_countdown
#	"skill_limit_mode": false,
#	"skill_limit_count": 5,
#	"burst_limit_mode": false,
#	"burst_limit_count": 5,
}


# GAMES ---------------------------------------------------------------------------------------------------------


enum Games {TUTORIAL, CLEANER_S, CLEANER_M, CLEANER_L, SPRINTER, DUEL}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"


var game_data_tutorial: Dictionary = { 
	"game": Games.TUTORIAL,
	"game_name": "Tutorial",
	"level": "",
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 3,
	"strays_start_count": 10,
}

var game_data_cleaner_S: Dictionary = { 
	"game": Games.CLEANER_S,
	"game_name": "Cleaner",
	"level": "S",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_S_tilemap.tscn",
	"game_time_limit": 120,
	"strays_start_count": 50, # se upošteva, če ni pozicij
	"highscore": 0, # more bit, da ga greba za med igro
}

var game_data_cleaner_M: Dictionary = {
	"game": Games.CLEANER_M,
	"game_name": "Cleaner",
	"level": "M",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_M_tilemap.tscn",
	"game_time_limit": 300,
	"strays_start_count": 140, 
	"highscore": 0,
}

var game_data_cleaner_L: Dictionary = {
	"game": Games.CLEANER_L,
	"game_name": "Cleaner",
	"level": "L",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_L_tilemap.tscn",
	"game_time_limit": 2,
	"strays_start_count": 320, 
	"highscore": 0,
}

var game_data_duel: Dictionary = {
	"game": Games.DUEL,
	"game_name": "The Duel",
	"level": "",
	"tilemap_path": "res://game/tilemaps/duel_tilemap.tscn",
	"game_time_limit": 3,
	"strays_start_count": 200, 
	"highscore": 0,
}


func _ready() -> void:
	var current_game = Games.DUEL
	set_game_data(current_game)

func set_game_data(selected_game) -> void:
	
#	selected_game = Games.CLEANER_L
	# kar se spreminja more biti setano na vseh igrah
	match selected_game:
		Games.TUTORIAL:
			current_game_data = game_data_tutorial
			game_settings["player_start_life"] = 1
			game_settings["timer_mode_countdown"] = false
			game_settings["lose_life_on_hit"] = false
			game_settings["start_countdown_on"] = false
			game_settings["start_countdown_on"] = true
		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_S
			game_settings["player_start_life"] = 1
			game_settings["timer_mode_countdown"] = true
			game_settings["lose_life_on_hit"] = false
			game_settings["start_countdown_on"] = true
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_M
			game_settings["player_start_life"] = 1
			game_settings["timer_mode_countdown"] = true
			game_settings["lose_life_on_hit"] = false
			game_settings["start_countdown_on"] = true
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_L
			game_settings["player_start_life"] = 1
			game_settings["timer_mode_countdown"] = true
			game_settings["lose_life_on_hit"] = false
			game_settings["start_countdown_on"] = true
		Games.DUEL: 
			current_game_data = game_data_duel
			game_settings["player_start_life"] = 3
			game_settings["timer_mode_countdown"] = true
			game_settings["lose_life_on_hit"] = true
			game_settings["start_countdown_on"] = true
		


#var default_game_highscores: Dictionary = { # prazen slovar ... uporabi se ob kreiranju fileta ... uporabi ga Glo
## če id uporabim kot gole številke, se vseeno prebere kot string
#	"1": {"Nobody": 9,},
#	"2": {"Nobody": 8,},
#	"3": {"Nobody": 7,},
#	"4": {"Nobody": 6,},
#	"5": {"Nobody": 5,},
#	"6": {"Nobody": 4,},
#	"7": {"Nobody": 3,},
#	"8": {"Nobody": 2,},
#	"9": {"Nobody": 1,},
#}
