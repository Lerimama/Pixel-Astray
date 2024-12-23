extends Node


func TOP(): pass


enum Games {CLEANER, ERASER_XS, ERASER_S, ERASER_M, ERASER_L, ERASER_XL, HUNTER, DEFENDER, SWEEPER, THE_DUEL, SHOWCASE}
enum HighscoreTypes {NONE, POINTS, TIME}

enum TOUCH_CONTROLLER {DISABLED, BUTTONS_LEFT, BUTTONS_RIGHT, SCREEN_LEFT, SCREEN_RIGHT} # zaporedje more bit, da so SCREEN na koncu (settings uporablja)
var touch_controller_content: Dictionary = {
	TOUCH_CONTROLLER.DISABLED: {"Disabled": "Touch controls DISABLED"},
	TOUCH_CONTROLLER.BUTTONS_LEFT:  {"Buttons Right": "On-screen BUTTONS, Burst on right"},
	TOUCH_CONTROLLER.BUTTONS_RIGHT:  {"Buttons Left": "On-screen BUTTONS, Burst on left"},
	TOUCH_CONTROLLER.SCREEN_LEFT:  {"Sliding Left": "SLIDE tracking for motion, Burst on left"},
	TOUCH_CONTROLLER.SCREEN_RIGHT:  {"Sliding Right": "SLIDE tracking for motion, Burst on right"},
}

var default_player_stats: Dictionary = {
	"player_name": "Somebody", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life": 0, # se opredeli iz game_settings
	"player_energy": 0, # se opredeli iz game_settings
	"player_points": 0,
	"colors_collected": 0,
	"skill_count": 0,
	"burst_count": 0,
	"cells_traveled": 0,
}

var default_game_settings: Dictionary = { # per game
	# player
	"player_start_life": 1, # 1 lajf skrije ikone v hudu, on hit jemlje energijo ne lajfa
	"player_start_color": Global.color_dark_gray_pixel, # na začetku je bel, potem se animira v start color ... #232323, #141414
	"player_step_time": 0.09, # default hitrost
	"player_start_energy": 192,
	# points
	"color_picked_points": 10,
	"white_eliminated_points": 100,
	"cleaned_reward_points": 1000, # 1 ... izpiše se "SUCCESS!" # TEST
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": 0,
	"on_hit_wall_energy_factor": 1, # 1 ... energija ostane ista
	"on_get_hit_energy_factor": 0, # 0 ... izguba lajfa
	# reburst
	"reburst_mode": false,
	"reburst_hit_power": 0, # 0 gre po original pravilih moči, trenutno je 5 full power
	"reburst_window_time": 0.2, # 0 je neomejen čas
	# strays
	"create_strays_count": 0,
	"spawn_white_stray_part": 0, # procenti spawnanih ... 0 ne spawna nobenega belega
	"spawn_white_stray_part_limit": 0.5, # klempam, da ni "brezveznih" situacij
	"respawn_strays_count_range": [0,0], # če je > 0, je respawn aktiviran
	"respawn_pause_time": 1, # če je 0 lahko pride do errorja (se mi zdi, da n 0, se timer sam disejbla)
	"respawn_pause_time_low": 1, # klempam navzdol na tole
	"stray_step_time": 0.4, # ne manjši od 0.2
	"stray_step_pause_time": 1, # ne sme bit manjša od stray step hitrosti (0.2), je clampana ob apliciranju

	# game
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"color_pool_colors_count": 500,
	"step_slowdown_mode": true,
	"full_power_mode": false, # vedno destroja ves stack, hitrost = max_cock_count
	"game_music_track_index": 0, # default muska v igri
	"follow_mode": false,
	"still_time_limit": 0, # 0 je disejblano ... ko si pri miru se nekaj lahko zgodi
	"show_expressions": true,
	# gui
	"start_countdown": true,
	"zoom_to_level_size": false, # SHOWCASE
	"always_zoomed_in": false, # SWEEPER

}


# GAME DATA -----------------------------------------------------------------------------------
func GAME_DATA(): pass


var game_data_cleaner: Dictionary = {
	"game": Games.CLEANER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.POINTS,
	"game_name": "Cleaner",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_cleaner.tscn",
	"description": "Clear %d strays to reclaim the one-and-only status!" % 500,
}

