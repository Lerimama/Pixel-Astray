extends Control


onready var highscore_table_S: VBoxContainer = $GameS/HighscoreTable
onready var highscore_table_M: VBoxContainer = $GameM/HighscoreTable
onready var highscore_table_L: VBoxContainer = $GameL/HighscoreTable
onready var highscore_table_XL: VBoxContainer = $GameXL/HighscoreTable
onready var highscore_table_XXL: VBoxContainer = $GameXXL/HighscoreTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

#	highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_ranking)
#	highscore_table_S.get_highscore_table(Profiles.game_data_cleaner_S["game"], fake_player_ranking) 
#	highscore_table_M.get_highscore_table(Profiles.game_data_cleaner_M["game"], fake_player_ranking)
#	highscore_table_L.get_highscore_table(Profiles.game_data_cleaner_L["game"], fake_player_ranking)
	
	pass

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("highscores")
	get_viewport().set_disable_input(true)
