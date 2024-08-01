extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var selected_tab: Button
var selected_hall: Control
var scroll_tween_time: float = 0.8

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

var time_since_higscores_update: float = 0
var update_higscores_disabled_time_limit: float = 5
onready var update_scores_btn: Button = $UpdateScoresBtn

# tables data ... zaporedje se mora ujemati v sponjih 3 in z node zaporedjem v drevesu
onready var halls: Array = [
	$ScrollContainer/ScrollContent/Classic/ClassicHall,
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/XSHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/SHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/MHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/LHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/XLHall,
	$ScrollContainer/ScrollContent/Unbeatables/TabContainer/EraserHall, 
	$ScrollContainer/ScrollContent/Unbeatables/TabContainer/DefenderHall, 
	]
onready var all_sweeper_halls: Array = [
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper1Hall, 
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper2Hall, 
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper3Hall, 
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper4Hall, 
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper5Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper6Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper7Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper8Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper9Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper10Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper11Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper12Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper13Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper14Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper15Hall,
	$ScrollContainer/ScrollContent/Sweepers/TabContainer/Sweeper16Hall
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
	]
	
# tabs
onready var tab_btns: HBoxContainer = $Tabs
onready var classic_tab_btn: Button = $Tabs/ClassicTab
onready var unbeatable_tab_btn: Button = $Tabs/UnbeatableTab
onready var sweeper_tab_btn: Button = $Tabs/SweeperTab
onready var cleaner_tab_btn: Button = $Tabs/CleanerTab

# halls
var focused_content: Control = null # 
onready var classic: Control = $ScrollContainer/ScrollContent/Classic # OPT imena halls
onready var unbeatables: Control = $ScrollContainer/ScrollContent/Unbeatables
onready var unbeatables_content: TabContainer = $ScrollContainer/ScrollContent/Unbeatables/TabContainer
onready var sweepers: Control = $ScrollContainer/ScrollContent/Sweepers
onready var sweepers_content: Control = $ScrollContainer/ScrollContent/Sweepers/TabContainer
onready var cleaners: Control = $ScrollContainer/ScrollContent/Cleaners
onready var cleaners_content: TabContainer = $ScrollContainer/ScrollContent/Cleaners/TabContainer

# scroll
onready var scroll_container: ScrollContainer = $ScrollContainer
onready var classic_scroll_position: float = classic.rect_position.x
onready var unbeatables_scroll_position: float = unbeatables.rect_position.x
onready var sweepers_scroll_position: float = sweepers.rect_position.x
onready var cleaners_scroll_position: float = cleaners.rect_position.x - (scroll_container.rect_size.x - cleaners.rect_size.x) # drugačna, ker je zadnja


func _input(event):
	
	if focused_content == null:
		var content_to_focus: Control
		if selected_hall == unbeatables:
			if event.is_action_pressed("ui_down"):
				focus_hall_content(unbeatables)		
		elif selected_hall == sweepers:
			if event.is_action_pressed("ui_down"):
				focus_hall_content(sweepers)	
		elif selected_hall == cleaners:
			if event.is_action_pressed("ui_down"):
				focus_hall_content(cleaners)			
		else:
			pass
	# če hall je fokusiran se premikam po tabih
	else:
		var tab = focused_content.current_tab
		if event.is_action_pressed("ui_up"):
			defocus_hall_content()
			return
		elif event.is_action_pressed("ui_left"):
			tab -= 1
		elif event.is_action_pressed("ui_right"):
			tab += 1
		focused_content.current_tab = clamp(tab, 0, get_child_count())
		focused_content.set_current_tab(tab)

func _ready() -> void:
	
	# btn groups
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)	
#	classic_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	unbeatable_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	sweeper_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	cleaner_tab_btn.add_to_group(Global.group_menu_confirm_btns)
#	update_scores_btn.add_to_group(Global.group_menu_confirm_btns)

	# update centriranih pozicij hall holderjev
	var scroll_container_width: float = scroll_container.rect_size.x/2 
	unbeatables_scroll_position -= scroll_container_width - unbeatables.rect_size.x/2
	sweepers_scroll_position -= scroll_container_width - sweepers.rect_size.x/2
	
	load_all_highscore_tables()

	# classic selected
	selected_tab = classic_tab_btn
	selected_hall = classic
	
	highlight_hall_on_select()
	

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
		
		# če je mouse skrolanje zaznavam izbrani hall
		if scroll_container.mouse_filter == 2: # zahteva prenovo, če jo rabim
			var new_scroll_position: float = scroll_container.scroll_horizontal
			if new_scroll_position <= classic_scroll_position:
				selected_tab = classic_tab_btn 
				selected_hall = classic
			elif new_scroll_position <= unbeatables_scroll_position:
				selected_tab = unbeatable_tab_btn
				selected_hall = unbeatables
			elif new_scroll_position <= sweepers_scroll_position:
				selected_tab = sweeper_tab_btn
				selected_hall = sweepers
			else:
				selected_tab = cleaner_tab_btn
				selected_hall = cleaners 
		
		highlight_hall_on_select()
		

		
