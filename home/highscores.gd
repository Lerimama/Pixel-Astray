extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var eraser_s_table: VBoxContainer = $EraserSTable
onready var eraser_m_table: VBoxContainer = $EraserMTable
onready var eraser_l_table: VBoxContainer = $EraserLTable
onready var cleaner_s_table: VBoxContainer = $CleanerSTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var cleaner_table: VBoxContainer = $CleanerLTable
onready var scroller_table: VBoxContainer = $ScrollerTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	eraser_s_table.get_highscore_table(Profiles.game_data_eraser_s, fake_player_ranking)
	eraser_m_table.get_highscore_table(Profiles.game_data_eraser_m, fake_player_ranking)
	eraser_l_table.get_highscore_table(Profiles.game_data_eraser_l, fake_player_ranking)
	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_s, fake_player_ranking)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_m, fake_player_ranking)
	cleaner_table.get_highscore_table(Profiles.game_data_cleaner_l, fake_player_ranking)
	scroller_table.get_highscore_table(Profiles.game_data_scroller, fake_player_ranking)
	

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_viewport().set_disable_input(true)
