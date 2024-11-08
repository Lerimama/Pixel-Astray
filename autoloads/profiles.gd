extends Node


enum Games {CLEANER, ERASER_XS, ERASER_S, ERASER_M, ERASER_L, ERASER_XL, HUNTER, DEFENDER, SWEEPER, THE_DUEL, SHOWCASE}
enum HighscoreTypes {NONE, POINTS, TIME}

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

var default_game_settings: Dictionary = {
	# player
	"player_start_life": 3, # 1 lajf skrije ikone v hudu, on hit jemlje energijo ne lajfa
	"player_start_color": Global.color_dark_gray_pixel, # na začetku je bel, potem se animira v start color ... #232323, #141414
	"player_step_time": 0.09, # default hitrost
	"player_start_energy": 192,
	# points
	"color_picked_points": 10, 
	"white_eliminated_points": 100, 
	"cleaned_reward_points": 1000,
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	"on_hit_wall_energy_part": 0.5,
	# reburst
	"reburst_enabled": false,
	"reburst_hit_power": 1, # 0 gre po original pravilih moči, trenutno je 5 full power
	"reburst_window_time": 0.3, # 0 je neomejen čas
	"reburst_window_energy_drain": -2, # uporabljam namesto časa
	# strays
	"create_strays_count": 0,
	"spawn_white_stray_part": 0, # procenti spawnanih ... 0 ne spawna nobenega belega
	"spawn_white_stray_part_limit": 0.5, # klempam, da ni "brezveznih" situacij
	"respawn_strays_count_range": [0,0], # če je > 0, je respawn aktiviran
	"respawn_pause_time": 1, # če je 0 lahko pride do errorja (se mi zdi, da n 0, se timer sam disejbla)
	"respawn_pause_time_low": 1, # klempam navzdol na tole
	"stray_step_time": 0.5, # ne manjši od 0.2
	"throttled_stray_spawn": true,
	# game
	"burst_count_limit": 0, # če je nič, ni omejeno
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"game_music_track_index": 0, # default muska v igri
	"color_pool_colors_count": 500,
	"step_slowdown_mode": true,
	"full_power_mode": false, # vedno destroja ves stack, hitrost = max_cock_count
	"spawn_strays_on_cleaned": false,
	# gui
	"show_game_instructions": true,
	"position_indicators_show_limit": 10, # en manj je število vidnih
	"start_countdown": true,
	"zoom_to_level_size": false, # SHOWCASE
	"always_zoomed_in": false, # SWEEPER
}