func load_all_highscore_tables(update_tables: bool = false):
	
	var all_local_tables: Array = []
	var all_global_tables: Array = []
	var all_sweeper_global_tables: Array = []
	var all_sweeper_local_tables: Array = []	
	
	# naberem vse hale
	print("Updating tables")
	for hall in halls:
		var hall_table_local: Control = hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = hall.get_node("TablePair/HighscoreTableGlobal")
		# preimenujem hall ime, ker se vidi v tabih
		hall.name = hall.name.trim_suffix("Hall")
		all_local_tables.append(hall_table_local)
		all_global_tables.append(hall_table_global)
	for sweeper_hall in all_sweeper_halls:
		var hall_table_local: Control = sweeper_hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = sweeper_hall.get_node("TablePair/HighscoreTableGlobal")
		# preimenujem hall ime, ker se vidi v tabih
		sweeper_hall.name = str(all_sweeper_halls.find(sweeper_hall) + 1)
		all_sweeper_global_tables.append(hall_table_global)
		all_sweeper_local_tables.append(hall_table_local)
	# apdejtam lokalne tabele
	for table in all_local_tables:
		var table_index: int = all_local_tables.find(table)
		var game_data_local: Dictionary = all_tables_game_data[table_index]
		#		if game_data_local["game"] == Profiles.Games.SWEEPER: # OPT sweeper tabele združi z drugimi 
		#			game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
		table.load_local_to_global_ranks(game_data_local)
	# apdejtam globalne tabele
	for table in all_global_tables:
		var table_index: int = all_global_tables.find(table)
		var game_data_local: Dictionary = all_tables_game_data[table_index]
		if update_tables:
			var last_table_in_row: Control = all_global_tables[all_global_tables.size() - 1]
			if table == last_table_in_row:
				LootLocker.update_lootlocker_leaderboard(game_data_local)
				yield(LootLocker, "connection_closed")
				ConnectCover.cover_label_text = "Finished"
				yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
				ConnectCover.close_cover() # odda signal, ko se zapre	
			else:
				LootLocker.update_lootlocker_leaderboard(game_data_local, false)
				yield(LootLocker, "leaderboard_updated")
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.global_highscores_count, true)
	# apdejtam sweeper lokalne tabele
	for table in all_sweeper_local_tables:
		var game_data_local: Dictionary = Profiles.game_data_sweeper
		game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
		table.load_local_to_global_ranks(game_data_local)
	# apdejtam sweeper globalne tabele
	for table in all_sweeper_global_tables:
		var game_data_local: Dictionary = Profiles.game_data_sweeper
		game_data_local["level"] = all_sweeper_global_tables.find(table) + 1
		if update_tables:
			var last_table_in_row: Control = all_sweeper_global_tables[all_sweeper_global_tables.size() - 1]
			if table == last_table_in_row:
				LootLocker.update_lootlocker_leaderboard(game_data_local)
				yield(LootLocker, "connection_closed")
				ConnectCover.cover_label_text = "Finished"
				yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
				ConnectCover.close_cover() # odda signal, ko se zapre	
			else:
				LootLocker.update_lootlocker_leaderboard(game_data_local, false)
				yield(LootLocker, "leaderboard_updated")
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.global_highscores_count, true)
	print ("All tables updated")

			
func focus_hall_content(content_to_focus: Control):
	
	# fokus na hall
	match content_to_focus:
		unbeatables:
			focused_content = unbeatables_content
		sweepers:
			focused_content = sweepers_content
		cleaners:
			focused_content = cleaners_content
	focused_content.focus_mode = Control.FOCUS_ALL		
	focused_content.grab_focus()
	
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
	match focused_content:
		unbeatables_content:
			tab_to_focus = unbeatable_tab_btn
		sweepers_content:
			tab_to_focus = sweeper_tab_btn
		cleaners_content:
			tab_to_focus = cleaner_tab_btn
			
	tab_to_focus.grab_focus() 

	# disable focus na notranjosti
	focused_content.focus_mode = Control.FOCUS_NONE
	focused_content = null


# UTILITI --------------------------------------------------------------------------------------------------------------


func highlight_hall_on_select():
	
	for tab_btn in tab_btns.get_children():	
		tab_btn.get_node("EdgeSelected").hide()
		tab_btn.self_modulate = Color.white
	selected_tab.get_node("EdgeSelected").show()
	selected_tab.self_modulate = Global.color_yellow

	return
#	for hall in scroll_container/ScrollContent.get_children():
#		hall.get_node("Undi/EdgeSelected").hide()	
#	selected_hall.get_node("Undi/EdgeSelected").show()	
	
	
func scroll_to_position(new_scroll_position: float):
	
	if not focused_content == null:
		defocus_hall_content()
	
	var scroll_tween = get_tree().create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", new_scroll_position, scroll_tween_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	yield(scroll_tween, "finished")
	

# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_UpdateScoresBtn_pressed() -> void:
	
	update_scores_btn.disabled = true
	load_all_highscore_tables(true)

	
func _on_ClassicTab_pressed() -> void:
	scroll_to_position(classic_scroll_position)
	
	
func _on_UnbeatableTab_pressed() -> void:
	scroll_to_position(unbeatables_scroll_position)


func _on_SweeperTab_pressed() -> void:
	scroll_to_position(sweepers_scroll_position)

	
func _on_CleanerTab_pressed() -> void:
	scroll_to_position(cleaners_scroll_position)
	

func _on_Unbeatable_tab_selected() -> void:
	
	# fokusiram samo, če je ta hall selectan 
	if selected_hall == unbeatables:
		get_focus_owner().release_focus()
		focus_hall_content(unbeatables)


func _on_Sweepers_tab_selected() -> void:
	
	# fokusiram samo, če je ta hall selectan 
	if selected_hall == sweepers:
		get_focus_owner().release_focus()
		focus_hall_content(sweepers)

func _on_Cleaner_tab_selected() -> void:
	
	# fokusiram samo, če je ta hall selectan 
	if selected_hall == cleaners:
		get_focus_owner().release_focus()
		focus_hall_content(cleaners)

	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")