var game_data_eraser_xs: Dictionary = {
	"game": Games.ERASER_XS, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser XS",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_xs.tscn",
	"description" : "Collect all %d colors and become the brightest again!" % 32,
}

var game_data_eraser_s: Dictionary = {
	"game": Games.ERASER_S, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser S",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_s.tscn",
	"description" : "Collect all %d colors and become the brightest again!" % 50,
}

var game_data_eraser_m: Dictionary = {
	"game": Games.ERASER_M, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser M",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_m.tscn",
	"description" : "Collect all %d colors and become the brightest again!" % 140,
}

var game_data_eraser_l: Dictionary = {
	"game": Games.ERASER_L, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser L",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_l.tscn",
	"description" : "Collect all %d colors and become the brightest again!" % 230,
}

var game_data_eraser_xl: Dictionary = {
	"game": Games.ERASER_XL, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.TIME,
	"game_name": "Eraser XL",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_eraser_xl.tscn",
	"description" : "Collect all %d colors and become the brightest again!" % 320,
}

var game_data_hunter: Dictionary = {
	"game": Games.HUNTER, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.POINTS,
	"game_name": "Hunter",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_hunter.tscn",
	"description" : "Keep the colors in check as they keep popping in!",
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
	"description" : "Defend your screen against invading colors!",
	# štart
	"level": 1,
	"level_goal_count": 32, # CON kolikor jih spawnanih v prvi rundi
	"spawn_round_range": [1, 1], # random spawn count, največ 120 - 8
	"line_steps_per_spawn_round": 1, # na koliko stepov se spawna nova runda
	# level up
	"level_goal_count_grow": 32, # dodatno prištejem
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
	"description" : "Sweep the entire screen with one spectacular move!",
	"Prop" : "Destroy the first stray and keep your momentum by pressing in the next target's direction.",
	"level": 1,
}

var game_data_the_duel: Dictionary = {
	"game": Games.THE_DUEL, # key igre je key lootlocker tabele
	"highscore_type": HighscoreTypes.NONE,
	"game_name": "The Duel",
	"game_scene_path": "res://game/game.tscn",
	"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
	"description" : "Only the best cleaner will shine in this epic battle!",
	"Prop": "Hit the opposing player\nto take his life and\nhalf of his points.",
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
	"res://game/tilemaps/sweeper/tilemap_sweeper_16.tscn" # pixel astray
	]


# PROCES -----------------------------------------------------------------------------------


var html5_mode: bool = false # skrije ExitGameBtn v home, GO in pavzi
var touch_available: bool = false
var debug_mode: bool = false

var tutorial_music_track_index: int = 3

# settings (home)
var use_default_color_theme: bool = true # sejvam
var pregame_screen_on: bool = true # sejvam
var camera_shake_on: bool = true # sejvam
var tutorial_mode: bool = true # sejvam
var analytics_mode: bool = true
var brightness: float = 1 setget _change_brightness # 0.6 > 1.1 ... def = 1
var vsync_on: bool = true setget _change_vsync
var set_touch_controller: int = TOUCH_CONTROLLER.SCREEN_LEFT
var screen_touch_sensitivity: float = 0.1 # 0 - 20% VP width ... def 0.1 ... ročno nastavljen ticker node

var game_settings: Dictionary
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"


var start_with_method: String = "home_in_intro"

func _ready() -> void:

	# opredelim app mode
	if OS.get_name() == "HTML5":
		html5_mode = true
	else:
		html5_mode = false
	analytics_mode = not html5_mode # vsa analitika preverja, če je v modu
	tutorial_mode = not html5_mode
	touch_available = OS.has_touchscreen_ui_hint()
	debug_mode = OS.is_debug_build()

	# nastavim sejvane settingse
	if not html5_mode:
		var apply_game_settings: Dictionary = Data.read_settings_from_file() # če fileta ni, pobere trenutno setane vrednosti
		pregame_screen_on = apply_game_settings["pregame_screen_on"]
		camera_shake_on = apply_game_settings["camera_shake_on"]
		tutorial_mode = apply_game_settings["tutorial_mode"]
		analytics_mode = apply_game_settings["analytics_mode"]
		self.vsync_on = apply_game_settings["vsync_on"]

	# DEBUG setup

	# če greš iz menija je tole povoženo
	if debug_mode:
