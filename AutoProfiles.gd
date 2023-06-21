extends Node





# PROFILES ---------------------------------------------------------------------------------------------------------


var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	"P1" : { # ključi bodo kasneje samo indexi
		"player_name" : "Moe",
		"player_color" : Config.color_blue, # color_yellow, color_green, color_red
		"controller_profile" : "ARROWS",
	},
}

# STATS ---------------------------------------------------------------------------------------------------------

var default_level_highscores: Dictionary = { 
# prazen slovar ... uporabi se ob kreiranju fileta ... uporabi ga Glo
	"1": {
		"P1": 60,
	},
	"2": {
		"P2": 50,
	},
	"3": {
		"P3": 40,
	},
	"4": {
		"P4": 30,
	},
	"5": {
		"P5": 1,
	},
}

var default_player_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"player_name" : "Moe Def",
	"player_active" : false, # zaenkrat ga v aktivnega setaš na pixlov ready
	"player_life" : 1,
	"player_points": 0,
	"player_energy" : 172, # max, da se lepo ujema s pixli
	"skills_used" : 0,
	"cells_travelled" : 0,
}

#var default_level_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
var default_game_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"level_no" : 88,
	"game_time" : 900, # sekund
	"stray_pixels_count" : 32,
	"off_pixels_count" : 0,
	"highscore": 0000, # se naloži ob štartu igre, zato, da te lahko opozori že med igro
	"highscore_owner": "NNNNNNNNNN" # se naloži ob štartu igre, zato, da te lahko opozori že med igro
}

enum GameModes {BASIC}

var game_rules : Dictionary = { # tole ne uporabljam v zadnji varianti
	"game_mode" : GameModes.BASIC,
#	"player_start_position" : Vector2(500, 500),
	"points_color_picked": 10,
	"points_skill_used": -3,
	"points_cell_travelled": -3,
	
	"energy_color_picked": 20,
	"energy_skill_used": -1,
	"energy_cell_travelled": -1,
}

#enum Levels {FIRST, SQUARE, CIRCLE, TRIANGLE
#}
#
#var default_level_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
#	Levels.FIRST: {
##		"player_start_position" : Vector2(0, 0),
#		"game_time" : 5,
#		"level" : 0,
#		"stray_pixels_count" : 32,
#	}
#}

