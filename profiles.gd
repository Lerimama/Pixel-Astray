extends Node


# STATS ---------------------------------------------------------------------------------------------------------


var default_level_highscores: Dictionary = { # prazen slovar ... uporabi se ob kreiranju fileta ... uporabi ga Glo
# če id uporabim kot gole številke, se vseeno prebere kot string
	"1": {"Nobody": 9,},
	"2": {"Nobody": 8,},
	"3": {"Nobody": 7,},
	"4": {"Nobody": 6,},
	"5": {"Nobody": 5,},
	"6": {"Nobody": 4,},
	"7": {"Nobody": 3,},
	"8": {"Nobody": 2,},
	"9": {"Nobody": 1,},
}

var default_player_stats : Dictionary = { # bo verjetno za vsak mode drugačen
	"player_name" : "Moe", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life" : 1, # če je samo en lajf, potem se ikone skrijejo v hudu
	"player_points": 0,
	"player_energy" : 192, # tukaj določena je nepomembna, ker se jo na začetku opredeli iz gam settings
	"skill_count" : 0,
	"burst_count" : 0,
	"cells_travelled" : 0,
}


# === GAMES ===


enum Levels {TUTORIAL, PRACTICE, S, M, L, XL, XXL}

var level_data : Dictionary = { # na štartu igre se tole duplicira in postane game stats
	"level" : Levels.TUTORIAL,
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 600, # sekund
	"stray_pixels_count": 7, # premaknjeno na tilemap
	
	"off_pixels_count": 0,
	"highscore": 0000, # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
	"highscore_owner": "Nobody", # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
}

# na štartu se vrednosti injicirajo v "level_data"

var level_tutorial_data: Dictionary = { 
	"level": Levels.TUTORIAL,
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 0,
	"stray_pixels_count": 7,
}


var level_practice: Dictionary = { 
	"level": Levels.PRACTICE,
	"tilemap_path": "x",
#	"game_time_limit": 600,
#	"stray_pixels_count": 5,
}

var level_1_data: Dictionary = { 
	"level": Levels.S,
	"game_time_limit": 5,
#	"stray_pixels_count": 5,
}

var level_2_data: Dictionary = {
	"level": Levels.M,
	"game_time_limit": 5,
	"stray_pixels_count": 32, 
}

var level_3_data: Dictionary = {
	"level": Levels.L,
	"game_time_limit": 5,
	"stray_pixels_count": 140, 
}

var level_4_data: Dictionary = {
	"level": Levels.XL,
	"game_time_limit": 5,
	"stray_pixels_count": 230, 
}

var level_5_data: Dictionary = {
	"level": Levels.XXL,
	"game_time_limit": 5,
	"stray_pixels_count": 320, 
}


var game_rules: Dictionary = { # tole ne uporabljam v zadnji varianti
	
	"all_cleaned_points": 500, # GM
	"color_picked_points": 10, # GM
	"color_picked_energy": 20, # GM
	"additional_color_picked_points": 20, # GM
	"additional_color_picked_energy": 40, # GM
	"cell_travelled_points": -1, # GM
	"cell_travelled_energy": -1, # GM
	"skill_used_points": 0, # GM ... isto kot stepanje
	"skill_used_energy": 0, # GM
	"skilled_energy_drain": 0, # GM
	"wall_hit_points": 0, # GM
	"wall_hit_energy": -96, # GM
	"skilled_energy_drain_speed": 0.1, # GM ... čas med vsakim odvzemom
	"player_start_energy": 192, # GM
	"dead_time": 2, # GM
	"tired_energy": 32, # player ... procent cele energije
	"min_player_alpha": 0.2, # player
	"player_max_energy": 192, # player .. max, da se lepo ujema s pixli (24)
	"max_step_time": 0.15, # player
	"min_step_time": 0.09, # player
	"burst_speed_addon": 12, # player ... dodatek hitrosti na cock_ghost
	"gameover_countdown_duration": 5, # hud game timer
	"last_breath_loop_limit": 3, # cca 1 bit na sekundo
	"pixel_start_color": Color("#141414"),
	"death_mode_duration" : 20,
	
		
	# config ... ne vem če je vse za ta slovar?
	"timer_countdown_mode" : true,
	"pick_neighbour_mode": false, # hud, player
	"deathmode_on": false, # hud_game_timer
	"last_breath_mode": true, # player
	"minimap_on": false, # game
	"game_countdown_on": false, # game_countdown
	"energy_speed_mode": true, # GM, player
	"lose_life_on_wall": false, # GM ... v tem primeru, ne izgubiš energije niti točk
	"lose_life_on_energy": true, # GM ... v tem primeru, ne izgubiš energije niti točk
	"revive_energy_reset": true,  # GM
	"stop_burst_mode": true,  # player
	"skill_limit_mode": false,
	"skill_limit_count": 5,
	"burst_limit_mode": false,
	"burst_limit_count": 5,
}
