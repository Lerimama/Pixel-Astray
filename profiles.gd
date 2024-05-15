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
	"player_start_color": Color("#323232"), # na začetku je bel, potem se animira v start color ... #232323, #141414
	"step_time_fast": 0.09, # default hitrost
	"player_start_energy": 192,
	"step_slowdown_mode": true,
	"lose_life_on_hit": true, # alternativa je izguba energije na hit in samo en lajf
	"full_power_mode": false, # vedno destroja ves bulk, hitrost = max_cock_count
	# points
	"cleaned_reward_points": 1000,
	"reburst_reward_points": 100,
	"color_picked_points": 10, 
	"on_hit_points_div": 0,
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	"on_hit_energy_div": 2, # delež porabe od trenutne energije
	# reburst
	"reburst_mode": false,
	"reburst_count_limit": 0, # 0 je unlimited
	"reburst_reward_limit": 0, # 0 je brez nagrade
	"reburst_window_time": 0.3, # 0 je neomejen čas
	"reburst_hit_power": 1, # kolk jih destroya ... 0 gre po original pravilih moči, trenutno je 5 full power
	# strays
	"strays_start_count": 0, # ponekod se spawna vsaj 1
	"respawn_wait_time": 1, # če je 0, se respawn zgodi na cleaned
	"respawn_strays_count": 0, # če je 0, se je respawn off
	"random_stray_to_wall": false,
	"stray_wall_spawn_possibilty": 0,
	# game
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"start_countdown": true,
	"spectrum_start_on": true, # a pobrane prižigam al ugašam ... na scrollerja ne deluje
	"game_instructions_popup": true,
	"show_solution_hint": false, # riddler reštve
	"zoom_to_level_size": false,
}


enum Games {
	TUTORIAL,
	CLASSIC_S, CLASSIC_M, CLASSIC_L,
	POPPER, CLEANER_M,
	THE_DUEL,
	RIDDLER,
	SCROLLER,
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
var game_data_classic_s: Dictionary = { 
	"game": Games.CLASSIC_S,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Classic S",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_classic_s.tscn",
	"description" : "Collect all colors in limited time.",
	"Label": "[center][b]Limitations[/b]\nIf you lose all life and energy.",
	"Label2" : "[center][b]Skills[/b]\nRebursting is not available.",
	"Label3" : "[center][b]Time[/b]\nLimited to 2 minutes",
}
var game_data_classic_m: Dictionary = {
	"game": Games.CLASSIC_M,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Classic M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_classic_m.tscn",
	"description" : "Collect all colors in limited time.",
	"Label": "[center][b]Game Over[/b]\nIf you lose all life and energy.",
	"Label2" : "[center][b]Skills[/b]\nRebursting is not available.",
	"Label3" : "[center][b]Time[/b]\nLimited to 5 minutes",
}
var game_data_classic_l: Dictionary = {
	"game": Games.CLASSIC_L,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Classic L",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_classic_l.tscn",
	"description" : "Collect all colors in limited time.",
	"Label": "[center][b]Game Over[/b]\nIf you lose all life and energy.",
	"Label2" : "[center][b]Skills[/b]\nRebursting is not available.",
	"Label3" : "[center][b]Time[/b]\nLimited to 10 minutes",
}
var game_data_popper: Dictionary = { 
	"game": Games.POPPER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Poppers",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_popper.tscn",
	"description" : "Score points or clean the screen to reach next level.",
	"Label": "[center][b]Game Over[/b]\nif you lose all life or if screen is full of colors.",
	"Label2" : "[center][b]Skills[/b]\nRebursting is not available.",
	"Label3" : "[center][b]Time[/b]\nUnlimited levels. Unlimited time. Game is unbeatable.",
	"Label4" : "[center][b]Energy[/b]\nDon't worry about energy.",
	#
	"respawn_wait_time_factor": 0.7, # množim
	"respawn_strays_count_grow": 1, # prištejem
	"level_points_goal": 30, # prvi level
	"level_points_goal_grow": 320, # prištejem najvišjemu rezultatu
	"level_strays_spawn_count_grow": 5, # prištejem
}
var game_data_cleaner_m: Dictionary = { 
	"game": Games.CLEANER_M,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_m.tscn",
	"description" : "Score points or clean the screen to reach next level.",
	"Label2" : "[center][b]Skills[/b]\nRebursting is not available.",
	"Label3" : "[center][b]Time[/b]\nUnlimited levels. Unlimited time. Game is unbeatable.",
	"Label4" : "[center][b]Energy[/b]\nDon't worry about energy.",
	#
	"respawn_wait_time_factor": 0.7, # množim
	"respawn_strays_count_grow": 1, # prištejem
	"level_points_goal": 320, # prvi
	"level_points_goal_grow": 320, # prištejem najvišjemu rezultatu
	"level_strays_spawn_count_grow": 32, # prištejem
}
var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	"description" : "Surviving player or player with higher score wins.",
	"Label": "[center][b]Game Over[/b]\nIf one of the players loses all life.",
	"Label2" : "[center][b]Time[/b]\nLimited to 2 minutes",
	"Label3" : "[center][b]Skills[/b]\nRebursting is not available.",
}
var game_data_scroller: Dictionary = { 
	"game": Games.SCROLLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Defender",
	"game_scene_path": "res://game/game_scrolling.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_scrolling.tscn",
	"description" : "Prevent invading colors from flooding the screen.",
	"Label": "[center][b]Game Over[/b]\nIf player is surrounded or when there is no room for colors to invade.",
	"Label2" : "[center][b]Burst[/b] \nAlways collects all colors in stack.",
	"Label3" : "[center][b]Skills[/b] \nSkills are not available.",
	"Label4" : "[center][b]Energy[/b]\nDon't worry about energy.",
	#
	"stages_per_level": 2, # prvi level
	"stages_per_level_grow": 0, # dodatno prištejem
	"lines_scroll_per_spawn_round": 1, # na koliko stepov se spawna nova runda
	"scrolling_pause_time": 1.5, # ne sem bit manjša od stray step hitrosti (0.2)
	"scrolling_pause_time_factor": 0.8, # množim z vsakim levelom
	"stray_to_spawn_round_range": [1, 8], # random spawn count, največ 120 - 8
	"round_range_factor_1": 1, # množim spodnjo mejo
	"round_range_factor_2": 2, # množim zgornjo mejo
	"round_spawn_possibility": 32, # procenti
	"round_spawn_possibility_factor": 1.2, # množim procente
}
var game_data_riddler: Dictionary = {
	"game": Games.RIDDLER,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Riddler",
	"game_scene_path": "res://game/game.tscn",
	#
	"description" : "Collect all available colors with a single burst move.",
	"Prop" : "[center][b]Burst move[/b]\nStarts on first color hit and continues through all following reburst.",
	"Prop2" : "[center]Burst can collect all colors in stack. Reburst always collects only color.",
	"Prop3" : "[center]Burst can collect all colors in stack. Reburst always collects only color.",
}

var riddler_level_setting: Dictionary = { 
	1: { # ključ je tudi številka levela
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_01.tscn",
		"level_description": "Description ...", # pre-game instructions
	},
	2: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_02.tscn",
		"level_description": "Description ...",
	},
	3: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_03.tscn",
		"level_description": "Description ...",
	},
	4: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_04.tscn",
		"level_description": "Description ...",
	},
	5: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_05.tscn",
		"level_description": "Description ...",
	},
	6: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_06.tscn",
		"level_description": "Description ...",
	},
	7: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_07.tscn",
		"level_description": "Description ...",
	},
	8: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_08.tscn",
		"level_description": "Description ...",
	},
	9: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_09.tscn",
		"level_description": "Description ...",
	},
	
	10: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_S.tscn",
		"level_description": "Description ...",
	},
	11: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_M.tscn",
		"level_description": "Description ...",
	},
	12: {
		"tilemap_path": "res://game/tilemaps/riddler/tilemap_riddler_L.tscn",
		"level_description": "Description ...",
	},
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
#	var debug_game = Games.CLASSIC_S
#	var debug_game = Games.CLASSIC_M
#	var debug_game = Games.CLASSIC_L
#	var debug_game = Games.SCROLLER
	var debug_game = Games.POPPER
