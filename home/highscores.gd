extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var selected_tab: Button
var selected_hall: Control

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

# tables data ... zaporedje se mora ujemati
onready var all_local_tables: Array = [
	$ScrollContainer/ScrollContent/ClassicHall/ClassicTable, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXS/CleanerXSTable, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerS/CleanerSTable, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerM/CleanerMTable, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerL/CleanerLTable, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXL/CleanerXLTable,
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/Defender/DefenderTable, 
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/Eraser/EraserTable, 
	$ScrollContainer/ScrollContent/SweeperHall/SweeperTable 
	]
onready var all_global_tables: Array = [
	$ScrollContainer/ScrollContent/ClassicHall/ClassicTableGlobal, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXS/CleanerXSTableGlobal, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerS/CleanerSTableGlobal, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerM/CleanerMTableGlobal, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerL/CleanerLTableGlobal, 
	$ScrollContainer/ScrollContent/CleanersHall/TabContainer/CleanerXL/CleanerXLTableGlobal,
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/Defender/DefenderTableGlobal, 
	$ScrollContainer/ScrollContent/UnbeatableHall/TabContainer/Eraser/EraserTableGlobal, 
	$ScrollContainer/ScrollContent/SweeperHall/SweeperTableGlobal
	]
onready var all_tables_game_data: Array = [
	Profiles.game_data_classic,
	Profiles.game_data_cleaner_xs,
	Profiles.game_data_cleaner_s,
	Profiles.game_data_cleaner_m,
	Profiles.game_data_cleaner_l,
	Profiles.game_data_cleaner_xl,
	Profiles.game_data_chaser,
	Profiles.game_data_defender,
	Profiles.game_data_sweeper
	]

# tabs
onready var tabs: HBoxContainer = $Tabs
onready var classic_tab: Button = $Tabs/ClassicTab
onready var unbeatable_tab: Button = $Tabs/UnbeatableTab
onready var sweeper_tab: Button = $Tabs/SweeperTab
onready var cleaner_tab: Button = $Tabs/CleanerTab

# halls
var focused_hall_content: Control = null # 
onready var classic_hall: Control = $ScrollContainer/ScrollContent/ClassicHall
onready var unbeatable_hall: Control = $ScrollContainer/ScrollContent/UnbeatableHall
onready var unbeatable_tab_container: TabContainer = $ScrollContainer/ScrollContent/UnbeatableHall/TabContainer
onready var sweeper_hall: Control = $ScrollContainer/ScrollContent/SweeperHall
onready var cleaner_hall: Control = $ScrollContainer/ScrollContent/CleanersHall
onready var cleaner_tab_container: TabContainer = $ScrollContainer/ScrollContent/CleanersHall/TabContainer

# scrolling
onready var scroll_container: ScrollContainer = $ScrollContainer
onready var classic_hall_position: float = classic_hall.rect_position.x
onready var unbeatable_hall_position: float = unbeatable_hall.rect_position.x
onready var sweeper_hall_position: float = sweeper_hall.rect_position.x
onready var cleaner_hall_position: float = cleaner_hall.rect_position.x - (scroll_container.rect_size.x - cleaner_hall.rect_size.x) # drugačna, ker je zadnja

# table nodes
onready var classic_table: VBoxContainer = $ScrollContainer/ScrollContent/ClassicHall/ClassicTable
onready var classic_table_global: VBoxContainer = $ScrollContainer/ScrollContent/ClassicHall/ClassicTableGlobal
onready var sweeper_table: VBoxContainer = $ScrollContainer/ScrollContent/SweeperHall/SweeperTable

 

func _input(event):
	
	# če hall ni fokusiran, ga fokusiram s tipko dol
	if focused_hall_content == null:
		# če je fokusiran pravi tab ob tipki "dol" fokusiram notranjost
		match get_focus_owner():
			unbeatable_tab:
				if event.is_action_pressed("ui_down"):
					focus_selected_hall(unbeatable_tab)
			cleaner_tab:
				if event.is_action_pressed("ui_down"):
					focus_selected_hall(cleaner_tab)
	# če hall je fokusiran se premikam po tabih
	else:
		var tab = focused_hall_content.current_tab
		if event.is_action_pressed("ui_up"):
			defocus_selected_hall()
			return
		elif event.is_action_pressed("ui_left"):
			tab -= 1
		elif event.is_action_pressed("ui_right"):
			tab += 1
		focused_hall_content.current_tab = clamp(tab, 0, get_child_count())
		unbeatable_tab_container.set_current_tab(tab)



func _ready() -> void:
	
	var show_lines_count: int = 10
	
	# napolnem lokalne lestvice
	for table in all_local_tables:
		var table_index: int = all_local_tables.find(table)
		var game_data_local: Dictionary = all_tables_game_data[table_index]
		table.load_highscore_table(game_data_local, fake_player_ranking, show_lines_count)
		var game_data_global = game_data_local.duplicate()
		game_data_global["level"] = "Global"
		table.load_local_to_global_ranks(game_data_local, game_data_global)
		
		
	# _temp global ranks
	var game_data_global = Profiles.game_data_classic.duplicate()
	game_data_global["level"] = "Global"
	
	# napolnem globalne lestvice
	for table in all_global_tables:
		var table_index: int = all_global_tables.find(table)