# GAME DATA -----------------------------------------------------------------------------------

	
var game_data_cleaner: Dictionary = { 
	"game": Games.CLEANER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.POINTS,
	"game_name": "Cleaner",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner.tscn",
	# pre-game instructons
	"description": "Take back the colors and become the brightest again.",
	"Prop": "Clear all %s strays\nto reclaim your\none-and-only status." % str(500), # CON ročno povezano z game time
	"Prop2": "Give it your best shot\nto beat the current\nrecord score!",
}
var game_data_eraser_xs: Dictionary = { 
	"game": Games.ERASER_XS, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser XS",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_xs.tscn",
	# pre-game instructons
	"description" : "Clear the colors before time slips away!",
	"Prop" : "You have %s minute\nbefore your screen becomes\npermanently saturated." % str(2), # CON ročno povezano z game time
	"Prop2" : "Be quick and efficient\nto beat the current\nrecord time!",
	# 2min / 32 straysov
}
var game_data_eraser_s: Dictionary = { 
	"game": Games.ERASER_S, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser S",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_s.tscn",
	# pre-game instructons
	"description" : "Clear the colors before time slips away!",
	"Prop" : "You have %s minute\nbefore your screen becomes\npermanently saturated." % str(3), # CON ročno povezano z game time
	"Prop2" : "Be quick and efficient\nto beat the current\nrecord time!",
	# 5min / 50 straysov
}
var game_data_eraser_m: Dictionary = { 
	"game": Games.ERASER_M, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_m.tscn",
	# pre-game instructons
	"description" : "Clear the colors before time slips away!",
	"Prop" : "You have %s minutes\nbefore your screen becomes\npermanently saturated." % str(10), # CON ročno povezano z game time
	"Prop2" : "Be quick and efficient\nto beat the current\nrecord time!",
	# 7min / 100 straysov
}
var game_data_eraser_l: Dictionary = {
	"game": Games.ERASER_L, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser L",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_l.tscn",
	# pre-game instructons
	"description" : "Clear the colors before time slips away!",
	"Prop" : "You have %s minutes\nbefore your screen becomes\npermanently saturated." % str(15), # CON ročno povezano z game time
	"Prop2" : "Be quick and efficient\nto beat the current\nrecord time!",
	# 10min / 200 straysov
}
var game_data_eraser_xl: Dictionary = {
	"game": Games.ERASER_XL, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser XL",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_xl.tscn",
	# pre-game instructons
	"description" : "Clear the colors before time slips away!",
	"Prop" : "You have %s minutes\nbefore your screen becomes\npermanently saturated." % str(20), # CON ročno povezano z game time
	"Prop2" : "Be quick and efficient\nto beat the current\nrecord time!",
	# 15min / 300 straysov
}
var game_data_hunter: Dictionary = { 
	"game": Games.HUNTER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.POINTS,
	"game_name": "Hunter",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_stalker.tscn",
	# pre-game instructons
	"description" : "Keep the colors in check as they keep popping in!",
	"Prop": "Difficulty level will increase\nwhen your spectrum\nindicator gets filled.",
	"Prop2" : "Give it your best shot\nto beat the current\nrecord score!",
	# štart
	"level": 1,
	"level_goal_count": 1, # # CON level_goal_mode ... ročno povezano s številom spawnanih na tilemapu
	"level_goal_count_grow": 3,
	# "create_strays_count": 0, # določi tilemap
	"create_strays_count_grow": 0,
	# "respawn_strays_count_range": [2,8],
	"respawn_strays_count_range_grow": [1,1],
	# "respawn_pause_time": 3,
	"respawn_pause_time_factor": 0.80,
	# "spawn_white_stray_part": 0.21,
	"spawn_white_stray_part_grow": 0, # omejena na 2. level na set_new_level
}
var game_data_defender: Dictionary = { 
	"game": Games.DEFENDER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.POINTS,
	"game_name": "Defender",
	"game_scene_path": "res://game/game_defender.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_defender.tscn",
	# pre-game instructons
	"description" : "Defend your screen against invading colors!",
	"Prop" : "Player is always\nfull of energy,\nbut has no skills.",
	"Prop2": "Difficulty level will\nincrease when your\nspectrum indicator\ngets filled.",
	"Prop3" : "Give it your\nbest shot to\nbeat the current\nrecord score!",
	# štart
	"level": 1,
	"level_goal_count": 10, # CON kolikor jih spawnanih v prvi rundi
	"line_step_pause_time": 1.4, # ne sme bit manjša od stray step hitrosti (0.2), je clampana ob apliciranju
	"spawn_round_range": [1, 1], # random spawn count, največ 120 - 8
	"line_steps_per_spawn_round": 1, # na koliko stepov se spawna nova runda
	# level up
	"level_goal_count_grow": 100, # dodatno prištejem
	"line_step_pause_time_factor": 0.8, # množim z vsakim levelom
	"spawn_round_range_grow": [1, 1], # množim [spodnjo, zgornjo] mejo
	"line_steps_per_spawn_round_factor": 3, # na koliko stepov se spawna nova runda
}
var game_data_sweeper: Dictionary = {
	"game": Games.SWEEPER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Sweeper",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn",
	"description" : "Handle the colors to sweep the entire screen\nwith one spectacular cascading move!",
	# pre-game instructons
	"Prop": "To REBURST, press\nin the next target's\ndirection upon hitting\na stray pixel.",
	"Prop2": "You have\nonly a couple of\nseconds to keep\nyour momentum.",
	"Prop3": "Initial burst can\ncollect all stacked\ncolors. Reburst always\ncollects only one.",
	"level": 1,
}
var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.NONE,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	# pre-game instructons
	"description" : "Only the best cleaner will shine in this epic battle!",
	"Prop": "Player with better\nfinal score will be named\nthe Ultimate cleaning champ!",
	"Prop2": "Hit the opposing player\nto take his life and\nhalf of his points.",
}
var sweeper_level_tilemap_paths: Array = [ 
	# zaporedje je ključno za level name
	"res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_02.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_03.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_04.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_05.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_06.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_07.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_08.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_09.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_10.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_11.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_12.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_13.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_14.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_15.tscn",
	"res://game/tilemaps/sweeper/tilemap_sweeper_pixel_astray.tscn"
	]


