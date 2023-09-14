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
	"player_life" : 3,
	"player_points": 0,
	"player_energy" : 192, # tukaj določena je nepomembna, ker se jo na začetku opredeli iz gam settings
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
	
	# opiši kako kaj deluje
	
	"color_picked_points": 10,
	"color_picked_energy": 20,
	"additional_color_picked_points": 20,
	"additional_color_picked_energy": 40,
	"cell_travelled_points": -1,
	"cell_travelled_energy": -1,
	"skill_used_points": -1, # isto kot stepanje
	"skill_used_energy": -1,
	"tired_energy" : 20, # procent cele energije
	"skilled_energy_drain": -1,
	"skilled_energy_drain_speed": 0.1, # čas med vsakim odvzemom
	# config ... ne vem če je vse za ta slovar?
	"pick_neighbour_mode": false, # na hud.gd, player.gd
	"deathmode_on": true, # na hud_game_timer.gd
	"last_breath_mode": true, # na player.gd
	"minimap_on": false, # na game.gd
	"game_intro_on": true, # na GM
	"game_countdown_on": false, # na game_countdown.gd
	"energy_speed_mode": true, # na GM _on_stat_change, player.gd
	"energy_alpha_mode": false, # na hud_game_timer.gd
	"min_player_alpha": 0.2,
#	"stray_energy_pull": true, 
#	"skills_in_row": false,
#	"stop in burst"
	"wall_hit_points": -5,
	"wall_hit_energy": -96,
	"loose_life_on": true, # v tem primeru, ne izgubiš energije niti točk
	"revive_energy_reset": true,
	"player_max_energy": 192, # na player.gd .. max, da se lepo ujema s pixli (24)
	"player_start_energy": 192, # na GM
	# hitrost
	"max_step_time": 0.15, # na player.gd
	"min_step_time": 0.09, # na player.gd
	# energija
	"dead_time": 3,
	"skilled_energy_drain_on": true
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
