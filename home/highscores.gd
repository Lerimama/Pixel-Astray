extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var selected_tab: Button
var selected_hall: Control
var scroll_tween_time: float = 0.8

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

var time_since_higscores_update: float = 0
var update_higscores_disabled_time_limit: float = 5
onready var update_scores_btn: Button = $UpdateScoresBtn

# tables data ... zaporedje se mora ujemati
onready var halls: Array = [
	$ScrollContainer/ScrollContent/ClassicHall,
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXSHall, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerSHall, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerMHall, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerLHall, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXLHall,
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/DefenderHall, 
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/EraserHall, 
	]
onready var all_sweeper_halls: Array = [
	$ScrollContainer/ScrollContent/SweeperHall/TabContainer/Sweeper1Hall, 
	$ScrollContainer/ScrollContent/SweeperHall/TabContainer/Sweeper2Hall, 
	$ScrollContainer/ScrollContent/SweeperHall/TabContainer/Sweeper3Hall, 
	$ScrollContainer/ScrollContent/SweeperHall/TabContainer/Sweeper4Hall, 
	$ScrollContainer/ScrollContent/SweeperHall/TabContainer/Sweeper5Hall
	]
#onready var all_local_tables: Array = []
#onready var all_global_tables: Array = []
onready var all_tables_game_data: Array = [
	Profiles.game_data_classic,
	Profiles.game_data_cleaner_xs,
	Profiles.game_data_cleaner_s,
	Profiles.game_data_cleaner_m,
	Profiles.game_data_cleaner_l,
	Profiles.game_data_cleaner_xl,
	Profiles.game_data_defender,
	Profiles.game_data_chaser,
	]
	
#onready var all_sweeper_global_tables: Array = [
#	$ScrollContainer/ScrollContent/SweeperHall/SweeperTableGlobal,
#	$ScrollContainer/ScrollContent/SweeperHall/SweeperTableGlobal2
#	]
#onready var all_sweeper_local_tables: Array = [
#	$ScrollContainer/ScrollContent/SweeperHall/SweeperTable,
#	$ScrollContainer/ScrollContent/SweeperHall/SweeperTable2 
#	]

# tabs
onready var tab_btns: HBoxContainer = $Tabs
onready var classic_tab_btn: Button = $Tabs/ClassicTab
onready var unbeatable_tab_btn: Button = $Tabs/UnbeatableTab
onready var sweeper_tab_btn: Button = $Tabs/SweeperTab
onready var cleaner_tab_btn: Button = $Tabs/CleanerTab

# halls
var focused_hall_content: Control = null # 
onready var classic_hall: Control = $ScrollContainer/ScrollContent/ClassicHall
onready var unbeatable_hall: Control = $ScrollContainer/ScrollContent/UnbeatableHall
onready var unbeatable_hall_content: TabContainer = $ScrollContainer/ScrollContent/UnbeatableHall/TabContainer
onready var sweeper_hall: Control = $ScrollContainer/ScrollContent/SweeperHall
onready var cleaner_hall: Control = $ScrollContainer/ScrollContent/CleanersHall
onready var cleaner_hall_content: TabContainer = $ScrollContainer/ScrollContent/CleanersHall/TabContainer

# scrolling
onready var scroll_container: ScrollContainer = $ScrollContainer
onready var classic_hall_position: float = classic_hall.rect_position.x
onready var unbeatable_hall_position: float = unbeatable_hall.rect_position.x
onready var sweeper_hall_position: float = sweeper_hall.rect_position.x
onready var cleaner_hall_position: float = cleaner_hall.rect_position.x - (scroll_container.rect_size.x - cleaner_hall.rect_size.x) # drugačna, ker je zadnja


func _input(event):
	
	if focused_hall_content == null:
		var content_to_focus: Control
		if selected_hall == unbeatable_hall:
			if event.is_action_pressed("ui_down"):
				focus_hall_content(unbeatable_hall)			
		elif selected_hall == cleaner_hall:
			if event.is_action_pressed("ui_down"):
				focus_hall_content(cleaner_hall)			
		else:
			pass
	# če hall je fokusiran se premikam po tabih
	else:
		var tab = focused_hall_content.current_tab
		if event.is_action_pressed("ui_up"):
			defocus_hall_content()
			return
		elif event.is_action_pressed("ui_left"):
			tab -= 1
		elif event.is_action_pressed("ui_right"):
			tab += 1
		focused_hall_content.current_tab = clamp(tab, 0, get_child_count())
		unbeatable_hall_content.set_current_tab(tab)

