extends Control


var highscores_loaded: bool = false
var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var publish_btn_text: String = "    Publish %s local scores online"
var focus_color: Color = Global.color_yellow

# tables ... zaporedje se mora ujemati v sponjih 3 in z node zaporedjem v drevesu
var all_tables: Array = []
var sweeper_tables: Array = []
var hall_tables: Array = []
onready var halls: Array = [
	$GameHalls/Cleaner/CleanerHall,
	$GameHalls/Erasers/TabContainer/XSHall,
	$GameHalls/Erasers/TabContainer/SHall,
	$GameHalls/Erasers/TabContainer/MHall,
	$GameHalls/Erasers/TabContainer/LHall,
	$GameHalls/Erasers/TabContainer/XLHall,
	$GameHalls/Unbeatables/TabContainer/HunterHall,
	$GameHalls/Unbeatables/TabContainer/DefenderHall,
	]
onready var all_sweeper_halls: Array = [ # na ready jih dodam med vse halls
	$GameHalls/Sweepers/TabContainer/Sweeper1Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper2Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper3Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper4Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper5Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper6Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper7Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper8Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper9Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper10Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper11Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper12Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper13Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper14Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper15Hall,
	$GameHalls/Sweepers/TabContainer/Sweeper16Hall
	]
onready var hall_tables_game_data: Array = [
	Profiles.game_data_cleaner,
	Profiles.game_data_eraser_xs,
	Profiles.game_data_eraser_s,
	Profiles.game_data_eraser_m,
	Profiles.game_data_eraser_l,
	Profiles.game_data_eraser_xl,
	Profiles.game_data_hunter,
	Profiles.game_data_defender,
	]

onready var update_scores_btn: Button = $UpdateScoresBtn
onready var publish_unpublished_btn: Button = $PublishUnpublishedBtn
onready var back_btn: TextureButton = $BackBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var select_level_node: Control = $"../SelectLevel"
onready var game_halls: HBoxContainer = $GameHalls
onready var default_focus_node: Control = update_scores_btn

# jp in kb scrollanje

var sw_hs_table
var scroll_delta: float = 0
var scroll_stopped: bool = true


func _input(event):

	# ko je fokusiran tab container
	if get_focus_owner() and get_focus_owner() is TabContainer:

		var focused_tab_container: TabContainer = get_focus_owner()
		var current_tab_index: int = focused_tab_container.get_current_tab()
		# tab select
		if Input.is_action_just_pressed("ui_right"):
			if current_tab_index == focused_tab_container.get_tab_count() - 1:
				focused_tab_container.current_tab = 0
			else:
				focused_tab_container.current_tab = current_tab_index + 1
			get_tree().set_input_as_handled()
		elif Input.is_action_just_pressed("ui_left"):
			if current_tab_index == 0:
				focused_tab_container.current_tab = focused_tab_container.get_tab_count() - 1
			else:
				focused_tab_container.current_tab = current_tab_index - 1
			get_tree().set_input_as_handled()
#		elif Input.is_action_pressed("ui_down"):
#			scroll_delta += 0.1
#			if scroll_delta > 10 and scroll_stopped:
#				scroll_stopped = false
#				sw_hs_table.scroll_vertical += scroll_delta
#			elif scroll_delta < 10:
#				print (scroll_delta)
#			get_tree().set_input_as_handled()
		elif Input.is_action_just_pressed("ui_cancel"):
			get_focus_owner().get_parent().grab_focus()
			get_tree().set_input_as_handled()


