extends Node


## nastavitve v igri


# DEFAULT -----------------------------------------------------------------------------------


var game_color_schemes: Dictionary = {
	"default_color_scheme": { # default
		1: Color.black, # ne velja, ker greba iz spectrum slike
		2: Color.white,	# ne velja, ker greba iz spectrum slike
	},
	"color_scheme_1":{ 
		1: Color.white, # red
		2: Color.white, #yellow
	},
	"color_scheme_2":{ 
		1: Color("#f35b7f"), # red
		2: Color("#fef98b"), #yellow
	},
	"color_scheme_3":{
		1: Color("#f9aa71"), # orange
		2: Color("#fef98b"), # blue
	},
	"color_scheme_4":{
		1: Color("#fef98b"), #yellow
		2: Color("#5effa9"), # green
	},
	"color_scheme_5":{
		1: Color("#5effa9"), # green
		2: Color("#4b9fff"), # blue
	},
	"color_scheme_6":{
		1: Color("#74ffff"), # turkizna
		2: Color("#4b9fff"), # blue
	},
	"color_scheme_7":{
		1: Color("#4b9fff"), # blue
		2: Color("#ec80fb"), #purple
	},
	"color_scheme_8":{
		1: Color("#ec80fb"), # purple
		2: Color("#7053c2"), # viola
	},
	"color_scheme_9":{ 
		1: Color.magenta, # red
		2: Color.greenyellow, #yellow
	},	
#	"color_scheme_10":{ 
#		1: Color.magenta, # red
#		2: Color.greenyellow, #yellow
#	},
}

var current_color_scheme: Dictionary = game_color_schemes["default_color_scheme"]


var scrolling_levels_conditions: Dictionary = {
	1: {
		"lines_scroll_per_spawn_round": 10,
		"stages_per_level": 3,
		"color_scheme": game_color_schemes["color_scheme_1"],
		"scrolling_pause_time": 0.5, # ne sem bit manjšaq od stray stepa
		"strays_spawn_count": 32
	},
	2: {
		"lines_scroll_per_spawn_round": 9,
		"stages_per_level": 5,
		"color_scheme": game_color_schemes["color_scheme_2"],
		"scrolling_pause_time": 0.45,
		"strays_spawn_count": 32
	},
	3: {
		"lines_scroll_per_spawn_round": 8,
		"stages_per_level": 5,
		"color_scheme": game_color_schemes["color_scheme_3"],
		"scrolling_pause_time": 0.4,
		"strays_spawn_count": 32
	},
	4: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 20,
		"color_scheme": game_color_schemes["color_scheme_4"],
		"scrolling_pause_time": 0.4,
		"strays_spawn_count": 32
	},
	5: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["color_scheme_5"],
		"scrolling_pause_time": 0.4,
		"strays_spawn_count": 32
	},
	6: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["color_scheme_6"],
		"scrolling_pause_time": 0.4,
		"strays_spawn_count": 32
	},
	7: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["color_scheme_7"],
		"scrolling_pause_time": 0.4,
		"strays_spawn_count": 32
	},
	8: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["color_scheme_8"],
		"scrolling_pause_time": 0.5,
		"strays_spawn_count": 32
	},
	9: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["color_scheme_9"],
		"scrolling_pause_time": 0.5,
		"strays_spawn_count": 32
	},
	10: {
		"lines_scroll_per_spawn_round": 7,
		"stages_per_level": 30,
		"color_scheme": game_color_schemes["default_color_scheme"],
		"scrolling_pause_time": 0.5,
		"strays_spawn_count": 32
	},
}

var default_player_stats: Dictionary = {
	"player_name" : "Somebody", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life" : 0, # se opredeli iz game_settings
	"player_energy" : 0, # se opredeli iz game_settings
	"player_points": 0,
	"colors_collected": 0,
	"skill_count" : 0,
	"burst_count" : 0,
	"cells_traveled" : 0,
}

