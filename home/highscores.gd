extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var cleaner_table: VBoxContainer = $CleanerTable
onready var eraser_s_table: VBoxContainer = $EraserSTable
onready var eraser_m_table: VBoxContainer = $EraserMTable
onready var eraser_l_table: VBoxContainer = $EraserLTable
onready var eternal_table: VBoxContainer = $EternalTable
onready var eternal_xl_table: VBoxContainer = $EternalXLTable
onready var scroller_table: VBoxContainer = $ScrollerTable


func _ready() -> void:
	
	var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

	cleaner_table.get_highscore_table(Profiles.game_data_cleaner, fake_player_ranking)
	eraser_s_table.get_highscore_table(Profiles.game_data_eraser_S, fake_player_ranking)
	eraser_m_table.get_highscore_table(Profiles.game_data_eraser_M, fake_player_ranking)
	eraser_l_table.get_highscore_table(Profiles.game_data_eraser_L, fake_player_ranking)
	eternal_table.get_highscore_table(Profiles.game_data_eternal, fake_player_ranking)
	eternal_xl_table.get_highscore_table(Profiles.game_data_eternal_xl, fake_player_ranking)
	scroller_table.get_highscore_table(Profiles.game_data_scroller, fake_player_ranking)
	

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_viewport().set_disable_input(true)
