extends Node


## nastavitve v igri


# DEFAULT -----------------------------------------------------------------------------------


var game_color_schemes: Dictionary = {
	"default_color_scheme": { # default
		1: Color.black, # ne velja, ker greba iz spectrum slike
		2: Color.white,	# ne velja, ker greba iz spectrum slike
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
}

var current_color_scheme: Dictionary = game_color_schemes["default_color_scheme"]


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

var default_game_settings: Dictionary = { # default settings so tiste, ki so najbolj pogoste ... opisane v tutorialu
	# scoring
	"all_cleaned_points": 500,
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
	# timer
	"gameover_countdown_duration": 5,
	"timer_mode_countdown" : true, # če prišteva in je "game_time_limit" = 0, nima omejitve navzgor
	"start_countdown": true,
	# behaviour
	"step_slowdown_mode": true,
	"suddent_death_mode": false,
	"sudden_death_limit" : 20,
	"minimap_on": false,
	"manage_highscores": false,
	"lose_life_on_hit": true, # zadetek od igralca ali v steno pomeni izgubo življenja, alternativa je izguba energije
	# position indikatorji
	"position_indicators_mode": true, # duel jih nima
	"show_position_indicators_stray_count": 3,
	# skill limits
	"skill_limit_mode": false,
	"skill_limit_count": 5,
	"burst_limit_mode": false,
	"burst_limit_count": 5,
	# strays steping
	"stray_step_mode": false,
	"pause_time": 0.01, # pavzo delim z random številom v obsegu ...
	"random_pause_time_divider_range": 50, # obseg za random število ... večji je, bolj se vse premika
	"stray_step_time": 0.2,
	"scrolling_pause_time": 0.5,
	
	# "scrolling_mode": false,
	# "hit_player_points": 1000,
	# "start_players_count": 1, ... nastavim s tiletom v tilemapu # setano v home/play meniju 
	# "stacked_color_picked_points": 2,
	# "stacked_color_picked_energy": 10,
}


# GAMES ---------------------------------------------------------------------------------------------------------

enum Games {
	INTRO, 
	DEBUG, 
	TUTORIAL, CLEANER_S, CLEANER_M, CLEANER_L, 
	SPRINTER_S, SPRINTER_M, SPRINTER_L, DUEL,
	HUNTER, SCROLLER,
	RUNNER,  RIDDLER,
	}


var game_data_intro: Dictionary = { 
	"game": Games.INTRO,
	"game_name": "Intro",
	"level": "",
	"tilemap_path": "",
	#"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
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

var game_data_cleaner_S: Dictionary = { 
	"game": Games.CLEANER_S,
	"game_name": "Cleaner",
	"level": "S",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_S_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50, # se upošteva, če ni pozicij
}

var game_data_cleaner_M: Dictionary = {
	"game": Games.CLEANER_M,
	"game_name": "Cleaner",
	"level": "M",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_M_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 140, 
}

var game_data_cleaner_L: Dictionary = {
	"game": Games.CLEANER_L,
	"game_name": "Cleaner",
	"level": "L",
	"tilemap_path": "res://game/tilemaps/cleaner/cleaner_L_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 320, 
}

var game_data_sprinter_S: Dictionary = {
	"game": Games.SPRINTER_S,
	"game_name": "Sprinter",
	"level": "S",
	"tilemap_path": "res://game/tilemaps/sprinter/sprinter_tilemap.tscn",
	"game_time_limit": 120,
	"strays_start_count": 320, 
}

var game_data_sprinter_M: Dictionary = {
	"game": Games.SPRINTER_M,
	"game_name": "Sprinter",
	"level": "M",
	"tilemap_path": "res://game/tilemaps/sprinter/sprinter_tilemap.tscn",
	"game_time_limit": 300,
	"strays_start_count": 320, 
}

var game_data_sprinter_L: Dictionary = {
	"game": Games.SPRINTER_L,
	"game_name": "Sprinter",
	"level": "L",
	"tilemap_path": "res://game/tilemaps/sprinter/sprinter_tilemap.tscn",
	"game_time_limit": 600,
	"strays_start_count": 320, 
}

var game_data_duel: Dictionary = {
	"game": Games.DUEL,
	"game_name": "Sprinter",
	"level": "Duel",
	"tilemap_path": "res://game/tilemaps/sprinter/sprinter_tilemap_duel.tscn",
	"game_time_limit": 300,
	"strays_start_count": 320, 
}

var game_data_scroller: Dictionary = { 
	"game": Games.SCROLLER,
	"game_name": "Scroller",
	"level": "",
	"tilemap_path": "res://game/tilemaps/scrolling_tilemap.tscn",
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

# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"

func _ready() -> void:
	
#	var current_game = Games.DUEL # če greš iz menija je tole povoženo
#	var current_game = Games.TUTORIAL # če greš iz menija je tole povoženo
	var current_game = Games.CLEANER_L # če greš iz menija je tole povoženo
#	var current_game = Games.SCROLLER # če greš iz menija je tole povoženo
#	var current_game = Games.DEBUG # če greš iz menija je tole povoženo
	set_game_data(current_game)
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	match selected_game:
		Games.INTRO:
			current_game_data = game_data_intro
			game_settings["position_indicators_mode"] = false
		Games.TUTORIAL:
			current_game_data = game_data_tutorial
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_S
			# game_settings["manage_highscores"] = true
			game_settings["timer_mode_countdown"] = false
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_M
			# game_settings["manage_highscores"] = true
			game_settings["timer_mode_countdown"] = false
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_L
			# game_settings["manage_highscores"] = true			
			game_settings["timer_mode_countdown"] = false
		Games.SPRINTER_S: 
			current_game_data = game_data_sprinter_S
			game_settings["manage_highscores"] = true
			game_settings["timer_mode_countdown"] = false
		Games.SPRINTER_M: 
			current_game_data = game_data_sprinter_M
			game_settings["manage_highscores"] = true
			game_settings["timer_mode_countdown"] = false
		Games.SPRINTER_L: 
			current_game_data = game_data_sprinter_L
			game_settings["manage_highscores"] = true			
			game_settings["timer_mode_countdown"] = false
		Games.DUEL: 
			current_game_data = game_data_duel
			game_settings["lose_life_on_hit"] = true
			game_settings["position_indicators_mode"] = false 
		Games.SCROLLER:
			current_game_data = game_data_scroller
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
			game_settings["stray_step_mode"] = true
			game_settings["position_indicators_mode"] = false 
			game_settings["step_slowdown_mode"] = false
			# game_settings["scrolling_mode"] = true
		Games.HUNTER:
			current_game_data = game_data_hunter
			game_settings["stray_step_mode"] = true
			game_settings["step_slowdown_mode"] = false
		Games.DEBUG: # default nastavitve
			current_game_data = game_data_debug
			game_settings["player_start_life"] = 2
			game_settings["manage_highscores"] = false
			game_settings["start_countdown"] = false
			game_settings["position_indicators_mode"] = false 
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



		