# done
var default_game_settings: Dictionary = { # default settings so tiste, ki so najbolj pogoste ... opisane v tutorialu
	# to so default CLEANER settings
	# scoring
	"all_cleaned_points": 1000,
	"color_picked_points": 1,
	"cell_traveled_points": 0,
	"skill_used_points": 0,
	"burst_released_points": 0,
	"on_hit_points_part": 2,
	# energija
	"color_picked_energy": 20,
	"cell_traveled_energy": -1,
	"skill_used_energy": 0,
	"burst_released_energy": 0,
	"on_hit_energy_part": 2, # delež porabe od trenutne energije
	# player on start
	"player_start_life": 3, # 1 lajf skrije ikone v hudu in določi "lose_life_on_hit"
	"player_start_energy": 192,
	"player_start_color": Color("#141414"),
	# player in game
	"player_max_energy": 192, # max energija
	"player_tired_energy": 20, # pokaže steps warning popup in hud oabrva rdeče
	"step_time_fast": 0.09, # default hitrost
	"step_time_slow": 0.15, # minimalna hitrost
	"step_slowdown_rate": 18, # delež energije
	"step_slowdown_mode": true,
	"lose_life_on_hit": true, # zadetek od igralca ali v steno pomeni izgubo življenja, alternativa je izguba energije
#	# skill limits
#	"skill_limit_mode": false,
#	"skill_limit_count": 5,
#	"burst_limit_mode": false,
#	"burst_limit_count": 5,

	# game
	"gameover_countdown_duration": 5,
	"timer_mode_countdown" : true, # če prišteva in je "game_time_limit" = 0, nima omejitve navzgor
#	
	"start_countdown": false,
	"minimap_on": false,
	"position_indicators_mode": true, # duel jih nima 
	"show_position_indicators_stray_count": 5,
	"suddent_death_mode": false,
	"sudden_death_limit" : 20,
	
#	# strays steping ... prenešeno v GM
##	"stray_step_mode": false,
#	"pause_time": 0.1, # random pavzo delim z random številom v obsegu ...
#	"random_pause_time_divider_range": 50, # obseg za random število ... večji je, bolj se vse premika
	"stray_step_time": 0.2,
#	"scrolling_pause_time": 0.5,
#	"scrolling_pause_time": 0.5,

#	"highscore_type": HighscoreTypes.HS_TIME,
	"manage_highscores": true,

	# odl	
	# "scrolling_mode": false,
	# "hit_player_points": 1000,
	# "start_players_count": 1, ... nastavim s tiletom v tilemapu # setano v home/play meniju 
	# "stacked_color_picked_points": 2,
	# "stacked_color_picked_energy": 10,
}


# GAMES ---------------------------------------------------------------------------------------------------------

enum Games {
#	INTRO, 
	DEBUG, 
#	SWEEPER_S, SWEEPER_M, SWEEPER_L,
	ERASER_S, ERASER_M, ERASER_L,
	CLEANER_S, CLEANER_M, CLEANER_L, CLEANER_DUEL
	HUNTER, SCROLLER,
	SPRINTER_S, SPRINTER_M, SPRINTER_L, SPRINTER_DUEL
	RUNNER,  RIDDLER,
	TUTORIAL,
	}

enum HighscoreTypes {NO_HS, HS_POINTS, HS_TIME_LOW, HS_TIME_HIGH} # vpliva

#var game_data_difolt: Dictionary = { 
#	"game": 0,
#	"highscore_type": 0,
#	"game_name": "",
#	"level": "",
#	"game_scene_path": "",
#	"tilemap_path": "",
#	"game_time_limit": 0,
#	"strays_start_count": 0, 
### >>>> HS se doda med igro
#}

# tudu

var game_data_eraser_S: Dictionary = { 
	"game": Games.ERASER_S,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "S",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser_S.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50,
}

var game_data_eraser_M: Dictionary = {
	"game": Games.ERASER_M,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "M",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser_M.tscn",
	"game_time_limit": 0,
	"strays_start_count": 140, 
}

var game_data_eraser_L: Dictionary = {
	"game": Games.ERASER_L,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "L",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser_L.tscn",
	"game_time_limit": 0,
	"strays_start_count": 320, 
}

var game_data_cleaner_S: Dictionary = {
	"game": Games.CLEANER_S,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner",
	"level": "S",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner.tscn",
	"game_time_limit": 60,
	"strays_start_count": 500, 
}

var game_data_cleaner_M: Dictionary = {
	"game": Games.CLEANER_M,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner",
	"level": "M",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner.tscn",
	"game_time_limit": 120,
	"strays_start_count": 500, 
}

var game_data_cleaner_L: Dictionary = {
	"game": Games.CLEANER_L,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner",
	"level": "L",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner.tscn",
	"game_time_limit": 300,
	"strays_start_count": 500, 
}

var game_data_cleaner_duel: Dictionary = {
	"game": Games.CLEANER_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "Cleaner",
	"level": "DUEL",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner_duel.tscn",
	"game_time_limit": 60,
	"strays_start_count": 320, 
}


var game_data_scroller: Dictionary = { 
	"game": Games.SCROLLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Scroller",
	"level": " ", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_scrolling.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_scrolling.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50,
	
}

var game_data_hunter: Dictionary = {
	"game": Games.HUNTER,
	"game_name": "Hunter",
	"level": "",
	"tilemap_path": "res://game/tilemaps/sprinter/sprinter_tilemap.tscn",
	"game_time_limit": 300,
	"strays_start_count": 320, 
}

var game_data_debug: Dictionary = { 
	"game": Games.DEBUG,
	"game_name": "Debug",
	"level": "",
	"tilemap_path": "res://game/tilemaps/debug_tilemap.tscn",
	"game_time_limit": 100,
	"strays_start_count": 10,
}

