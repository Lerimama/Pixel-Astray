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

var game_rules: Dictionary = { # tole ne uporabljam v zadnji varianti
	
	"color_picked_points": 10, # GM
	"color_picked_energy": 20, # GM
	"additional_color_picked_points": 20, # GM
	"additional_color_picked_energy": 40, # GM
	"cell_travelled_points": -1, # GM
	"cell_travelled_energy": -1, # GM
	"skill_used_points": -1, # GM ... isto kot stepanje
	"skill_used_energy": -1, # GM
	"skilled_energy_drain": -1, # GM
	"wall_hit_points": -5, # GM
	"wall_hit_energy": -96, # GM
	"skilled_energy_drain_speed": 0.1, # GM ... čas med vsakim odvzemom
	"player_start_energy": 192, # GM
	"dead_time": 3, # GM
	"tired_energy" : 20, # player ... procent cele energije
	"min_player_alpha": 0.2, # player
	"player_max_energy": 192, # player .. max, da se lepo ujema s pixli (24)
	"max_step_time": 0.15, # player
	"min_step_time": 0.09, # player
	"burst_speed_addon": 12, # player ... dodatek hitrosti na cock_ghost
	
	# config ... ne vem če je vse za ta slovar?
	"pick_neighbour_mode": false, # hud, player
	"deathmode_on": true, # hud_game_timer
	"last_breath_mode": true, # player
	"minimap_on": false, # game
	"game_intro_on": false, # GM
	"game_countdown_on": false, # game_countdown
	"energy_speed_mode": true, # GM, player
	"energy_alpha_mode": true, # hud_game_timer
	"loose_life_on": true, # GM ... v tem primeru, ne izgubiš energije niti točk
	"revive_energy_reset": true,  # GM
	"stop_burst_mode": true,  # player
	"randomize_stray_spawning": false,  # GM
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