# VARZ -----------------------------------------------------------------------------------


var game_settings: Dictionary
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var use_default_color_theme: bool = true
var get_it_time: float = 1 # tajming za dojet določene faze igre
var default_highscore_line_name: String = "10Characters" # se uporabi, če še ni nobenega v filetu

# nastavitve, ki se setajo tudi v home
var camera_shake_on: bool = true
var tutorial_music_track_index: int = 1
var tutorial_mode: bool = true
var throttler_msec_threshold: int = 5 # koliko msec je še na voljo v frejmu, ko raje premaknem na naslednji frame
var html5_mode: bool = false # skrije ExitGameBtn v home, GO in pavzi

# lootlocker
var lootlocker_game_key: String = "dev_5a1cab01df0641c0a5f76450761ce292"
var lootlocker_game_version: String = "0.92"
var lootlocker_development_mode: bool = false
var global_highscores_count: int = 99 # če bi blo več, ne paše na %02d 	 b 
var local_highscores_count: int = 10

	
func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var debug_game = Games.SHOWCASE # fix camera
	var debug_game = Games.CLEANER
#	var debug_game = Games.ERASER_XS
#	var debug_game = Games.ERASER_S
#	var debug_game = Games.ERASER_M
#	var debug_game = Games.ERASER_L
#	var debug_game = Games.ERASER_XL
#	var debug_game = Games.HUNTER
#	var debug_game = Games.DEFENDER
#	var debug_game = Games.SWEEPER
#	var debug_game = Games.THE_DUEL
	set_game_data(debug_game)
	
	