func _ready() -> void:

	# btns
	back_btn.add_to_group(Batnz.group_cancel_btns)

	if Profiles.html5_mode:
		update_scores_btn.hide()
		publish_unpublished_btn.hide()
		default_focus_node = back_btn

	# naberem tabele
	for sweeper_hall in all_sweeper_halls:
		var hall_table: Control = sweeper_hall.get_node("HighscoreTable")
		# novo hall ime, ker se vidi v tabih
		sweeper_hall.name = "%02d" % (all_sweeper_halls.find(sweeper_hall) + 1)
		hall_table.name = "Sweeper" + sweeper_hall.name + "Table"
		sweeper_tables.append(hall_table)
	for hall in halls:
		var hall_table: Control = hall.get_node("HighscoreTable")
		# novo hall ime, ker se vidi v tabih
		hall.name = hall.name.trim_suffix("Hall")
		hall_table.name = hall.name + "Table"
		hall_tables.append(hall_table)
	all_tables = sweeper_tables.duplicate()
	all_tables.append_array(hall_tables)

	# premik frontalnih tabel na vrh
	var first_update_table_names: Array = ["Cleaner", "01", "XS", "Hunter"]
	first_update_table_names.invert()
	for first_table_name in first_update_table_names: # zadnjo dam najprej spredaj ...
		for table in all_tables:
			if table.get_parent().name == first_table_name:
				var table_to_move = all_tables.pop_at(all_tables.find(table))
				all_tables.push_front(table_to_move)
				break

	# hall connect and start lnf
	var section_nodes: Array = [$GameHalls/Cleaner, $GameHalls/Sweepers, $GameHalls/Erasers, $GameHalls/Unbeatables]
	for section in section_nodes:
		section.connect("focus_entered", self, "_on_section_focused", [section])
		section.connect("focus_exited", self, "_on_section_unfocused", [section])
		section.get_node("Title").modulate = Global.color_gui_gray_trans

	var tab_containers: Array = [$GameHalls/Unbeatables/TabContainer, $GameHalls/Sweepers/TabContainer, $GameHalls/Erasers/TabContainer]
	for container in tab_containers:
		container.connect("focus_entered", self, "_on_hall_focused", [container])
		container.connect("focus_exited", self, "_on_hall_unfocused", [container])

	sw_hs_table = $GameHalls/Sweepers/TabContainer.get_child(0).get_child(1).get_node("TableScroller")
	print(sw_hs_table)
	sw_hs_table.connect("scroll_ended", self, "_on_hall_scroll_ended")
	sw_hs_table.connect("scroll_started", self, "_on_hall_scroll_ended")


func load_all_highscore_tables(update_with_global: bool, update_in_background: bool = false):

	highscores_loaded = false

	var update_object_count: int = 0
	for table in all_tables:
		var table_game_data: Dictionary
		if sweeper_tables.has(table):
			table_game_data = Profiles.game_data_sweeper
			table_game_data["level"] = sweeper_tables.find(table) + 1
		else:
			var table_index: int = hall_tables.find(table)
			table_game_data = hall_tables_game_data[table_index]

		if update_with_global:
			update_object_count += 1
			var update_count_string: String = "%02d/"  % update_object_count + str(all_tables.size())
			var last_table_in_row: Control = all_tables[all_tables.size() - 1]
			if table == last_table_in_row:
				LootLocker.update_lootlocker_leaderboard(table_game_data, true, update_count_string, update_in_background)
				yield(LootLocker, "connection_closed")
				ConnectCover.cover_label_text = "Finished"
				yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
				ConnectCover.close_cover() # odda signal, ko se zapre
			else:
				LootLocker.update_lootlocker_leaderboard(table_game_data, false, update_count_string, update_in_background)
				yield(LootLocker, "leaderboard_updated")

		table.build_highscore_table(table_game_data, false)

	# print ("All tables updated")

	# zapišem število neobjavljenih
	var all_unpublished_scores_count: int = 0
	for table in all_tables:
		all_unpublished_scores_count += table.unpublished_local_scores.size()
	if all_unpublished_scores_count > 0 and not Profiles.html5_mode:
		publish_unpublished_btn.text = publish_btn_text % str(all_unpublished_scores_count)
		publish_unpublished_btn.show()
	else:
		publish_unpublished_btn.hide()

	# after focus
	if update_with_global and not update_in_background: # samo kadar je na HOF ekranu
		Batnz.grab_focus_nofx(default_focus_node)

	# ponovno seta vsebino (brez tilemapa)
	select_level_node.select_level_btns_holder.set_level_btns_content() # _temp ... povzroča nek error ...

	highscores_loaded = true


