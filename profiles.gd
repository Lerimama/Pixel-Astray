extends Node


var get_it_time: float = 1 # tajming za dojet določene faze igre
var camera_shake_on: bool = true
var tutorial_music_track_index: int = 1

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
	"step_time_fast": 0.09, # default hitrost
	"player_start_energy": 192,
	"step_slowdown_mode": true,
	"full_power_mode": false, # vedno destroja ves stack, hitrost = max_cock_count
	# points
	"color_picked_points": 10, 
	"white_eliminated_points": 100, 
	"cleaned_reward_points": 1000,
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	# reburst
	"reburst_enabled": false,
	"reburst_window_time": 0.3, # 0 je neomejen čas
	"reburst_hit_power": 0, # kolk jih destroya ... 0 gre po original pravilih moči, trenutno je 5 full power
	# strays start spawn
	"strays_start_count": 0, # ponekod se spawna vsaj 1
	"spawn_white_stray_part": 0, # procenti spawnanih ... 0 ne spawna nobenega belega
	# strays in-game respawn
	"respawn_strays_count": 0, # če je > 0, je respawn aktiviran
	"respawn_pause_time": 1, # če je 0 lahko pride do errorja (se mi zdi, da n 0, se timer sam disejbla)
	"respawn_on_turn_white": false, # na respawn se naključni spremeni v belega
	# game
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"game_music_track_index": 0, # default muska v igri
	"spawn_strays_on_cleaned": false,
	"start_countdown": true,
	"zoom_to_level_size": true,
	"show_solution_hint": false, # sweeper reštve
	"tutorial_mode": true, # klasika
	"show_game_instructions": true,
	"position_indicators_show_limit": 5, # 1000 pomeni, da je prižgano skos, 0, da ni nikoli
}

enum Games {
	TUTORIAL, CLASSIC,
	CLEANER_S, CLEANER_M, CLEANER_L,
	ERASER, HANDLER,
	THE_DUEL,
	SWEEPER,
	DEFENDER,
	SHOWCASE,
	}
	
	
enum HighscoreTypes {
	NO_HS, 
	HS_POINTS, 
	HS_COLORS, 
	HS_TIME_LOW, 
	HS_TIME_HIGH
	}

	
