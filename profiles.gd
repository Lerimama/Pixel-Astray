extends Node


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
	"player_start_life": 3, # 1 lajf skrije ikone v hudu
	"player_start_color": Global.color_dark_gray_pixel, # na začetku je bel, potem se animira v start color ... #232323, #141414
	"step_time_fast": 0.09, # default hitrost
	"player_start_energy": 192,
	"step_slowdown_mode": true,
	"lose_life_on_hit": true, # alternativa je izguba energije na hit in samo en lajf
	"full_power_mode": false, # vedno destroja ves bulk, hitrost = max_cock_count
	# points
	"color_picked_points": 10, 
	"white_eliminated_points": 100, 
	"cleaned_reward_points": 1000,
	"reburst_reward_points": 0,
	"on_hit_points_part": 0, # delež izgubljenih ob zadetku stene
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	"on_hit_energy_part": 0.5,
	# reburst
	"reburst_mode": false,
	"reburst_count_limit": 0, # 0 je unlimited
	"reburst_reward_limit": 0, # 0 je brez nagrade
	"reburst_window_time": 0.3, # 0 je neomejen čas
	"reburst_hit_power": 1, # kolk jih destroya ... 0 gre po original pravilih moči, trenutno je 5 full power
	# strays
	"strays_start_count": 0, # ponekod se spawna vsaj 1
	"respawn_strays_on_cleaned": false,
	"respawn_wait_time": 1, # če je 0, respawn pa je aktiviran, je respawn na cleaned
	"respawn_strays_count": 0, # če je > 0, je respawn aktiviran
	"random_stray_to_white": false, # na že spawnanih ... in game torej
	"spawn_white_stray_part": 0.0, # procenti ... 0 v ne spawna nobenega
	# game
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"start_countdown": true,
	"position_indicators_on": true,
	"show_game_instructions": true,
	"show_solution_hint": false, # sweeper reštve
	"zoom_to_level_size": true,
	"level_popup_on": false,
	"game_track_index": 0, # default muska v igri
}


