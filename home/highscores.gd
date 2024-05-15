extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var classic_s_table: VBoxContainer = $ClassicSTable
onready var classic_m_table: VBoxContainer = $ClassicMTable
onready var classic_l_table: VBoxContainer = $ClassicLTable
onready var game_data_popper_table: VBoxContainer = $PopperTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var scroller_table: VBoxContainer = $ScrollerTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	classic_s_table.get_highscore_table(Profiles.game_data_classic_s, fake_player_ranking)
	classic_m_table.get_highscore_table(Profiles.game_data_classic_m, fake_player_ranking)
	classic_l_table.get_highscore_table(Profiles.game_data_classic_l, fake_player_ranking)
	game_data_popper_table.get_highscore_table(Profiles.game_data_popper, fake_player_ranking)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_m, fake_player_ranking)
	scroller_table.get_highscore_table(Profiles.game_data_scroller, fake_player_ranking)
	

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_viewport().set_disable_input(true)
