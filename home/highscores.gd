extends Control


onready var highscore_table_S: VBoxContainer = $GameS/HighscoreTable
onready var highscore_table_M: VBoxContainer = $GameM/HighscoreTable
onready var highscore_table_L: VBoxContainer = $GameL/HighscoreTable
onready var highscore_table_XL: VBoxContainer = $GameXL/HighscoreTable
onready var highscore_table_XXL: VBoxContainer = $GameXXL/HighscoreTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100
	highscore_table_S.get_highscore_table(Profiles.game_data_S["game"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_M.get_highscore_table(Profiles.game_data_M["game"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_L.get_highscore_table(Profiles.game_data_L["game"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_XL.get_highscore_table(Profiles.game_data_XL["game"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno
	highscore_table_XXL.get_highscore_table(Profiles.game_data_XXL["game"], fake_player_ranking) # številka je ranking izven lesvice in nič ni označeno