#	var debug_game = Games.CLEANER_M
#	var debug_game = Games.THE_DUEL
#	var debug_game = Games.RIDDLER
	set_game_data(debug_game)
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	# debug
#	game_settings["game_instructions_popup"] = false
	game_settings["start_countdown"] = false
		
	match selected_game:
		
		Games.SHOWCASE: 
			current_game_data = game_data_showcase
			game_settings["respawn_strays_count"] = 0
			game_settings["reburst_mode"] = true
			game_settings["player_start_color"] = Color.white
			game_settings["reburst_hit_power"] = 1
			game_settings["reburst_mode"] = true			
			game_settings["reburst_window_time"] = 0
			game_settings["strays_start_count"] = 50
		
		Games.TUTORIAL: 
			current_game_data = game_data_tutorial
			game_settings["game_instructions_popup"] = false
			game_settings["game_time_limit"] = 600
			game_settings["respawn_strays_count"] = 0
			game_settings["lose_life_on_hit"] = false
			game_settings["reburst_mode"] = true
		
		Games.CLASSIC_S: 
			current_game_data = game_data_classic_s
			game_settings["game_time_limit"] = 120
			game_settings["strays_start_count"] = 1
			game_settings["respawn_wait_time"] = 0
			game_settings["respawn_strays_count"] = 5
		Games.CLASSIC_M: 
			current_game_data = game_data_classic_m
			game_settings["game_time_limit"] = 300
			game_settings["strays_start_count"] = 140
			game_settings["respawn_strays_count"] = 0
		Games.CLASSIC_L: 
			current_game_data = game_data_classic_l
			game_settings["game_time_limit"] = 600
			game_settings["strays_start_count"] = 320
			game_settings["respawn_strays_count"] = 0
		
		Games.POPPER: 
			current_game_data = game_data_popper
			game_settings["on_hit_points_div"] = 0
			game_settings["cell_traveled_energy"] = 0
			#
			game_settings["reburst_mode"] = true
			game_settings["full_power_mode"] = true
			game_settings["position_indicators_on"] = false
			game_settings["start_countdown"] = false
			#
			game_settings["zoom_to_level_size"] = true
			game_settings["strays_start_count"] = 50
			game_settings["respawn_strays_count"] = 1
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_m
			game_settings["on_hit_points_div"] = 0
			game_settings["cell_traveled_energy"] = 0
			#
			game_settings["reburst_mode"] = true
			game_settings["full_power_mode"] = true
			game_settings["position_indicators_on"] = false
			game_settings["start_countdown"] = false
			#
			game_settings["zoom_to_level_size"] = true
			game_settings["strays_start_count"] = 320			
			game_settings["random_stray_to_wall"] = true
#			game_settings["stray_wall_spawn_possibilty"] = 10

		Games.SCROLLER:
			current_game_data = game_data_scroller
			game_settings["lose_life_on_hit"] = false
			game_settings["on_hit_energy_div"] = 0
			game_settings["cell_traveled_energy"] = 0
			game_settings["position_indicators_on"] = false 
			game_settings["strays_start_count"] = 1 # 1 v prvi spawn rundi
			game_settings["zoom_to_level_size"] = true
			# debug
#			game_settings["scrolling_pause_time"] = 0.3 # 1 v prvi spawn rundi
#			game_settings["stray_to_spawn_round_range"] = [20, 30] # 1 v prvi spawn rundi
		
		Games.THE_DUEL: 
			current_game_data = game_data_the_duel
			game_settings["position_indicators_on"] = false 
			game_settings["respawn_strays_count"] = 20 
			game_settings["game_time_limit"] = 60
			game_settings["strays_start_count"] = 100
			#	
			game_settings["respawn_wait_time"] = 10
			game_settings["respawn_strays_count"] = 3
			game_settings["zoom_to_level_size"] = true
	
		Games.RIDDLER: 
			current_game_data = game_data_riddler
			game_settings["player_start_life"] = 1
			game_settings["player_start_color"] = Color.white
			game_settings["color_picked_points"] = 0
			game_settings["cell_traveled_energy"] = 0
			game_settings["cleaned_reward_points"] = 1 # ... izpiše se "SUCCESS!"
			#
			game_settings["lose_life_on_hit"] = true
			game_settings["reburst_mode"] = true
			game_settings["reburst_window_time"] = 0
			game_settings["respawn_strays_count"] = 0
			game_settings["position_indicators_on"] = false
			game_settings["zoom_to_level_size"] = true
			# debug
			current_game_data["level"] = 1

