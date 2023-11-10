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
	"cells_travelled" : 0,
}


# SETTINGS ---------------------------------------------------------------------------------------------------------


#var default_level_data: Dictionary = { # na štartu se napolne s podatki posameznega levela
#	"level" : Games.TUTORIAL,
#	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
#	"game_time_limit": 600, # sekund
#	"strays_start_count": 10, # premaknjeno na tilemap
#	"highscore": 0000, # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
#	"highscore_owner": "Nobody", # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
#}

# na štartu se vrednosti injicirajo v "current_game_data"
enum Games {TUTORIAL, PRACTICE, S, M, L, XL, XXL}
var current_game_data: Dictionary

var game_data_tutorial: Dictionary = { 
	"game": Games.TUTORIAL,
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 10,
}

var game_data_practice: Dictionary = { 
	"game": Games.PRACTICE,
	"tilemap_path": "x",
	"game_time_limit": 600,
	"strays_start_count": 500,
}

var game_data_S: Dictionary = { 
	"game": Games.S,
	"game_time_limit": 5,
	"strays_start_count": 5, 
}

var game_data_M: Dictionary = {
	"game": Games.M,
	"game_time_limit": 5,
	"strays_start_count": 32, 
}

var game_data_L: Dictionary = {
	"game": Games.L,
	"game_time_limit": 5,
	"strays_start_count": 140, 
}

var game_data_XL: Dictionary = {
	"game": Games.XL,
	"game_time_limit": 5,
	"strays_start_count": 230, 
}

var game_data_XXL: Dictionary = {
	"game": Games.XXL,
	"game_time_limit": 5,
	"strays_start_count": 320, 
}

var player_settings: Dictionary = { 
	"start_life": 1, # če je samo en lajf, potem se ikone skrijejo v hudu
	"start_energy": 192, # GM
	"start_color": Color("#141414"),
	"step_time_fast": 0.09, # default hitrost
	"step_time_slow": 0.15, # minimalna hitrost
	"tired_energy": 20, # pokaže steps warning popup in hud oabrva rdeče
	"slowdown_mode": true, # hitrost je odvisna od energije
	"slowdown_rate": 18,
}

var game_settings: Dictionary = {
	# scoring
	"all_cleaned_points": 500,
	"color_picked_points": 10,
	"color_picked_energy": 20,
	"stacked_color_picked_points": 20,
	"stacked_color_picked_energy": 20,
	"cell_travelled_points": -1,
	"cell_travelled_energy": -1,
	"skill_used_points": 0,
	"skill_used_energy": 0,
	"skilled_energy_drain": 0,
	"skilled_energy_drain_speed": 0.1, # čas med vsakim odvzemom
	# settings
	"timer_mode_countdown" : true,
	"gameover_countdown_duration": 5,
	"suddent_death_mode": false,
	"sudden_death_limit" : 20,
	"skill_limit_mode": false,
	"skill_limit_count": 5,
	"burst_limit_mode": false,
	"burst_limit_count": 5,
	"lose_life_on_wall": false,
	"pick_neighbour_mode": false,
	"minimap_on": false,
	"start_countdown_on": false, # game_countdown
}

var current_game = Games.PRACTICE

func _ready() -> void:
	match current_game:
		Games.TUTORIAL:
			current_game_data = game_data_tutorial
		Games.PRACTICE:
			current_game_data = game_data_practice

func set_game_data(selected_game) -> void:
	
	match selected_game:
		Games.TUTORIAL:
			current_game_data = game_data_tutorial
		Games.PRACTICE:
			current_game_data = game_data_practice
#			game_settings["start_countdown_on"] = true


#var default_level_highscores: Dictionary = { # prazen slovar ... uporabi se ob kreiranju fileta ... uporabi ga Glo
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