func set_game_data(selected_game):
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	# bugfixing
#	game_settings["start_countdown"] = false
#	game_settings["player_start_life"] = 2
#	game_settings["show_game_instructions"] = false

	match selected_game:

		Games.CLEANER: 
			current_game_data = game_data_cleaner.duplicate()
			game_settings["create_strays_count"] = 500 # spawna jih cca 1200 (tilemap setup)
		Games.ERASER_XS: 
			current_game_data = game_data_eraser_xs.duplicate()
			game_settings["game_time_limit"] = 120 
			game_settings["create_strays_count"] = 32
			game_settings["spawn_white_stray_part"] = 0.11 # 10 posto
		Games.ERASER_S: 
			current_game_data = game_data_eraser_s.duplicate()
			game_settings["game_time_limit"] = 300
			game_settings["create_strays_count"] = 50
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_M: 
			current_game_data = game_data_eraser_m.duplicate()
			game_settings["game_time_limit"] = 600
			game_settings["create_strays_count"] = 150
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_L: 
			current_game_data = game_data_eraser_l.duplicate()
			game_settings["game_time_limit"] = 900
			game_settings["create_strays_count"] = 300
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_XL: 
			current_game_data = game_data_eraser_xl.duplicate()
			game_settings["game_time_limit"] = 1200
			game_settings["create_strays_count"] = 400
			game_settings["spawn_white_stray_part"] = 0.11
		Games.HUNTER: 
			current_game_data = game_data_hunter.duplicate()
			game_settings["position_indicators_show_limit"] = 0
			#
			game_settings["respawn_strays_count_range"] = [2, 8]
			game_settings["respawn_pause_time"] = 3
			game_settings["spawn_white_stray_part"] = 0.32
		Games.DEFENDER:
			current_game_data = game_data_defender.duplicate()
			game_settings["cell_traveled_energy"] = 0
			game_settings["position_indicators_show_limit"] = 0
			game_settings["full_power_mode"] = true
			#
			game_settings["create_strays_count"] = 1 # število spawnanih v prvi rundi
		Games.SWEEPER: 
			current_game_data = game_data_sweeper.duplicate()
			game_settings["player_start_life"] = 1
			game_settings["player_start_color"] = Color.white
			game_settings["on_hit_wall_energy_part"] = 1
			game_settings["color_picked_points"] = 0
			game_settings["cell_traveled_energy"] = -2
			game_settings["cleaned_reward_points"] = 1 # ... izpiše se "SUCCESS!" # TEST
			game_settings["position_indicators_show_limit"] = 0
			game_settings["reburst_enabled"] = true
			game_settings["reburst_window_time"] = 13
			game_settings["burst_count_limit"] = 1
			#
			game_settings["throttled_stray_spawn"] = false
			game_settings["game_music_track_index"] = 1
			game_settings["always_zoomed_in"] = true # prižge se med prvo igro iz menija, tako ostane za zmerom zoomiran
			game_settings["show_game_instructions"] = false # prižge se samo za prvi gejm iz menija
			return game_settings # da lahko vklopim "instructions" in "zoomed in" za prehod iz home menija
		Games.THE_DUEL: 
			current_game_data = game_data_the_duel.duplicate()
			game_settings["game_time_limit"] = 180 # tilemap set
			game_settings["spawn_strays_on_cleaned"] = true
			game_settings["position_indicators_show_limit"] = 0
			game_settings["respawn_strays_count_range"] = [1, 14]
			game_settings["spawn_white_stray_part"] = 0.21
			
			
# SHOWCASE ----------------------------------------------------------------------------------------------------------------


#		Games.SHOWCASE: 
#			current_game_data = game_data_showcase.duplicate()
#			game_settings["create_strays_count"] = 180 # samo klasika in kapsula
#			game_settings["color_picked_points"] = 0
#			game_settings["cleaned_reward_points"] = 0
#			game_settings["white_eliminated_points"] = 0
#			game_settings["start_countdown"] = false
#			game_settings["show_game_instructions"] = false
#			game_settings["zoom_to_level_size"] = true
#			game_settings["cell_traveled_energy"] = 0		
#			game_settings["player_start_life"] = 5
#			# variacije	
#			# random stray step on start_game()
#			game_settings["player_start_color"] = Color.white
#			# camera_shake_on = false
#			# game_settings["reburst_enabled"] = true			
#			# game_settings["reburst_window_time"] = 0
#
#var game_data_showcase: Dictionary = {
#	"game": Games.SHOWCASE,
#	"highscore_type": HighscoreTypes.NONE,
#	"game_name": "Showcase",
#	#	"game_scene_path": "res://showcase/game_showcase.tscn",
#	#	"tilemap_path": "res://showcase/tilemap/tilemap_showcase_title.tscn",
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase.tscn", # klasika
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_sweeper.tscn", # reburts on, white start in belega
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_skills.tscn",
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_multicollect.tscn",
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_step.tscn",
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_waiting.tscn", # camera shake on, white start
#	#	"tilemap_path": "res://showcase/tilemaps/tilemap_showcase_capsule.tscn", # transparenca belih,  camera shake on, white start, stray spawn count
#	"description" : "Clean them all",
#	"Prop" : "Or not",
#	"Prop2" : "Or yes!",
#}
