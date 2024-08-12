extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var scroll_tween_time: float = 0.8
#var selected_hall: Control
var selected_hall: Control
var selected_tab_btn: Button

var all_local_tables: Array = []
var all_global_tables: Array = []
var all_sweeper_global_tables: Array = []
var all_sweeper_local_tables: Array = []
var time_since_higscores_update: float = 0
var update_higscores_disabled_time_limit: float = 5


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var update_scores_btn: Button = $UpdateScoresBtn

# tables data ... zaporedje se mora ujemati v sponjih 3 in z node zaporedjem v drevesu
onready var halls: Array = [
	$ScrollContainer/ScrollContent/Classic/ClassicHall,
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/XSHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/SHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/MHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/LHall, 
	$ScrollContainer/ScrollContent/Cleaners/TabContainer/XLHall,
	$ScrollContainer/ScrollContent/Unbeatables/TabContainer/ChaserHall, 
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
onready var tab_btns: HBoxContainer = $TabBtns
onready var classic_tab_btn: Button = $TabBtns/ClassicTab
onready var unbeatable_tab_btn: Button = $TabBtns/UnbeatableTab
onready var sweeper_tab_btn: Button = $TabBtns/SweeperTab
onready var cleaner_tab_btn: Button = $TabBtns/CleanerTab

# halls
var focused_content: Control = null # 
onready var classic: Control = $ScrollContainer/ScrollContent/Classic
onready var classic_hall: Control = $ScrollContainer/ScrollContent/Classic/ClassicHall
onready var unbeatables: Control = $ScrollContainer/ScrollContent/Unbeatables
onready var unbeatables_hall: TabContainer = $ScrollContainer/ScrollContent/Unbeatables/TabContainer
onready var sweepers: Control = $ScrollContainer/ScrollContent/Sweepers
onready var sweepers_hall: Control = $ScrollContainer/ScrollContent/Sweepers/TabContainer
onready var cleaners: Control = $ScrollContainer/ScrollContent/Cleaners
onready var cleaners_hall: TabContainer = $ScrollContainer/ScrollContent/Cleaners/TabContainer

# scroll
onready var scroll_container: ScrollContainer = $ScrollContainer
onready var classic_position: float = classic.rect_position.x
onready var unbeatables_position: float = unbeatables.rect_position.x
onready var sweepers_position: float = sweepers.rect_position.x
onready var cleaners_position: float = cleaners.rect_position.x - (scroll_container.rect_size.x - cleaners.rect_size.x) # drugačna, ker je zadnja

func _input(event):
	
	if focused_content == null:
		var content_to_focus: Control
		if selected_hall == unbeatables_hall and get_focus_owner() == unbeatable_tab_btn:
			if Input.is_action_just_pressed("ui_down"):
				focus_hall_content(unbeatables_hall)
		elif selected_hall == sweepers_hall and get_focus_owner() == sweeper_tab_btn:
			if Input.is_action_just_pressed("ui_down"):
				focus_hall_content(sweepers_hall)
					
		elif selected_hall == cleaners_hall and get_focus_owner() == cleaner_tab_btn:
			if Input.is_action_just_pressed("ui_down"):
				focus_hall_content(cleaners_hall)
		else:
			return			
	# če hall je fokusiran se premikam po tabih
	else:
		var tab = focused_content.current_tab
		if Input.is_action_just_pressed("ui_left"):
			tab -= 1
		elif Input.is_action_just_pressed("ui_right"):
			tab += 1
		elif Input.is_action_just_pressed("ui_up"):
			get_focus_owner().release_focus()
			defocus_hall_content()
			get_tree().set_input_as_handled()
			return
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
	
	# naberem tabele
	for hall in halls:
		var hall_table_local: Control = hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = hall.get_node("TablePair/HighscoreTableGlobal")
		# novo hall ime, ker se vidi v tabih
		hall.name = hall.name.trim_suffix("Hall")
		all_local_tables.append(hall_table_local)
		all_global_tables.append(hall_table_global)
		
	for sweeper_hall in all_sweeper_halls:
		var hall_table_local: Control = sweeper_hall.get_node("TablePair/HighscoreTable")
		var hall_table_global: Control = sweeper_hall.get_node("TablePair/HighscoreTableGlobal")
		# novo hall ime, ker se vidi v tabih
		sweeper_hall.name = str(all_sweeper_halls.find(sweeper_hall) + 1)
		all_sweeper_global_tables.append(hall_table_global)
		all_sweeper_local_tables.append(hall_table_local)

	
	# dodam sweeper tabele med vse lokalne
	all_local_tables.append_array(all_sweeper_local_tables)
	all_global_tables.append_array(all_sweeper_global_tables)
	
	# update centriranih pozicij hall holderjev
	var scroll_container_width: float = scroll_container.rect_size.x/2 
	unbeatables_position -= scroll_container_width - unbeatables.rect_size.x/2
	sweepers_position -= scroll_container_width - sweepers.rect_size.x/2
	
	load_all_highscore_tables()

	# classic selected
	select_hall(classic_position)
	
	
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

		
func load_all_highscore_tables(update_tables: bool = false):
	
	print("Updating tables")
	
	# apdejtam lokalne tabele
	for table in all_local_tables:
		var game_data_local: Dictionary
		if all_sweeper_local_tables.has(table):
			game_data_local = Profiles.game_data_sweeper
			game_data_local["level"] = all_sweeper_local_tables.find(table) + 1
		else:	
			var table_index: int = all_local_tables.find(table)
			game_data_local = all_tables_game_data[table_index]
		table.load_highscore_table(game_data_local, fake_player_ranking, Profiles.local_highscores_count)
		table.load_local_to_global_ranks(game_data_local)
	
	
	# apdejtam globalne tabele
	for table in all_global_tables:
		var game_data_local: Dictionary
		if all_sweeper_global_tables.has(table):
			game_data_local = Profiles.game_data_sweeper
			game_data_local["level"] = all_sweeper_global_tables.find(table) + 1
		else:
					
			var table_index: int = all_global_tables.find(table)
			game_data_local = all_tables_game_data[table_index]
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
	
	print ("All tables updated")


# UTILITI --------------------------------------------------------------------------------------------------------------


func select_hall(new_scroll_position: float, focus_content_also: bool = false):
	
	if focused_content:
		defocus_hall_content()
	
	# naberem izbrano pred premikom
	var content_to_deheighlight: Control
	var tab_btn_to_deheighlight: Button
	# če je tab btn izbran
	if not selected_tab_btn == null:
		tab_btn_to_deheighlight = selected_tab_btn
		tab_btn_to_deheighlight.self_modulate = Color.white
		tab_btn_to_deheighlight.get_node("EdgeSelected").hide()
		content_to_deheighlight = get_visible_hall_content(selected_hall)
	
	# setam novo izbrano vsebino
	match new_scroll_position:
		classic_position:
			selected_tab_btn = classic_tab_btn 
			selected_hall = classic_hall
		unbeatables_position:
			selected_tab_btn = unbeatable_tab_btn
			selected_hall = unbeatables_hall
		sweepers_position:
			selected_tab_btn = sweeper_tab_btn
			selected_hall = sweepers_hall
		cleaners_position:
			selected_tab_btn = cleaner_tab_btn
			selected_hall = cleaners_hall	
	
	# printt("S HALL", content_to_deheighlight, selected_hall)
	
	# ugasnem staro vsebino in prižgem novo
	selected_tab_btn.get_node("EdgeSelected").show()
	var scroll_tween = get_tree().create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", new_scroll_position, scroll_tween_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	selected_tab_btn.self_modulate = Global.color_yellow
	yield(scroll_tween, "finished")	
	
	if not content_to_deheighlight == null:
		content_to_deheighlight.get_node("Undi/EdgeSelected").hide()
	
	# fokusiram hall
	if focus_content_also:
#		defocus_hall_content()
		focus_hall_content(selected_hall)	
			
	var content_to_highlight = get_visible_hall_content(selected_hall)
	content_to_highlight.get_node("Undi/EdgeSelected").show()


func get_visible_hall_content(hall: Control):
	
	if hall == classic_hall:
		return classic_hall
	else:
		var open_tab_index: int = hall.current_tab
		var open_tab_content: Control = hall.get_children()[open_tab_index]
		
		return open_tab_content
	
					
func focus_hall_content(content_to_focus: Control):
	
	focused_content = content_to_focus
	focused_content.self_modulate = Color.white
	
	focused_content.focus_mode = Control.FOCUS_ALL		
	focused_content.grab_focus()
	
	# disable focus na prvem nivoju
	for tab_btn in tab_btns.get_children():	
		tab_btn.focus_mode = Control.FOCUS_NONE
	$BackBtn.focus_mode = Control.FOCUS_NONE
	update_scores_btn.focus_mode = Control.FOCUS_NONE
	
	
func defocus_hall_content():
	
	if get_focus_owner():
		get_focus_owner().release_focus()
	
	if not focused_content == null:
		
		# enable focus na prvem nivoju
		for tab_btn in tab_btns.get_children():	
			tab_btn.focus_mode = Control.FOCUS_ALL
		$BackBtn.focus_mode = Control.FOCUS_ALL
		update_scores_btn.focus_mode = Control.FOCUS_ALL	
		
		
		# fokus na zunaji tab
		var tab_btn_to_focus: Button
		match focused_content:
			unbeatables_hall:
				tab_btn_to_focus = unbeatable_tab_btn
			sweepers_hall:
				tab_btn_to_focus = sweeper_tab_btn
			cleaners_hall:
				tab_btn_to_focus = cleaner_tab_btn
				
		tab_btn_to_focus.grab_focus() 


		# disable focus na notranjosti
		focused_content.focus_mode = Control.FOCUS_NONE
		focused_content.self_modulate = Global.color_yellow
		
		
		focused_content = null
		

# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_UpdateScoresBtn_pressed() -> void:
	
	update_scores_btn.disabled = true
	load_all_highscore_tables(true)


func _on_ClassicBtn_pressed() -> void:
	
	select_hall(classic_position)
	
func _on_UnbeatableBtn_pressed() -> void:
	
	select_hall(unbeatables_position)


func _on_SweeperBtn_pressed() -> void:

	select_hall(sweepers_position)


func _on_CleanerBtn_pressed() -> void:
	
	select_hall(cleaners_position)
	



# notranji tabi

func _on_Sweepers_tab_selected(tab: int) -> void:
	
	if selected_hall == sweepers_hall:
		get_focus_owner().release_focus()
		focus_hall_content(sweepers_hall)
	else:
		select_hall(sweepers_position, true)
		pass
	
	
func _on_Unbeatable_tab_selected(tab: int) -> void:

	if selected_hall == unbeatables_hall:
		get_focus_owner().release_focus()
		focus_hall_content(unbeatables_hall)
	else:
		select_hall(unbeatables_position, true)	
	
	
func _on_Cleaner_tab_selected(tab: int) -> void:

	if selected_hall == cleaners_hall:
		get_focus_owner().release_focus()
		focus_hall_content(cleaners_hall)
	else:
		select_hall(cleaners_position, true)
	
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")



