extends Node


# STATS ---------------------------------------------------------------------------------------------------------


var default_level_highscores: Dictionary = { # prazen slovar ... uporabi se ob kreiranju fileta ... uporabi ga Glo
	"1": {"Prvi": 30,},
	"2": {"Drugi": 20,},
	"3": {"Tretji": 20,},
	"4": {"Četrti": 10,},
	"5": {"Peti": 9,},
	"6": {"Šesti": 8,},
	"7": {"Sedmi": 7,},
	"8": {"Osmi": 6,},
	"9": {"Deveti": 2,},
	"10": {"Deseti": 1,},
}


var default_player_stats : Dictionary = { # bo verjetno za vsak mode drugačen
	"player_name" : "Moe", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life" : 1,
	"player_points": 0,
	"player_energy" : 192, # max, da se lepo ujema s pixli (24
	"skills_used" : 0,
	"cells_travelled" : 0,
}

var default_level_stats : Dictionary = { # na štartu igre se tole duplicira in postane game stats
	"level_no" : 88,
	"game_time_limit" : 120, # sekund
	"death_mode_limit" : 20, # sekund
	"timer_countdown_mode" : true,
	"stray_pixels_count" : 50,
	"off_pixels_count" : 0,
	"highscore": 0000, # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
	"highscore_owner": "NNNNNNNNNN", # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
}


# GAMES ---------------------------------------------------------------------------------------------------------


enum GameModes {PROTOYPE, TRAINING, RUNNER, CLEANER, FINISHER}


# var game_rules_training: Dictionary = {
var game_rules: Dictionary = { # tole ne uporabljam v zadnji varianti
	"color_picked_points": 10,
	"color_picked_energy": 10,
	"additional_color_picked_points": 20,
	"additional_color_picked_energy": 20,
#	"cell_travelled_points": 0,
	"cell_travelled_energy": -1,
#	"skill_used_points": 0,
	"skill_used_energy": 0,
	"tired_energy_level" : 0.1, # procent cele energije
	
	# config ... ne vem če je vse za ta slovar?
	"pick_neighbour_mode": false,
	"deathmode_on": false,
	"last_breath_mode": true,
	"minimap_on": false,
	"energy_speed_mode": true, # premikanje ne porablja energije ... pogoj je v on_stat_change
#	"stray_energy_pull": true, 
#	"skills_in_row": false,
}


var game_rules_runner: Dictionary = {
	"color_picked_points": 10,
	"color_picked_energy": 10,
	"additional_color_picked_points": 20,
	"additional_color_picked_energy": 20,
	"cell_travelled_points": 0,
	"cell_travelled_energy": -1,
	"skill_used_points": 0,
	"skill_used_energy": 0,
	"tired_energy_level" : 0.1, # procent cele energije
}

var game_rules_cleaner: Dictionary = {
	"color_picked_points": 10,
	"color_picked_energy": 10,
	"additional_color_picked_points": 20,
	"additional_color_picked_energy": 20,
	"cell_travelled_points": 0,
	"cell_travelled_energy": -1,
	"skill_used_points": 0,
	"skill_used_energy": 0,
	"tired_energy_level" : 0.1, # procent cele energije
}

var game_rules_finisher: Dictionary = {
	"color_picked_points": 10,
	"color_picked_energy": 10,
	"additional_color_picked_points": 20,
	"additional_color_picked_energy": 20,
	"cell_travelled_points": 0,
	"cell_travelled_energy": -1,
	"skill_used_points": 0,
	"skill_used_energy": 0,
	"tired_energy_level" : 0.1, # procent cele energije
}