#		var game_data_local: Dictionary = all_tables_game_data[table_index]
#		var game_data_global = game_data_local.duplicate()
#		game_data_global["level"] = "Global"
		table.load_highscore_table(game_data_global, fake_player_ranking, 50) # debug, če je več kot je global rezultatov
	
	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)

	for tab in tabs.get_children():	
		tab.get_node("Edge").hide()
	
	for hall in $ScrollContainer/ScrollContent.get_children():
		hall.get_node("Undi/Edge").modulate.a = 0.3	
	selected_tab = classic_tab


func _process(delta: float) -> void:

	if get_parent().current_screen == get_parent().Screens.HIGHSCORES:	
		
		var new_scroll_position: float = scroll_container.scroll_horizontal
		var position_offset_buffer: float = 160
		
		# opredelim pressed tab glede na pozicijo
		if new_scroll_position <= classic_hall_position + position_offset_buffer:
			selected_tab = classic_tab 
			selected_hall = classic_hall
		elif new_scroll_position <= unbeatable_hall_position + position_offset_buffer:
			selected_tab = unbeatable_tab
			selected_hall = unbeatable_hall
		elif new_scroll_position <= sweeper_hall_position + position_offset_buffer:
			selected_tab = sweeper_tab
			selected_hall = sweeper_hall
		else:
			selected_tab = cleaner_tab
			selected_hall = cleaner_hall 
		
		# skrijem vse tab edge in pokažem izbranega
		for tab in tabs.get_children():	
			tab.get_node("Edge").hide()
		selected_tab.get_node("Edge").show()	
		
		# skrijem vse hall edge in pokažem izbranega
		#		for hall in $ScrollContainer/ScrollContent.get_children():
		#			hall.get_node("Undi/Edge").modulate.a = 0.3
		#	#			hall.get_node("Undi/Edge").hide()
		#	#		selected_hall.get_node("Undi/Edge").show()
		#		selected_hall.get_node("Undi/Edge").modulate.a = 1
		
	
			
func focus_selected_hall(focused_tab: Button):
	
	# fokus na hall
	match focused_tab:
		unbeatable_tab:
			focused_hall_content = unbeatable_tab_container
		cleaner_tab:
			focused_hall_content = cleaner_tab_container
	focused_hall_content.focus_mode = Control.FOCUS_ALL		
	focused_hall_content.grab_focus()
	
	# disable focus na prvem nivoju
	for tab in tabs.get_children():	
		tab.focus_mode = Control.FOCUS_NONE
	$BackBtn.focus_mode = Control.FOCUS_NONE
	$UpdateScoresBtn.focus_mode = Control.FOCUS_NONE
	
	
func defocus_selected_hall():
	
	# disable focus na notranjosti
	
	# enable focus na prvem nivoju
	for tab in tabs.get_children():	
		tab.focus_mode = Control.FOCUS_ALL
	$BackBtn.focus_mode = Control.FOCUS_ALL
	$UpdateScoresBtn.focus_mode = Control.FOCUS_ALL	
	
	# fokus na zunaji tab
	var tab_to_focus: Button
	match focused_hall_content:
		unbeatable_tab_container:
			tab_to_focus = unbeatable_tab
		cleaner_tab_container:
			tab_to_focus = cleaner_tab
	tab_to_focus.grab_focus() 

	#	printt("ToF", tab_to_focus. get_focus_owner()) # debug preskoči na update btn
	focused_hall_content.focus_mode = Control.FOCUS_NONE
	focused_hall_content = null


# UTILITI --------------------------------------------------------------------------------------------------------------


func scroll_to_position(new_scroll_position: float, selected_tab: Button):
	
	focused_hall_content = null
	
	var scroll_tween = get_tree().create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", new_scroll_position, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	yield(scroll_tween, "finished")

	
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


# BUTTONS --------------------------------------------------------------------------------------------------------------

		
func _on_ClassicTab_pressed() -> void:
	scroll_to_position(classic_hall_position, classic_tab)
	
	
func _on_UnbeatableTab_pressed() -> void:
	scroll_to_position(unbeatable_hall_position, unbeatable_tab)


func _on_SweeperTab_pressed() -> void:
	scroll_to_position(sweeper_hall_position, sweeper_tab)

	
func _on_CleanerTab_pressed() -> void:
	scroll_to_position(cleaner_hall_position, cleaner_tab)
	
	
	
	
func _on_SweeperRightBtn_pressed() -> void:
	
	sweeper_table.load_sweeper_table_page(1)


func _on_Sweeper_LeftBtn_pressed() -> void:
	
	sweeper_table.load_sweeper_table_page(-1)
	
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")


func _on_UpdateScoresBtn_pressed() -> void:
	
	LootLocker.update_lootlocker_leaderboard(Profiles.game_data_classic)
	yield(ConnectCover, "connect_cover_closed")
	
	var current_game_data_global = Profiles.game_data_classic.duplicate()
	current_game_data_global["level"] = "Global"
	classic_table.load_local_to_global_ranks(Profiles.game_data_classic, current_game_data_global)
	classic_table_global.load_highscore_table(current_game_data_global, fake_player_ranking, 15)
	