var game_data_runner: Dictionary = { 
	"game": Games.RUNNER,
	"game_name": "Runner",
	"level": "01",
	"tilemap_path": "res://game/tilemaps/runner_tilemap.tscn",
	"game_time_limit": 0, # če je 0 nima omejitve navzgor
	"strays_start_count": 10,
}

var game_data_riddler: Dictionary = { 
	"game": Games.RIDDLER,
	"game_name": "Riddled",
	"level": "01",
	"tilemap_path": "res://game/tilemaps/riddler/riddler_tilemap.tscn",
	"game_time_limit": 600,
	"strays_start_count": 10,
}

var game_data_tutorial: Dictionary = { 
	"game": Games.TUTORIAL,
	"game_name": "Tutorial",
	"level": "",
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 10,
}

# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"

func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var current_game = Games.ERASER_S
#	var current_game = Games.CLEANER_L
	var current_game = Games.CLEANER_DUEL
#	var current_game = Games.SCROLLER
##
###	var current_game = Games.DUEL
###	var current_game = Games.TUTORIAL
###	var current_game = Games.DEBUG
	set_game_data(current_game)
	
	pass
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	match selected_game:
		
		Games.DEBUG: # default nastavitve
			current_game_data = game_data_debug
			game_settings["player_start_life"] = 2
			game_settings["manage_highscores"] = false
			game_settings["start_countdown"] = false
			game_settings["position_indicators_mode"] = false 

		Games.ERASER_S: 
			current_game_data = game_data_eraser_S
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 0
			game_settings["color_picked_points"] = 0
		Games.ERASER_M: 
			current_game_data = game_data_eraser_M
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 0
			game_settings["color_picked_points"] = 0
		Games.ERASER_L: 
			current_game_data = game_data_eraser_L
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 0
			game_settings["color_picked_points"] = 0

		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_S
			game_settings["cell_traveled_energy"] = 0
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_M
			game_settings["cell_traveled_energy"] = 0
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_L
			game_settings["cell_traveled_energy"] = 0
		Games.CLEANER_DUEL: 
			current_game_data = game_data_cleaner_duel
			game_settings["position_indicators_mode"] = false 
			# debug
			game_settings["start_countdown"] = false

		Games.SCROLLER:
			current_game_data = game_data_scroller
			game_settings["cell_traveled_energy"] = 0
			game_settings["player_start_life"] = 1
			game_settings["player_start_color"] = Color.blue
			
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
			
			game_settings["stray_step_mode"] = true
			game_settings["position_indicators_mode"] = false 
			game_settings["step_slowdown_mode"] = false
			game_settings["manage_highscores"] = false
		Games.SCROLLER_DUEL:
			current_game_data = game_data_scroller
			game_settings["cell_traveled_energy"] = 0
			
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
			
			game_settings["stray_step_mode"] = true
			game_settings["position_indicators_mode"] = false 
			game_settings["step_slowdown_mode"] = false
			# game_settings["scrolling_mode"] = true
		
#		Games.SPRINTER_S: 
#			current_game_data = game_data_sprinter_S
#			game_settings["manage_highscores"] = true
#			game_settings["timer_mode_countdown"] = false
#		Games.SPRINTER_M: 
#			current_game_data = game_data_sprinter_M
#			game_settings["manage_highscores"] = true
#			game_settings["timer_mode_countdown"] = false
#		Games.SPRINTER_L: 
#			current_game_data = game_data_sprinter_L
#			game_settings["manage_highscores"] = true			
#			game_settings["timer_mode_countdown"] = false
#		Games.HUNTER:
#			current_game_data = game_data_hunter
#			game_settings["stray_step_mode"] = true
#			game_settings["step_slowdown_mode"] = false
#		Games.TUTORIAL:
#			current_game_data = game_data_tutorial
#			game_settings["timer_mode_countdown"] = false
#			game_settings["start_countdown"] = false

#			game_settings["step_slowdown_mode"] = false
#			game_settings["step_time_fast"] = 1.15
#			game_settings["stray_step_mode"] = true
#		Games.SCROLLER:
#			current_game_data = game_data_scroller
#			game_settings["player_start_life"] = 2
#			game_settings["manage_highscores"] = false
#			game_settings["start_countdown"] = false
#			game_settings["stray_step_mode"] = true
#			game_settings["scrolling_mode"] = true
#			game_settings["position_indicators_mode"] = false 
##			game_settings["step_slowdown_mode"] = false
##			game_settings["step_time_fast"] = 1.15
##			game_settings["stray_step_mode"] = true
#		Games.RUNNER: 
#			current_game_data = game_data_runner
#			game_settings["player_start_life"] = 3
#			game_settings["timer_mode_countdown"] = false
#			game_settings["cell_traveled_energy"] = 0
#		Games.RIDDLER: 
#			current_game_data = game_data_riddler
#			game_settings["cell_traveled_energy"] = 0



		
