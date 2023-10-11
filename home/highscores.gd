extends Control


onready var highscore_table_S: VBoxContainer = $LevelS/HighscoreTable
onready var highscore_table_M: VBoxContainer = $LevelM/HighscoreTable
onready var highscore_table_L: VBoxContainer = $LevelL/HighscoreTable
onready var highscore_table_XL: VBoxContainer = $LevelXL/HighscoreTable
onready var highscore_table_XXL: VBoxContainer = $LevelXXL/HighscoreTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100
	highscore_table_S.get_highscore_table(Profiles.level_1_stats["level"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_M.get_highscore_table(Profiles.level_2_stats["level"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_L.get_highscore_table(Profiles.level_3_stats["level"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_XL.get_highscore_table(Profiles.level_4_stats["level"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_XXL.get_highscore_table(Profiles.level_5_stats["level"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno

