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


var default_game_settings: Dictionary = { # to so default CLEANING settings
	# player
	"player_start_life": 1, # 1 lajf skrije ikone v hudu in določi "lose_life_on_hit"
	"player_start_energy": 192, # če je 0, je 0 ... instant GO
#	"player_start_color": Color("#ffffff"), # Color("#232323"), Color("#141414"), # old #141414
	"player_start_color": Color("#141414"), # Color("#232323"), Color("#141414"), # old #141414
	"player_max_energy": 192, # max energija
	"player_tired_energy": 20, # pokaže steps warning popup in hud oabrva rdeče
	"step_time_fast": 0.09, # default hitrost
	"step_time_slow": 0.15, # minimalna hitrost
	"step_slowdown_rate": 18, # delež energije, manjši pada hitreje
	# scoring
	"all_cleaned_points": 1000,
	"color_picked_points": 10, 
	"cell_traveled_points": 0,
	"skill_used_points": 0,
	"burst_released_points": 0,
	"on_hit_points_part": 2,
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	"skill_used_energy": 0,
	"burst_released_energy": 0,
	"on_hit_energy_part": 2, # delež porabe od trenutne energije
	"touching_stray_energy": 0,
	# reburst
	"reburst_count_limit": 0, # 0 je unlimited
	"reburst_reward_limit": 0, # 0 je brez nagrade
	"reburst_reward_points": 100, # kolk jih destroya ... 0 gre po original pravilih moči
	"reburst_window_time": 0.2, # 0 je neomejen čas
	"reburst_hit_power": 1, # kolk jih destroya ... 0 gre po original pravilih moči, 5 je full power
	# game
	"respawn_mode": true,
	"respawn_wait_time": 1,
	"respawn_strays_count": 1,
	"reburst_mode": false,
	"timer_mode_countdown" : true, # če prišteva in je "game_time_limit" = 0, nima omejitve navzgor
	"lose_life_on_hit": false, # zadetek od igralca ali v steno pomeni izgubo življenja, alternativa je izguba energije
	"step_slowdown_mode": true,
	"eternal_mode": false,
	"turn_stray_to_wall": true, # eternal big screen
	"full_power_mode": false, # hitrost je tudi max_cock_coiunt > vedno destroja ves bulk 
	# gui
	"gameover_countdown_duration": 5,
	"show_position_indicators_stray_count": 5,
	"position_indicators_on": true, # duel jih nima 
	"spectrum_start_on": false, # a pobrane prižigam al ugašam
	"zoom_animation": true,
	"start_countdown": false,
	"game_instructions_popup": true,
	"solutions_mode": false, # enigma reštve
	# neu
	"game_time_limit": 0,
	"strays_start_count": 0, # ponekod se spawna vsaj 1
}