var game_data_classic: Dictionary = { 
	"game": Games.CLASSIC,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Classic",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_classic.tscn",
	"description" : "Opis standardne avanture pucanja",
	"Prop" : "Klasika ...\nreclaim your\n\"one and only\"\nstatus.",
	"Prop2" : "Klasika ...",
	"Prop3" : "Score points\nto beat current\nrecord!",
}
var game_data_cleaner_s: Dictionary = { 
	"game": Games.CLEANER_S,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Cleaner S",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_s.tscn",
	"description" : "Clear the colors before time slips away!",
	"Prop" : "Clean quickly\nto reclaim your\n\"one and only\"\nstatus.",
	"Prop2" : "Cleaning time\nis limited to\n%s minutes." % str(2),
	"Prop3" : "Can you beat\nthe record time!",
}
var game_data_cleaner_m: Dictionary = {
	"game": Games.CLEANER_M,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Cleaner M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_m.tscn",
	"description" : "Race the clock and clean up the color explosion!",
	"Prop" : "Be quick and efficient to reclaim your \"one and only\" status.",
	"Prop2" : "Cleaning time\nis limited to\n%s minutes." % str(5),
	"Prop3" : "Can you beat\nthe record time!",
}
var game_data_cleaner_l: Dictionary = {
	"game": Games.CLEANER_L,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Cleaner L",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_l.tscn",
	"description" : "Clean up this vibrant mess before the clock runs out!",
	"Prop" : "Be quick and efficient to reclaim your \"one and only\" status.",
	"Prop2" : "Cleaning time is limited to %s minutes." % str(10),
	"Prop3" : "Can you beat\nthe record time!",
}
var game_data_eraser: Dictionary = { 
	"game": Games.ERASER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Eraser",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser.tscn",
	"description" : "Keep the colors in check as they keep popping in!",
	"Prop": "Unlimited\ncleaning time.\nUnlimited\ndifficulty levels.",
	"Prop2" : "No stubborn\nwhites on this\nscreen.",
	"Prop3" : "Score points\nto beat current\nrecord!",
	# štart
	"level": 1,
	"level_goal_count": 13,
	# "strays_start_count": 0, # določi tilemap
	# "respawn_strays_count": 5,
	# "respawn_pause_time": 1,
	# level up
	"level_goal_count_grow": 3,
	"strays_start_count_grow": 0,
	"respawn_strays_count_grow": 1,
	"respawn_pause_time_factor": 0.7,
	# ne rabim v tej igri
	"spawn_white_stray_part_factor": 1,
}
var game_data_handler: Dictionary = { 
	"game": Games.HANDLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Handler",
	"game_scene_path": "res://game/game.tscn",
	# "tilemap_path": "res://game/tilemaps/tilemap_handler.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_handler_s.tscn",
	"description" : "Prevent those pesky pixels from ruining your screen!",
	"Prop" : "Clean the screen\nto reach next\nchallenge.",
	"Prop2" : "Unlimited\ncleaning time.\nUnlimited\nchallenges.",
	"Prop3" : "Score points\nto beat current\nrecord!",
	# štart
	"level": 1,
	# "strays_start_count": 3, # določi settings
	# "spawn_white_stray_part": 0.0, # določi settings
	# level up
	"strays_start_count_grow": 32, # prištejem
	"spawn_white_stray_part_factor": 1, # množim
	# ne rabim v tej igri
#	"level_goal_count": 320,
#	"level_goal_count_grow": 320,
	"respawn_strays_count_grow": 0,
	"respawn_pause_time_factor": 1,
}
var game_data_defender: Dictionary = { 
	"game": Games.DEFENDER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Defender",
	"game_scene_path": "res://game/game_defender.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_defender.tscn",
	"description" : "Defend your screen against invading colors!",
	"Prop" : "Player is always\nfull of energy,\nbut has no skills.",
	"Prop2" : "Unlimited\ncleaning time.\nUnlimited\ndifficulty levels.",
	"Prop3" : "Score points\nto beat current\nrecord!",
	# štart
	"level": 1,
	"level_goal_count": 3, # prvi level
	"line_step_pause_time": 1.5, # ne sem bit manjša od stray step hitrosti (0.2), je clampana ob apliciranju
	"spawn_round_range": [1, 8], # random spawn count, največ 120 - 8
	"line_steps_per_spawn_round": 1, # na koliko stepov se spawna nova runda
	# level up
	"level_goal_count_grow": 320, # dodatno prištejem
	"line_step_pause_time_factor": 0.8, # množim z vsakim levelom
	"spawn_round_range_factor": [1, 1], # množim [spodnjo, zgornjo] mejo
	"line_steps_per_spawn_round_factor": 1, # na koliko stepov se spawna nova runda
}
var game_data_sweeper: Dictionary = {
	"game": Games.SWEEPER,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Sweeper",
	"game_scene_path": "res://game/game.tscn",
	"description" : "Sweep the entire screen in one spectacular move!",
	"Prop" : "Hit the first\nstray pixel and keep rebursting till there\nare none left.",
	"Prop2" : "To reburst when hitting a pixel, press\nin the direction of\nthe next target.",
	"Prop3" : "Showcase your\nmastery and beat\nthe record time!",
	#
	"level": 5, # provizorij
}
var sweeper_level_settings: Dictionary = { 
	1: { # ključ je tudi številka levela
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn",
	},
	2: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_02.tscn",
	},
	3: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_03.tscn",
	},
	4: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_04.tscn",
	},
	5: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_05.tscn",
	},
	6: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_06.tscn",
	},
	7: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_07.tscn",
	},
	8: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_08.tscn",
	},
	9: {
		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_09.tscn",
	},
	
	#	10: {
	#		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_S.tscn",
	#	},
	#	11: {
	#		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_M.tscn",
	#	},
	#	12: {
	#		"tilemap_path": "res://game/tilemaps/sweeper/tilemap_sweeper_L.tscn",
	#	},
}
var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	"description" : "Team up to tackle the colored mess and\nbattle for the ultimate cleaning champ title!",
	"Prop": " The player with better score wins.",
	"Prop2": "Hit the opposing player to take his life and get his share of points.",
	"Prop3" : "Battle time is limited to %s minutes." % str(3),
}
var game_data_showcase: Dictionary = {
	"game": Games.SHOWCASE,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Showcase",
#	"game_scene_path": "res://game/game_showcase.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_2.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_3.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_4.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_5.tscn",
}


# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary# = default_game_settings # = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var use_default_color_theme: bool = true


func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var debug_game = Games.SHOWCASE
#	var debug_game = Games.CLASSIC
#	var debug_game = Games.CLEANER_S
#	var debug_game = Games.CLEANER_M
#	var debug_game = Games.CLEANER_L
#	var debug_game = Games.DEFENDER
	var debug_game = Games.ERASER
#	var debug_game = Games.HANDLER
#	var debug_game = Games.SWEEPER
#	var debug_game = Games.THE_DUEL
	set_game_data(debug_game)
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
#	# debug
	game_settings["start_countdown"] = false
	game_settings["player_start_life"] = 2
	game_settings["show_game_instructions"] = false
		
	match selected_game:
		
		Games.SHOWCASE: 
			current_game_data = game_data_showcase.duplicate()
			game_settings["player_start_color"] = Color.white
			game_settings["reburst_hit_power"] = 1
			game_settings["reburst_enabled"] = true			
			game_settings["reburst_window_time"] = 0
			game_settings["strays_start_count"] = 50
		
		Games.CLASSIC: 
			current_game_data = game_data_classic.duplicate()
			game_settings["show_game_instructions"] = false
			game_settings["game_time_limit"] = 0
			game_settings["strays_start_count"] = 500
			
			game_settings["zoom_to_level_size"] = false
			game_settings["start_countdown"] = false
			
		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_s.duplicate()
			game_settings["game_time_limit"] = 120
			game_settings["strays_start_count"] = 50
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
#			game_settings["spawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11 # 10 posto
			# debug
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_m.duplicate()
			game_settings["game_time_limit"] = 300
			game_settings["strays_start_count"] = 140
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
#			game_settings["spawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_l.duplicate()
			game_settings["game_time_limit"] = 600
			game_settings["strays_start_count"] = 320
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
#			game_settings["spawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER: 
			current_game_data = game_data_eraser.duplicate()
#			game_settings["cell_traveled_energy"] = 0
			game_settings["start_countdown"] = false
			game_settings["strays_start_count"] = 5
			game_settings["strays_start_count"] = 5
			game_settings["respawn_strays_count"] = 1
			game_settings["respawn_pause_time"] = 1
		Games.HANDLER: 
			current_game_data = game_data_handler.duplicate()
#			game_settings["cell_traveled_energy"] = 0
			game_settings["start_countdown"] = false
			#
			game_settings["strays_start_count"] = 3	
			game_settings["respawn_on_cleaned"] = true

		Games.DEFENDER:
			current_game_data = game_data_defender.duplicate()
			game_settings["cell_traveled_energy"] = 0
			game_settings["full_power_mode"] = true # 1 v prvi spawn rundi
			game_settings["strays_start_count"] = 1 # 1 v prvi spawn rundi
			game_settings["position_indicators_show_limit"] = 0
			# debug
			game_settings["start_countdown"] = false # 1 v prvi spawn rundi
#			game_settings["line_step_pause_time"] = 0.3 # 1 v prvi spawn rundi
#			game_settings["spawn_round_range"] = [20, 30] # 1 v prvi spawn rundi
			game_settings["game_music_track_index"] = 1
		
		Games.THE_DUEL: 
			current_game_data = game_data_the_duel.duplicate()
			game_settings["game_time_limit"] = 0 #180
			#	
			game_settings["spawn_strays_on_cleaned"] = true
	
		Games.SWEEPER: 
			current_game_data = game_data_sweeper.duplicate()
			game_settings["player_start_life"] = 1
			game_settings["color_picked_points"] = 0
			game_settings["cell_traveled_energy"] = 0
			game_settings["cleaned_reward_points"] = 1 # ... izpiše se "SUCCESS!"
			game_settings["game_music_track_index"] = 1
			#
			game_settings["position_indicators_show_limit"] = 0
			game_settings["reburst_enabled"] = true
			game_settings["reburst_window_time"] = 0

