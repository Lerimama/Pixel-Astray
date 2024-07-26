extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var classic_table: VBoxContainer = $ClassicTable
onready var cleaner_xs_table: VBoxContainer = $CleanerXSTable
onready var cleaner_s_table: VBoxContainer = $CleanerSTable
onready var cleaner_m_table: VBoxContainer = $CleanerMTable
onready var cleaner_l_table: VBoxContainer = $CleanerLTable
onready var cleaner_xl_table: VBoxContainer = $CleanerXLTable
onready var chaser_table: VBoxContainer = $EraserTable
onready var defender_table: VBoxContainer = $DefenderTable
onready var sweeper_table: VBoxContainer = $SweeperTable


func _ready() -> void:
	
	var show_lines_count: int = 5
	classic_table.get_highscore_table(Profiles.game_data_classic, fake_player_ranking, 10)
	cleaner_xs_table.get_highscore_table(Profiles.game_data_cleaner_xs, fake_player_ranking, show_lines_count)
	cleaner_s_table.get_highscore_table(Profiles.game_data_cleaner_s, fake_player_ranking, show_lines_count)
	cleaner_m_table.get_highscore_table(Profiles.game_data_cleaner_m, fake_player_ranking, show_lines_count)
	cleaner_l_table.get_highscore_table(Profiles.game_data_cleaner_l, fake_player_ranking, show_lines_count)
	cleaner_xl_table.get_highscore_table(Profiles.game_data_cleaner_xl, fake_player_ranking, show_lines_count)
	chaser_table.get_highscore_table(Profiles.game_data_chaser, fake_player_ranking, show_lines_count)
	defender_table.get_highscore_table(Profiles.game_data_defender, fake_player_ranking, show_lines_count)
	sweeper_table.get_sweeper_highscore_table(Profiles.game_data_sweeper) # rabim 10 linij, ki so defaultne

	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	yield(get_tree().create_timer(1), "timeout") # _temp
	var game_data_global = Profiles.game_data_classic.duplicate()
	game_data_global["level"] = "Global"
	classic_table.get_local_to_global_ranks(Profiles.game_data_classic, game_data_global) # _temp
	classic_table_glo.get_highscore_table(game_data_global, fake_player_ranking, 15) # _temp

	
func fade_in_sweeper_table():
	
	var fade_time: float = 0.2
	var fade_tween = get_tree().create_tween()
	# fejkam delay
	fade_tween.tween_property(sweeper_table, "modulate:a", 1, 0.1) # delay
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
		
onready var classic_table_glo: VBoxContainer = $ClassicTableGlo


func _on_UpdateScoresBtn_pressed() -> void:
#	update_and_save_global_highscores(Profiles.game_data_classic)
	LootLocker.update_and_save_global_highscores_to_local(Profiles.game_data_classic)
	yield(LootLocker, "global_saved_to_local")
	var current_game_data_global = Profiles.game_data_classic.duplicate()
	current_game_data_global["level"] = "Global"
	classic_table.get_local_to_global_ranks(Profiles.game_data_classic, current_game_data_global) # _temp
	classic_table_glo.get_highscore_table(current_game_data_global, fake_player_ranking, 15) # _tem
	
	
func update_and_save_global_highscores(current_game_data: Dictionary):
	pass
#	# pogrebam board s spleta
#	# spremenim board v slovar kot so lokalne HS
#	# shranim v filet igre (dodam level Global)
#
#	# pogrebam leaderboard z neta
#	LootLocker.get_lootlocker_leaderboard() # Dictionary ali object
#	yield(LootLocker, "connection_closed")
#	var board = LootLocker.board # Dictionary ali object	
#
#	# spremenim board v HS slovar 
#	var global_game_highscores: Dictionary = {} 
#	for item in board:
#		var item_dictionary: Dictionary = item
#		var item_player_name: String = item_dictionary["member_id"]
#		var item_player_score = item_dictionary["score"]
#		var item_player_rank = "%02d" % item_dictionary["rank"]
#
#		var highscores_player_name: String = str(item_player_name)
#		var highscores_player_line: Dictionary 
#		highscores_player_line[highscores_player_name] = item_player_score
#
#		# add player dict to higscores dict
#		global_game_highscores[item_player_rank] = highscores_player_line
#
#	# dodam level name za ime save fileta in sejvam
#	var current_game_data_global = current_game_data.duplicate()
#	current_game_data_global["level"] = "Global"
#	Global.data_manager.write_highscores_to_file(current_game_data_global, global_game_highscores)
	
#	classic_table.get_local_to_global_ranks(current_game_data, current_game_data_global) # _temp
#	classic_table_glo.get_highscore_table(current_game_data_global, fake_player_ranking, 15) # _temp

	
func _on_SweeperRightBtn_pressed() -> void:
	
	sweeper_table.load_sweeper_table_page(1)


func _on_Sweeper_LeftBtn_pressed() -> void:
	
	sweeper_table.load_sweeper_table_page(-1)
	
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