#		var debug_game = Games.SHOWCASE # fix camera
#		var debug_game = Games.CLEANER
#		var debug_game = Games.ERASER_XS
#		var debug_game = Games.ERASER_S
#		var debug_game = Games.ERASER_M
#		var debug_game = Games.ERASER_L
#		var debug_game = Games.ERASER_XL
#		var debug_game = Games.HUNTER
#		var debug_game = Games.DEFENDER
		var debug_game = Games.SWEEPER
#		var debug_game = Games.THE_DUEL

#		start_with_method = "home_in_intro"
#		start_with_method = "home_in_no_intro"
		start_with_method = "game_in"

#		vsync_on = false
#		analytics_mode = false
		pregame_screen_on = false
		tutorial_mode = false
#		html5_mode = true
#		touch_available = true
#		debug_mode = false
#		game_settings["player_start_life"] = 2

		set_game_data(debug_game)
		game_settings["start_countdown"] = false
#	start_with_method = "home_in_no_intro"



func set_game_data(selected_game):

	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	game_settings["pregame_screen_on"] = pregame_screen_on # da se seta aka per-game in osnovnega ne spreminjam

	match selected_game:
		Games.CLEANER:
			current_game_data = game_data_cleaner.duplicate()
			game_settings["player_start_life"] = 3
			game_settings["create_strays_count"] = 500 # spawna jih cca 1200 (tilemap setup)
			game_settings["start_countdown"] = false
		Games.ERASER_XS:
			current_game_data = game_data_eraser_xs.duplicate()
			game_settings["player_start_life"] = 1
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["create_strays_count"] = 32
			game_settings["spawn_white_stray_part"] = 0.11 # 10 posto
		Games.ERASER_S:
			current_game_data = game_data_eraser_s.duplicate()
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["create_strays_count"] = 50
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_M:
			current_game_data = game_data_eraser_m.duplicate()
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["create_strays_count"] = 140
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_L:
			current_game_data = game_data_eraser_l.duplicate()
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["create_strays_count"] = 230
			game_settings["spawn_white_stray_part"] = 0.11
		Games.ERASER_XL:
			current_game_data = game_data_eraser_xl.duplicate()
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["create_strays_count"] = 320
			game_settings["spawn_white_stray_part"] = 0.11
		Games.HUNTER:
			current_game_data = game_data_hunter.duplicate()
			game_settings["respawn_strays_count_range"] = [2, 8]
			game_settings["respawn_pause_time"] = 3
			game_settings["spawn_white_stray_part"] = 0.32
			game_settings["start_countdown"] = false
		Games.DEFENDER:
			current_game_data = game_data_defender.duplicate()
			game_settings["full_power_mode"] = true
			game_settings["create_strays_count"] = 1
			game_settings["start_countdown"] = false
			game_settings["follow_mode"] = true
		Games.SWEEPER:
			current_game_data = game_data_sweeper.duplicate()
			game_settings["player_start_life"] = 1
			game_settings["on_hit_wall_energy_factor"] = 0
			game_settings["player_start_color"] = Color.white
			game_settings["color_picked_points"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["reburst_mode"] = true
			game_settings["reburst_window_time"] = 0
			game_settings["game_music_track_index"] = 3
			# zoom-in je samo prvi level iz home menija
			# med igro se seta na off, da ostane zoomiran
			# play iz GO je že zumiran
			game_settings["always_zoomed_in"] = false
			tutorial_mode = false # _temp rabi posebn tutorial
		Games.THE_DUEL:
			current_game_data = game_data_the_duel.duplicate()
			game_settings["player_start_life"] = 3
			game_settings["game_time_limit"] = 180 # tilemap set
			game_settings["respawn_strays_count_range"] = [1, 14]
			game_settings["spawn_white_stray_part"] = 0.21
			tutorial_mode = false


func _change_brightness(set_value: float):
	# najprej preveri home env, če ga ni je v pvza meniju

	var arena_enviroment: Environment
	var enviroment_node: WorldEnvironment = Global.game_manager.get_node("ArenaEnvironment")
	if enviroment_node == null:
		enviroment_node = Global.game_arena.get_node("ArenaEnvironment")
	arena_enviroment = enviroment_node.environment

	brightness = set_value
	arena_enviroment.adjustment_brightness = brightness


func _change_vsync(set_on: bool):

	vsync_on = set_on
	OS.vsync_enabled = vsync_on
	#	print ("vsync post ", OS.vsync_enabled)