func _ready() -> void:
	
	# btn groups
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)	
#	classic_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	unbeatable_hall.add_to_group(Global.group_menu_confirm_btns)
#	sweeper_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	cleaner_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	update_scores_btn.add_to_group(Global.group_menu_confirm_btns)
	
	print ("filam HS z diska")
	# pairs ... napolnem global 
	# za vsak par lestvic opredelim local/global in game data
	
	load_all_highscore_tables()

	# classic selected
	selected_tab = classic_tab_btn
	selected_hall = classic_hall
	highlight_hall_on_select()
	
		
func load_all_highscore_tables(with_update: bool = false):
	
	var all_local_tables: Array = []
	var all_global_tables: Array = []
	var all_sweeper_global_tables: Array = []
	var all_sweeper_local_tables: Array = []	
	
	
	for hall in halls:
		var hall_table_local: Control = hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = hall.get_node("TablePair/HighscoreTableGlobal")
		all_local_tables.append(hall_table_local)
		all_global_tables.append(hall_table_global)
	for sweeper_hall in all_sweeper_halls:
		var hall_table_local: Control = sweeper_hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = sweeper_hall.get_node("TablePair/HighscoreTableGlobal")
		sweeper_hall.name = "%02d" % (all_sweeper_halls.find(sweeper_hall) + 1)
		all_sweeper_global_tables.append(hall_table_global)
		all_sweeper_local_tables.append(hall_table_local)
		
	print ("pedenam lokalne")
	for table in all_local_tables:
		var table_index: int = all_local_tables.find(table)
		var game_data_local: Dictionary = all_tables_game_data[table_index]
		#		if game_data_local["game"] == Profiles.Games.SWEEPER: # OPT sweeper tabele združi z drugimi 
		#			game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
		table.load_local_to_global_ranks(game_data_local)
	for table in all_global_tables:
		var table_index: int = all_global_tables.find(table)
		var game_data_local: Dictionary = all_tables_game_data[table_index]
		if with_update:
			LootLocker.update_lootlocker_leaderboard(game_data_local)
			yield(ConnectCover, "connect_cover_closed")
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.global_highscores_count, true)
	print ("pedenam globalne")
	# napolnem sweeper lestvice s podatki iz diska
	for table in all_sweeper_local_tables:
		var game_data_local: Dictionary = Profiles.game_data_sweeper
		game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
		table.load_local_to_global_ranks(game_data_local)
	for table in all_sweeper_global_tables:
		var game_data_local: Dictionary = Profiles.game_data_sweeper
		game_data_local["level"] = all_sweeper_global_tables.find(table) + 1
		if with_update:
			LootLocker.update_lootlocker_leaderboard(game_data_local)
			yield(ConnectCover, "connect_cover_closed")
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.global_highscores_count, true)
	print ("spedenano")
	

func _process(delta: float) -> void:
	
	if get_parent().current_screen == get_parent().Screens.HIGHSCORES:	

		# update scores pavza
		if update_scores_btn.disabled:
			time_since_higscores_update += delta
			update_scores_btn.text = str(update_higscores_disabled_time_limit - time_since_higscores_update) + "to update"
			if time_since_higscores_update > update_higscores_disabled_time_limit:
				time_since_higscores_update = 0
				update_scores_btn.disabled = false
				update_scores_btn.text = "update global scores"
		
		# zaznavam izbrani hall
		var new_scroll_position: float = scroll_container.scroll_horizontal
		var position_offset_buffer: float = 160
		if new_scroll_position <= classic_hall_position + position_offset_buffer:
			selected_tab = classic_tab_btn 
			selected_hall = classic_hall
		elif new_scroll_position <= unbeatable_hall_position + position_offset_buffer:
			selected_tab = unbeatable_tab_btn
			selected_hall = unbeatable_hall
		elif new_scroll_position <= sweeper_hall_position + position_offset_buffer:
			selected_tab = sweeper_tab_btn
			selected_hall = sweeper_hall
		else:
			selected_tab = cleaner_tab_btn
			selected_hall = cleaner_hall 
		highlight_hall_on_select()
		
			
