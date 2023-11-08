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
	"player_life" : 0, # se opredeli iz game settings
	"player_energy" : 0, # se opredeli iz game settings
	"player_points": 0,
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
	"stray_pixels_count": 10, # premaknjeno na tilemap
	
	"off_pixels_count": 0,
	"highscore": 0000, # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
	"highscore_owner": "Nobody", # se naloži iz  "default_level_highscores" lestvice ob štartu igre, zato, da te lahko opozori že med igro
}

# na štartu se vrednosti injicirajo v "level_data"

var level_tutorial_data: Dictionary = { 
	"level": Levels.TUTORIAL,
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 0,
	"stray_pixels_count": 10,
}


var level_practice: Dictionary = { 
	"level": Levels.PRACTICE,
	"tilemap_path": "x",
	"game_time_limit": 600,
	"stray_pixels_count": 500,
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
	
	
	# player settings
	"player_start_life": 1, # če je samo en lajf, potem se ikone skrijejo v hudu
	"player_start_energy": 192, # GM
	"player_tired_energy": 32, # pokaže steps warning popup in hud oabrva rdeče
	"player_start_color": Color("#141414"),
	
	"last_breath_loop_limit": 3, # cca 1 bit na sekundo
	"dead_time": 2, # čas med izgubo lajfa in revive
	"burst_speed_addon": 12, # dodatek hitrosti na "cock" enoto
	
	# game settings
	"timer_mode_countdown" : true,
	"gameover_countdown_duration": 5,
	
	"suddent_death_mode": false,
	"sudden_death_limit" : 20,
	
	"speed_with_energy_mode": true, # hitrost je odvisna od energije
	"min_step_time": 0.09, # default hitrost
	"max_step_time": 0.15, # minimalna hitrost
	"speed_slowdown_rate": 18,
		
	"skill_limit_mode": false,
	"skill_limit_count": 5,
	
	"burst_limit_mode": false,
	"burst_limit_count": 5,
	
	"lose_life_on_wall": false,
	"pick_neighbour_mode": false,
	"minimap_on": false, # game
	
	# trenutno ni v rabi
	"last_breath_mode": true, # player
	"wall_hit_points": 0, # v gm je izbrana izguba polovice točk
	"wall_hit_energy": -96, # GM
	"min_player_alpha": 0.2, # player
	
	# obst?
#	"revive_energy_reset": true,  # GM
	"game_countdown_on": false, # game_countdown
#	"lose_life_on_energy": true, # GM ... v tem primeru, ne izgubiš energije niti točk
#	"stop_burst_mode": true,  # player
}