enum Games {
	TUTORIAL,
	ERASER_S, ERASER_M, ERASER_L,
	CLEANER_S, CLEANER_M, CLEANER_L,
	THE_DUEL,
	ENIGMA,
	SCROLLER,
	TESTING,
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
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_tutorial.tscn",
}
var game_data_eraser_s: Dictionary = { 
	"game": Games.ERASER_S,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser S",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/eraser/tilemap_eraser_S.tscn",
	# instructions text
	"description" : "Collect all available colors.",
	"Label": "", # presledek
	"Label2": "Game is over when you lose all energy.",
	"Label3" : "Time is limited.",
	"Label4" : "Rebursting is not available.",
}
var game_data_eraser_m: Dictionary = {
	"game": Games.ERASER_M,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser M",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/eraser/tilemap_eraser_M.tscn",
	# instructions text
	"description" : "Collect all available colors.",
	"Label": "", # presledek
	"Label2": "Game is over when you lose all energy.",
	"Label3" : "Time is limited.",
	"Label4" : "Rebursting is not available.",
}
var game_data_eraser_l: Dictionary = {
	"game": Games.ERASER_L,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser L",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/eraser/tilemap_eraser_L.tscn",
	# instructions text
	"description" : "Collect all available colors.",
	"Label": "", # presledek
	"Label2": "Game is over when you lose all energy.",
	"Label3" : "Time is limited.",
	"Label4" : "Rebursting is not available.",
}
var game_data_cleaner_s: Dictionary = { 
	"game": Games.CLEANER_S,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner S",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_s.tscn",
	# instructions text
	"description" : "Collect points to progress through levels.",
	"Label": "Game is over when you lose all life or the screen is full of colors.",
	"Label2" : "Unlimited levels. Unlimited time. Game is unbeatable.",
	"Label3" : "Level progress on points scored or if screen is cleaned.",
	"Label4" : "Don't worry about energy.",
	# xtra
	# "level": 1, # se neafila kasneje
	"respawn_wait_time": 1,
	"respawn_wait_time_factor": 0.7, # množim z vsakim levelom
	"respawn_strays_count": 1,
	"respawn_strays_count_grow": 1, # prištejem z vsakim levelom
	"level_points_limit": 320, # vsak level prištejem k trenutnemu limitu levela
	"level_points_limit_grow": 10, # dodatno prištejem z vsakim levelom
	"level_strays_spawn_count_grow": 5, # prištejem z vsakim levelom
}
var game_data_cleaner_m: Dictionary = { 
	"game": Games.CLEANER_M,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner M",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_m.tscn",
	# instructions text
	"description" : "Collect points to progress through levels.",
	"Label": "Game is over when you lose all life or the screen is full of colors.",
	"Label2" : "Unlimited levels. Unlimited time. Game is unbeatable.",
	"Label3" : "Level progress on points scored or if screen is cleaned.",
	"Label4" : "Don't worry about energy.",
	# xtra
	# "level": 1, # se neafila kasneje
	"respawn_wait_time_factor": 0.7, # množim z vsakim levelom
	"respawn_strays_count_grow": 1, # prištejem z vsakim levelom
	"level_points_limit": 320, # vsak level prištejem k trenutnemu limitu levela
	"level_points_limit_grow": 10, # dodatno prištejem z vsakim levelom
	"level_strays_spawn_count_grow": 32, # prištejem z vsakim levelom
}
var game_data_cleaner_l: Dictionary = {
	"game": Games.CLEANER_L,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner L",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner_l.tscn",
	# instructions text
	"description" : "Collect colors to earn points.",
	"Label": "", # presledek
	"Label2": "Game is over when you lose all energy.",
	"Label3" : "One big level.",
	"Label4" : "Time is limited.",
}
var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	# instructions text
	"description" : "Surviving player or player with higher score wins.",
	"Label": "", # presledek
	"Label2": "Game is over when one of the players loses all life.",
	"Label3" : "Time is limited.",
	"Label4" : "Rebursting is not available.",
}
var game_data_scroller: Dictionary = { 
	"game": Games.SCROLLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Defender",
	"game_scene_path": "res://game/game_scrolling.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_scrolling.tscn",
	# instructions text
	"description" : "Collect colors to progress through levels.",
	"Label": "Game is over when first wall column reaches the top or you have no room to move.",
	"Label2" : "Burst always collects all colors in stack.",
	"Label3" : "Level progress on colors collected count or if screen is cleaned.",
	"Label4" : "Skills and rebursting are not available.",
	"Label5" : "Don't worry about energy.",
	# "level": 1, # level se nafila ob štartu
	"stages_per_level": 50, # vsak level prištejem k trenutnemu limitu levela
	"stages_per_level_grow": 10, # dodatno prištejem
	"lines_scroll_per_spawn_round": 1,
	# pavza med stepanjem
	"scrolling_pause_time": 1.0, # ne sem bit manjša od stray step hitrosti (0.2)
	"scrolling_pause_time_factor": 0.9, # množim z vsakim levelom
	# random spawn na rundo
	"stray_to_spawn_round_range": [15, 30], # random spawn count, največ 20
	"round_range_factor_1": 1, # množim spodnjo mejo
	"round_range_factor_2": 1, # množim zgornjo mejo
	# možnost spawna v rundi
	"round_spawn_possibility": 32, # procenti
	"round_spawn_possibility_factor": 1.2, # množim procente
}
var game_data_enigma: Dictionary = {
	"game": Games.ENIGMA,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Riddler",
	"game_scene_path": "res://game/game_cleaning.tscn",
	# instructions text
	"description" : "Collect all available colors with a single burst move.",
	"Label" : "Burst move includes initial burst and all rebursts that follow.",
	"Label2": "Burst move starts when you hit the first stray pixel.",
	"Label3" : "Burst always collect all colors in a stack. Reburst collects only one.",
#	"Label3" : "Burst and reburst always collect all colors in a stack.",
	"Label4" : "Reburst time window is limitless.",
	"Label5" : "Don't worry about energy.",
	# nafila iz level settingsov
	# "tilemap_path": 
	# "level": 
}
var enigma_level_setting: Dictionary = { 
	1: { # ključ je tudi številka levela
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_01.tscn",
		"level_description": "Description ...", # pre-game instructions
	},
	2: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_02.tscn",
		"level_description": "Description ...",
	},
	3: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_03.tscn",
		"level_description": "Description ...",
	},
	4: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_04.tscn",
		"level_description": "Description ...",
	},
	5: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_05.tscn",
		"level_description": "Description ...",
	},
	6: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_06.tscn",
		"level_description": "Description ...",
	},
	7: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_07.tscn",
		"level_description": "Description ...",
	},
	8: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_08.tscn",
		"level_description": "Description ...",
	},
	9: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_enigma_09.tscn",
		"level_description": "Description ...",
	},
	
	10: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_riddler_S.tscn",
		"level_description": "Description ...",
	},
	11: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_riddler_M.tscn",
		"level_description": "Description ...",
	},
	12: {
		"tilemap_path": "res://game/tilemaps/enigma/tilemap_riddler_L.tscn",
		"level_description": "Description ...",
	},
}
var game_data_testing: Dictionary = {
	"game": Games.TESTING,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Testing ... link",
	"game_scene_path": "res://game/game_testing.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_2.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_3.tscn",
#	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_4.tscn",
	"tilemap_path": "res://game/tilemaps/testing/tilemap_testing_5.tscn",
	# instructions text
	"description" : "Collect colors to earn points.",
	"Label": "", # presledek
	"Label2": "Game is over when you lose all energy.",
	"Label3" : "One big level.",
	"Label4" : "Time is limited.",
}

# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary # = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var use_custom_color_theme: bool = false


func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var debug_game = Games.TESTING
#	var debug_game = Games.TUTORIAL
#	var debug_game = Games.ENIGMA
#	var debug_game = Games.CLEANER_S
#	var debug_game = Games.CLEANER_M
#	var debug_game = Games.CLEANER_L
#	var debug_game = Games.THE_DUEL
#	var debug_game = Games.ERASER_S
#	var debug_game = Games.ERASER_M
#	var debug_game = Games.ERASER_L
	var debug_game = Games.SCROLLER
	set_game_data(debug_game)
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	

		
	match selected_game:
		Games.TESTING: 
			current_game_data = game_data_testing
			game_settings["respawn_mode"] = false
			game_settings["reburst_mode"] = true
			game_settings["player_start_color"] = Color.white
			game_settings["zoom_animation"] = false
			game_settings["reburst_hit_power"] = 1
			game_settings["reburst_mode"] = true			
			game_settings["reburst_window_time"] = 0 # 0 = neomejeno
			game_settings["strays_start_count"] = 50
		Games.TUTORIAL: 
			current_game_data = game_data_tutorial
			game_settings["player_start_life"] = 3
			game_settings["game_instructions_popup"] = false
			game_settings["timer_mode_countdown"] = false
			game_settings["respawn_mode"] = false
		Games.ENIGMA: 
			current_game_data = game_data_enigma
			game_settings["color_picked_points"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["all_cleaned_points"] = 1 # vsaj ena točka, če ne se sploh ne pokaže ... izpiše se "SUCCESS!"
			game_settings["color_picked_points"] = 0
			game_settings["cell_traveled_energy"] = 0 # energija ni pomembna
			game_settings["lose_life_on_hit"] = true
			game_settings["timer_mode_countdown"] = false
			game_settings["spectrum_start_on"] = true
			game_settings["position_indicators_on"] = false
			game_settings["start_countdown"] = true
			game_settings["player_start_color"] = Color.white
			game_settings["reburst_window_time"] = 0 # 0 = neomejeno
			game_settings["reburst_hit_power"] = 1
			game_settings["reburst_mode"] = true
			# debug
			game_settings["respawn_mode"] = false
			current_game_data["level"] = 2
			game_settings["solutions_mode"] = false
		Games.CLEANER_S: 
			current_game_data = game_data_cleaner_s
			game_settings["player_start_life"] = 3
			game_settings["all_cleaned_points"] = 100
			game_settings["on_hit_points_part"] = 1
			game_settings["cell_traveled_energy"] = 0 # energija ni pomembna
			game_settings["eternal_mode"] = true
			game_settings["lose_life_on_hit"] = true
			game_settings["timer_mode_countdown"] = false
			game_settings["spectrum_start_on"] = true
			game_settings["position_indicators_on"] = false
			game_settings["turn_stray_to_wall"] = false
			game_settings["full_power_mode"] = true
			#
			game_settings["strays_start_count"] = 50
			game_settings["reburst_mode"] = true
#			game_settings["respawn_wait_time"] = 1
#			game_settings["respawn_strays_count"] = 1
		Games.CLEANER_M: 
			current_game_data = game_data_cleaner_m
			game_settings["player_start_life"] = 3
			game_settings["all_cleaned_points"] = 100
			game_settings["on_hit_points_part"] = 1
			game_settings["cell_traveled_energy"] = 0 # energija ni pomembna
			game_settings["eternal_mode"] = true
			game_settings["lose_life_on_hit"] = true
			game_settings["timer_mode_countdown"] = false
			game_settings["spectrum_start_on"] = true
			game_settings["turn_stray_to_wall"] = true
			game_settings["full_power_mode"] = true
			game_settings["strays_start_count"] = 320
			game_settings["reburst_mode"] = true
			#
#			game_settings["respawn_wait_time"] = 1
#			game_settings["respawn_strays_count"] = 1
		Games.CLEANER_L: 
			current_game_data = game_data_cleaner_l
			game_settings["game_time_limit"] = 300
			game_settings["strays_start_count"] = 320
#			game_settings["reburst_mode"] = true
			#	
			game_settings["respawn_wait_time"] = 5
			game_settings["respawn_strays_count"] = 5
		Games.ERASER_S: 
			current_game_data = game_data_eraser_s
			game_settings["all_cleaned_points"] = 1 # vsaj ena točka, če ne se sploh ne pokaže ... izpiše se "SUCCESS!"
			game_settings["color_picked_points"] = 0
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = true
			game_settings["strays_start_count"] = 50
			game_settings["respawn_mode"] = false
		Games.ERASER_M: 
			current_game_data = game_data_eraser_m
			game_settings["all_cleaned_points"] = 1 # vsaj ena točka, če ne se sploh ne pokaže ... izpiše se "SUCCESS!"
			game_settings["color_picked_points"] = 0
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = true
			game_settings["strays_start_count"] = 50
			game_settings["respawn_mode"] = false
		Games.ERASER_L: 
			current_game_data = game_data_eraser_l
			game_settings["all_cleaned_points"] = 1 # vsaj ena točka, če ne se sploh ne pokaže ... izpiše se "SUCCESS!"
			game_settings["color_picked_points"] = 0
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = true
			game_settings["strays_start_count"] = 50
			game_settings["respawn_mode"] = false
		Games.THE_DUEL: 
			current_game_data = game_data_the_duel
			game_settings["player_start_life"] = 3
			game_settings["lose_life_on_hit"] = true
			game_settings["position_indicators_on"] = false 
			game_settings["respawn_strays_count"] = 20 
			game_settings["game_time_limit"] = 60
			game_settings["strays_start_count"] = 100
			#	
			game_settings["respawn_wait_time"] = 10
			game_settings["respawn_strays_count"] = 3
		Games.SCROLLER:
			current_game_data = game_data_scroller
			game_settings["on_hit_energy_part"] = 1
			game_settings["lose_life_on_hit"] = false
			game_settings["cell_traveled_energy"] = 0
			game_settings["all_cleaned_points"] = 0
#			game_settings["zoom_animation"] = false
			game_settings["timer_mode_countdown"] = false
			game_settings["position_indicators_on"] = false 
			game_settings["player_start_color"] = Color.red
			game_settings["strays_start_count"] = 1 # 1 v prvi spawn rundi
			# debug
			game_settings["scrolling_pause_time"] = 0.3 # 1 v prvi spawn rundi
#			game_settings["stray_to_spawn_round_range"] = [20, 30] # 1 v prvi spawn rundi

	# debug
	game_settings["game_instructions_popup"] = false
	game_settings["start_countdown"] = false
#	game_settings["zoom_animation"] = false
	game_settings["reburst_mode"] = false
#	game_settings["respawn_mode"] = false