func focus_hall_content(content_to_focus: Control):
	
	# fokus na hall
	match content_to_focus:
		unbeatable_hall:
			focused_hall_content = unbeatable_hall_content
		cleaner_hall:
			focused_hall_content = cleaner_hall_content
	focused_hall_content.focus_mode = Control.FOCUS_ALL		
	focused_hall_content.grab_focus()
	
	# disable focus na prvem nivoju
	for tab_btn in tab_btns.get_children():	
		tab_btn.focus_mode = Control.FOCUS_NONE
	$BackBtn.focus_mode = Control.FOCUS_NONE
	update_scores_btn.focus_mode = Control.FOCUS_NONE
	
	
func defocus_hall_content():
	
	# enable focus na prvem nivoju
	for tab_btn in tab_btns.get_children():	
		tab_btn.focus_mode = Control.FOCUS_ALL
	$BackBtn.focus_mode = Control.FOCUS_ALL
	update_scores_btn.focus_mode = Control.FOCUS_ALL	
	
	# fokus na zunaji tab
	var tab_to_focus: Button
	match focused_hall_content:
		unbeatable_hall_content:
			tab_to_focus = unbeatable_tab_btn
		cleaner_hall_content:
			tab_to_focus = cleaner_tab_btn
			
	tab_to_focus.grab_focus() 

	# disable focus na notranjosti
	focused_hall_content.focus_mode = Control.FOCUS_NONE
	focused_hall_content = null


# UTILITI --------------------------------------------------------------------------------------------------------------


func highlight_hall_on_select():
	
	for tab_btn in tab_btns.get_children():	
		tab_btn.get_node("EdgeSelected").hide()
		tab_btn.self_modulate = Color.white
	selected_tab.get_node("EdgeSelected").show()
	selected_tab.self_modulate = Global.color_yellow

	for hall in $ScrollContainer/ScrollContent.get_children():
		hall.get_node("Undi/EdgeSelected").hide()	
	selected_hall.get_node("Undi/EdgeSelected").show()	
	
	
func scroll_to_position(new_scroll_position: float):
	
	if not focused_hall_content == null:
		defocus_hall_content()
	
	var scroll_tween = get_tree().create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", new_scroll_position, scroll_tween_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	yield(scroll_tween, "finished")
	

# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_UpdateScoresBtn_pressed() -> void:
	
	update_scores_btn.disabled = true
	# updejtam globalne rezultate na vseh lestvicah
	
	printt ("apdejt iger", get_focus_owner().release_focus() )
	# neu
	
	load_all_highscore_tables(true)
#	for table in all_global_tables:
#		var table_index: int = all_global_tables.find(table)
#		var game_data_local: Dictionary = all_tables_game_data[table_index]
#		LootLocker.update_lootlocker_leaderboard(game_data_local)
#		yield(ConnectCover, "connect_cover_closed")
#	for table in all_local_tables:
#		var table_index: int = all_local_tables.find(table)
#		var game_data_local: Dictionary = all_tables_game_data[table_index]
#		table.load_local_to_global_ranks(game_data_local)
#		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
#	print ("še sweepr")
#	for table in all_sweeper_global_tables:
#		var game_data_local: Dictionary = Profiles.game_data_sweeper
#		game_data_local["level"] = all_sweeper_global_tables.find(table) + 1
#		LootLocker.update_lootlocker_leaderboard(game_data_local)
#		yield(ConnectCover, "connect_cover_closed")
#	for table in all_sweeper_local_tables:
#		var game_data_local: Dictionary = Profiles.game_data_sweeper
#		game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
#		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
##		yield(get_tree().create_timer(0.1), "timeout") #_ temp
#		table.load_local_to_global_ranks(game_data_local)
#	print ("apdejtano")

	
func _on_ClassicTab_pressed() -> void:
	scroll_to_position(classic_hall_position)
	
	
func _on_UnbeatableTab_pressed() -> void:
	scroll_to_position(unbeatable_hall_position)


func _on_SweeperTab_pressed() -> void:
	scroll_to_position(sweeper_hall_position)

	
func _on_CleanerTab_pressed() -> void:
	scroll_to_position(cleaner_hall_position)
	

func _on_Unbeatable_tab_selected() -> void:
	
	# fokusiram samo, če je ta hall selectan 
	if selected_hall == unbeatable_hall:
		get_focus_owner().release_focus()
		focus_hall_content(unbeatable_hall)


func _on_Cleaner_tab_selected() -> void:
	
	# fokusiram samo, če je ta hall selectan 
	if selected_hall == cleaner_hall:
		get_focus_owner().release_focus()
		focus_hall_content(cleaner_hall)

	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
