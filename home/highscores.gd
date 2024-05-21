extends Control


var fake_player_ranking: int = 100 # številka je ranking izven lestvice, da ni označenega plejerja

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var cleaner_s_table: VBoxContainer = $CleanerSTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var cleaner_l_table: VBoxContainer = $CleanerLTable
onready var eraser_table: VBoxContainer = $EraserTable
onready var handler_table: VBoxContainer = $HandlerTable
onready var defender_table: VBoxContainer = $DefenderTable
onready var sweeper_table: VBoxContainer = $SweeperTable


func _ready() -> void:
	
	
	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_s, fake_player_ranking)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_m, fake_player_ranking)
	cleaner_l_table.get_highscore_table(Profiles.game_data_cleaner_l, fake_player_ranking)
	eraser_table.get_highscore_table(Profiles.game_data_eraser, fake_player_ranking)
	handler_table.get_highscore_table(Profiles.game_data_handler, fake_player_ranking)
	defender_table.get_highscore_table(Profiles.game_data_defender, fake_player_ranking)
	Profiles.game_data_sweeper["level"] = 1
	sweeper_table.get_highscore_table(Profiles.game_data_sweeper, fake_player_ranking)
	

func load_new_sweeper_table(next_or_prev: int):
	# ime save fileta SWEEPER_1_highscores.save
	
	# ciklanje levelov
	Profiles.game_data_sweeper["level"] += next_or_prev
	if Profiles.game_data_sweeper["level"] > Profiles.sweeper_level_setting.size():
		Profiles.game_data_sweeper["level"] = 1
	elif Profiles.game_data_sweeper["level"] < 1:
		Profiles.game_data_sweeper["level"] = Profiles.sweeper_level_setting.size()
	
	# tranzicija
	var fade_time: float = 0.4
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(sweeper_table.get_children()[1], "modulate:a", 0, fade_time).set_ease(Tween.EASE_IN)
	# vse linije brez titla, na ročen način
	fade_tween.parallel().tween_property(sweeper_table.get_children()[2], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[3], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[4], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[5], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[6], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[7], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[8], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[9], "modulate:a", 0, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[10], "modulate:a", 0, fade_time)
	fade_tween.tween_callback(sweeper_table, "get_highscore_table", [Profiles.game_data_sweeper, fake_player_ranking])
	# fejkam delay
	fade_tween.tween_property(sweeper_table, "modulate:a", 1, 0.2) # delay
	# vse linije brez titla, na ročen način
	fade_tween.tween_property(sweeper_table.get_children()[1], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[2], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[3], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[4], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[5], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[6], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[7], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[8], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[9], "modulate:a", 1, fade_time)
	fade_tween.parallel().tween_property(sweeper_table.get_children()[10], "modulate:a", 1, fade_time)
	
	
func _on_SweeperRightBtn_pressed() -> void:

	load_new_sweeper_table(1)


func _on_Sweeper_LeftBtn_pressed() -> void:
	
	load_new_sweeper_table(-1)
	
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_viewport().set_disable_input(true)


