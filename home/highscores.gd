extends Control


onready var eraser_s_table: VBoxContainer = $EraserSTable
onready var eraser_m_table: VBoxContainer = $EraserMTable
onready var eraser_l_table: VBoxContainer = $EraserLTable

onready var cleaner_s_table: VBoxContainer = $CleanerSTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var cleaner_l_table: VBoxContainer = $CleanerLTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	eraser_s_table.get_highscore_table(Profiles.game_data_eraser_S, fake_player_ranking)
	eraser_m_table.get_highscore_table(Profiles.game_data_eraser_M, fake_player_ranking)
	eraser_l_table.get_highscore_table(Profiles.game_data_eraser_L, fake_player_ranking)
	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_S, fake_player_ranking)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_M, fake_player_ranking)
	cleaner_l_table.get_highscore_table(Profiles.game_data_cleaner_L, fake_player_ranking)
	

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("highscores")
	get_viewport().set_disable_input(true)