enum Games {
	TUTORIAL,
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

	
var game_data_tutorial: Dictionary = { 
	"game": Games.TUTORIAL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "Tutorial",
	"game_scene_path": "res://game/game_tutorial.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_tutorial.tscn",
}
var game_data_cleaner_s: Dictionary = { 
	"game": Games.CLEANER_S,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner S",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_s.tscn",
	"description" : "Rainbow rush! Clear the colors quickly before time slips away!",
	"Prop" : "[center]Time limited to 2 minutes",
}
var game_data_cleaner_m: Dictionary = {
	"game": Games.CLEANER_M,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_m.tscn",
	"description" : "Hue hysteria! Race the clock and clean up the color explosion!",
	"Prop" : "[center]Time limited to 5 minutes",
}
var game_data_cleaner_l: Dictionary = {
	"game": Games.CLEANER_L,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner L",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_l.tscn",
	"description" : "Color catastrophe! Clean up this vibrant mess before the clock runs out!",
	"Prop" : "[center]Time limited to 10 minutes",
}
var game_data_eraser: Dictionary = { 
	"game": Games.ERASER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Eraser",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser.tscn",
	"description" : "Keep those colors in check as they keep popping in!",
	"Prop": "[center]Score points and progress through different difficulty levels.",
	"Prop2" : "[center]Unlimited time. Unlimited levels.",
	#
	"level": 1, # pomeni, da je multilevel
	"level_goal_count": 30, # prvi level
	"level_goal_count_grow": 320, # prištejem najvišjemu rezultatu
	"strays_start_count_grow": 5, # prištejem
	"respawn_wait_time_factor": 0.7, # množim
	"respawn_strays_count_grow": 1, # prištejem
	# ne rabim pri tej igri
	"spawn_white_stray_part_factor": 0, # množim
}
var game_data_handler: Dictionary = { 
	"game": Games.HANDLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Handler",
	"game_scene_path": "res://game/game.tscn",
	#	"tilemap_path": "res://game/tilemaps/tilemap_handler.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_handler_s.tscn",
	"description" : "Prevent those nasty white pixels from ruining your screen!",
	"Prop" : "[center]Clean up all colors and whites to progress through levels.",
	"Prop2" : "[center]Unlimited time. Unlimited levels.",
	"Prop3" : "[center]Use skills. Whites can only be destroyed if they are stacked.",
	#
	"level": 1, # pomeni, da je multilevel
	"spawn_white_stray_part_factor": 1, # množim
	"strays_start_count_grow": 32, # prištejem
	# ne rabim pri tej igri
	"respawn_wait_time_factor": 0, # množim
	"respawn_strays_count_grow": 5, # prištejem
	"level_goal_count": 320, # prvi
	"level_goal_count_grow": 320, # prištejem najvišjemu rezultatu
}
var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	"description" : "Team up to tackle the colored messa and battle for the ultimate cleaning champ title!",
	"Prop": "[center]Burst into opposing player to deal damage and get his share of points.",
	"Prop2" : "[center]Time is Limited to 3 minutes",
}
var game_data_defender: Dictionary = { 
	"game": Games.DEFENDER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Defender",
	"game_scene_path": "res://game/game_defender.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_defender.tscn",
	"description" : "Hold the line against the endless wave of colors!",
	"Prop": "[center]Collect invading colors and progress through unlimited difficulty levels.",
	"Prop2" : "[center]Energy and life dont matter.\nJust burst away ...",
	"Prop3" : "[center]Skills are not available.",
	#
	"level": 1, # pomeni, da je multilevel
		
	"stages_per_level": 32, # prvi level
	"stages_per_level_grow": 0, # dodatno prištejem
	"lines_scroll_per_spawn_round": 1, # na koliko stepov se spawna nova runda
	"invading_pause_time": 1.5, # ne sem bit manjša od stray step hitrosti (0.2)
	"invading_pause_time_factor": 0.8, # množim z vsakim levelom
	"stray_to_spawn_round_range": [1, 8], # random spawn count, največ 120 - 8
	"round_range_factor_1": 1, # množim spodnjo mejo
	"round_range_factor_2": 2, # množim zgornjo mejo
	"round_spawn_chance": 0.32, # delež
	"round_spawn_chance_factor": 1.2, # množim procente
}
var game_data_sweeper: Dictionary = {
	"game": Games.SWEEPER,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Sweeper",
	"game_scene_path": "res://game/game.tscn",
	"description" : "Sweep the entire screen in one spectacular\nburst move!",
	"Prop" : "[center]Launch the burst move with the initial hit and keep the momentum going with rebursting!",
	"Prop2" : "[center]Reburst after you hit the first stray pixel, by pressing the DIRECTION KEY in the next targets direction.",
	"Prop3" : "[center]Reburst always collects only one color.",
	"Prop4" : "[center]Reburst time window is 5 seconds.",
	#
	"level": 1, # pomeni, da je multilevel
}
var sweeper_level_setting: Dictionary = { 
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
var game_data_showcase: Dictionary = {
	"game": Games.SHOWCASE,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Showcase",
	"game_scene_path": "res://game/game_showcase.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_2.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_3.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_4.tscn",
	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_5.tscn",
}


# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary # = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var use_custom_color_theme: bool = false


func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var debug_game = Games.SHOWCASE
#	var debug_game = Games.TUTORIAL
#	var debug_game = Games.CLEANER_S
#	var debug_game = Games.CLEANER_M
#	var debug_game = Games.CLEANER_L
#	var debug_game = Games.DEFENDER
#	var debug_game = Games.ERASER
#	var debug_game = Games.HANDLER
#	var debug_game = Games.THE_DUEL
	var debug_game = Games.SWEEPER
	set_game_data(debug_game)
	
	# NEXT pregame instructions design in vsebinsko
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	# debug
#	game_settings["start_countdown"] = false
#	game_settings["player_start_life"] = 1
#	game_settings["show_game_instructions"] = false
		
	match selected_game:
		
		Games.SHOWCASE: 
			current_game_data = game_data_showcase
			game_settings["player_start_color"] = Color.white
			game_settings["reburst_hit_power"] = 1
			game_settings["reburst_mode"] = true			
			game_settings["reburst_window_time"] = 0
			game_settings["strays_start_count"] = 50
		
		Games.TUTORIAL: 
			current_game_data = game_data_tutorial
			game_settings["show_game_instructions"] = false
			game_settings["game_time_limit"] = 0
			game_settings["strays_start_count"] = 1
			game_settings["lose_life_on_hit"] = false
			game_settings["zoom_to_level_size"] = false
			game_settings["start_countdown"] = false
			
		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_s
			game_settings["game_time_limit"] = 120
			game_settings["strays_start_count"] = 50
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
			game_settings["respawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11 # 10 posto
			# debug
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_m
			game_settings["game_time_limit"] = 300
			game_settings["strays_start_count"] = 140
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
			game_settings["respawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_l
			game_settings["game_time_limit"] = 600
			game_settings["strays_start_count"] = 320
			game_settings["respawn_on_cleaned"] = true
			game_settings["zoom_to_level_size"] = false
			game_settings["respawn_strays_on_cleaned"] = true
			game_settings["spawn_white_stray_part"] = 0.11
		
		Games.ERASER: 
			current_game_data = game_data_eraser
			game_settings["cell_traveled_energy"] = 0
			game_settings["full_power_mode"] = true
			game_settings["position_indicators_on"] = false
			game_settings["start_countdown"] = false
			#
			game_settings["strays_start_count"] = 50
			game_settings["respawn_strays_count"] = 1
		
		Games.HANDLER: 
			current_game_data = game_data_handler
			game_settings["cell_traveled_energy"] = 0
			game_settings["full_power_mode"] = true
			game_settings["position_indicators_on"] = false
			game_settings["start_countdown"] = false
			#
			game_settings["strays_start_count"] = 3	
			game_settings["respawn_on_cleaned"] = true

		Games.DEFENDER:
			current_game_data = game_data_defender
			game_settings["lose_life_on_hit"] = false
			game_settings["on_hit_energy_part"] = 0
			game_settings["cell_traveled_energy"] = 0
			game_settings["position_indicators_on"] = false 
			game_settings["strays_start_count"] = 1 # 1 v prvi spawn rundi
			game_settings["full_power_mode"] = true
			# debug
#			game_settings["invading_pause_time"] = 0.3 # 1 v prvi spawn rundi
#			game_settings["stray_to_spawn_round_range"] = [20, 30] # 1 v prvi spawn rundi
			game_settings["game_track_index"] = 1
		
		Games.THE_DUEL: 
			current_game_data = game_data_the_duel
			game_settings["position_indicators_on"] = false 
#			game_settings["strays_start_count"] = 1 
			game_settings["game_time_limit"] = 0#180
			#	
			game_settings["respawn_strays_count"] = 20 
			game_settings["respawn_wait_time"] = 0
			game_settings["respawn_strays_on_cleaned"] = true
	
		Games.SWEEPER: 
			current_game_data = game_data_sweeper
			game_settings["player_start_life"] = 1
#			game_settings["player_start_color"] = Color.white
			game_settings["color_picked_points"] = 0
			game_settings["cell_traveled_energy"] = 0
			game_settings["cleaned_reward_points"] = 1 # ... izpiše se "SUCCESS!"
			game_settings["game_track_index"] = 1
			#
			game_settings["lose_life_on_hit"] = true
			game_settings["reburst_mode"] = true
			game_settings["reburst_window_time"] = 0
			game_settings["respawn_strays_count"] = 0
			game_settings["position_indicators_on"] = false
			# debug
			current_game_data["level"] = 8

