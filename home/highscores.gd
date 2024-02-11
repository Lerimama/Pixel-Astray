extends Control


onready var cleaner_table: VBoxContainer = $CleanerTable

onready var eraser_s_table: VBoxContainer = $EraserSTable
onready var eraser_m_table: VBoxContainer = $EraserMTable
onready var eraser_l_table: VBoxContainer = $EraserLTable

onready var amaze_table: VBoxContainer = $AmazeTable

onready var riddler_s_table: VBoxContainer = $RiddlerSTable
onready var riddler_m_table: VBoxContainer = $RiddlerMTable
onready var riddler_l_table: VBoxContainer = $RiddlerLTable

onready var scroller_table: VBoxContainer = $ScrollerTable
onready var sidewinder_table: VBoxContainer = $SidewinderTable

#onready var cleaner_s_table: VBoxContainer = $CleanerSTable
#onready var cleaner_m_table: VBoxContainer = $CleanerMTable
#onready var cleaner_l_table: VBoxContainer = $CleanerLTable



func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	cleaner_table.get_highscore_table(Profiles.game_data_cleaner, fake_player_ranking)
	eraser_s_table.get_highscore_table(Profiles.game_data_eraser_S, fake_player_ranking)
	eraser_m_table.get_highscore_table(Profiles.game_data_eraser_M, fake_player_ranking)
	eraser_l_table.get_highscore_table(Profiles.game_data_eraser_L, fake_player_ranking)
	
	amaze_table.get_highscore_table(Profiles.game_data_amaze, fake_player_ranking)
	riddler_s_table.get_highscore_table(Profiles.game_data_riddler_S, fake_player_ranking)
	riddler_m_table.get_highscore_table(Profiles.game_data_riddler_M, fake_player_ranking)
	riddler_l_table.get_highscore_table(Profiles.game_data_riddler_L, fake_player_ranking)
	
	
	scroller_table.get_highscore_table(Profiles.game_data_scroller, fake_player_ranking)
	sidewinder_table.get_highscore_table(Profiles.game_data_sidewinder, fake_player_ranking)
#	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_S, fake_player_ranking)
#	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_M, fake_player_ranking)
#	cleaner_l_table.get_highscore_table(Profiles.game_data_cleaner_L, fake_player_ranking)


func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("highscores")
	get_viewport().set_disable_input(true)