func publish_all_unpublished_scores():

#	disable_btns()
	get_viewport().set_disable_input(true)

	var tables_to_update: Array = []
	for table in all_tables:
		if not table.unpublished_local_scores.empty():
			table.publish_unpublished_scores()
			tables_to_update.append(table)
			yield(LootLocker, "connection_closed")
	ConnectCover.cover_label_text = "Finished"

	# v gumb zapišem število neobjavljenih
	publish_unpublished_btn.hide()

	# rebuild tables
	for table in tables_to_update:
		var game_data_local: Dictionary
		if sweeper_tables.has(table):
			game_data_local = Profiles.game_data_sweeper
			game_data_local["level"] = sweeper_tables.find(table) + 1
		else:
			var table_index: int = all_tables.find(table)
			game_data_local = hall_tables_game_data[table_index]
		table.build_highscore_table(table.table_game_data, false)

	yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
	ConnectCover.close_cover()

#	disable_btns(false)
	get_viewport().set_disable_input(false)


func reset_all_local_scores():

	ConnectCover.open_cover(false)
	ConnectCover.cover_label_text = "Reseting ..."

	for table in all_tables:
		Data.delete_highscores_file(table.table_game_data)

	# rebuild tables
	for table in all_tables:
		var game_data_local: Dictionary
		if sweeper_tables.has(table):
			game_data_local = Profiles.game_data_sweeper
			game_data_local["level"] = sweeper_tables.find(table) + 1
		else:
			var table_index: int = all_tables.find(table)
			game_data_local = hall_tables_game_data[table_index]
		table.build_highscore_table(table.table_game_data, fake_player_ranking, false)

	yield(get_tree().create_timer(1), "timeout")
	ConnectCover.cover_label_text = "Finished"
	yield(get_tree().create_timer(0.2), "timeout")
	ConnectCover.close_cover()


# HALLS NAV --------------------------------------------------------------------------------------------------------------


func _on_hall_unfocused(hall_unfocused: Control):
	hall_unfocused.self_modulate = Color.white


func _on_hall_focused(hall_focused: Control):
	hall_focused.self_modulate = focus_color
	hall_focused.get_parent().get_node("Title").modulate = focus_color


func _on_section_focused(focused_section: Control):
	focused_section.get_node("Title").modulate = focus_color


func _on_section_unfocused(unfocused_section: Control):
	unfocused_section.get_node("Title").modulate = Global.color_gui_gray_trans


func _on_hall_scroll_ended():
	print("scroll STOP")
	scroll_delta = 0
	scroll_stopped = true



# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")


func _on_UpdateScoresBtn_pressed() -> void:

	update_scores_btn.release_focus()
#	update_scores_btn.disabled = true
	load_all_highscore_tables(true, false) # update, in front


func _on_UpdateScoresBtn_focus_entered() -> void:

	if not update_scores_btn.disabled:
		update_scores_btn.get_child(0).modulate = Global.color_btn_focus


func _on_UpdateScoresBtn_focus_exited() -> void:

	if not update_scores_btn.disabled:
		update_scores_btn.get_child(0).modulate = Global.color_btn_enabled


func _on_PUnpScoresBtn_pressed() -> void:

	publish_all_unpublished_scores()


func _on_PUnpScoresBtn_focus_entered() -> void:

	if not publish_unpublished_btn.disabled:
		publish_unpublished_btn.get_child(0).modulate = Global.color_btn_focus


func _on_PUnpScoresBtn_focus_exited() -> void:

	if not publish_unpublished_btn.disabled:
		publish_unpublished_btn.get_child(0).modulate = Global.color_btn_enabled

