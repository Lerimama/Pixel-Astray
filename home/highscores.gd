extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var cleaner_s_table: VBoxContainer = $CleanerSTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var cleaner_l_table: VBoxContainer = $CleanerLTable
onready var eraser_table: VBoxContainer = $EraserTable
onready var handler_table: VBoxContainer = $HandlerTable
onready var defender_table: VBoxContainer = $DefenderTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_s, fake_player_ranking)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_m, fake_player_ranking)
	cleaner_l_table.get_highscore_table(Profiles.game_data_cleaner_l, fake_player_ranking)
	eraser_table.get_highscore_table(Profiles.game_data_eraser, fake_player_ranking)
	handler_table.get_highscore_table(Profiles.game_data_handler, fake_player_ranking)
	defender_table.get_highscore_table(Profiles.game_data_defender, fake_player_ranking)
	

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_viewport().set_disable_input(true)
