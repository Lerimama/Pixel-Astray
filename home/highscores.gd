extends Control


var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var publish_btn_text: String = "    Publish %s local scores online"

# tables ... zaporedje se mora ujemati v sponjih 3 in z node zaporedjem v drevesu
var all_tables: Array = []
var sweeper_tables: Array = []
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
onready var all_tables_game_data: Array = [
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

# halls za input ... neurejeno (input)
onready var cleaner_hall: Control = $GameHalls/Cleaner/CleanerHall
onready var unbeatables_hall: TabContainer = $GameHalls/Unbeatables/TabContainer
onready var sweepers_hall: Control = $GameHalls/Sweepers/TabContainer
onready var erasers_hall: TabContainer = $GameHalls/Erasers/TabContainer
onready var cleaner_focus_node: Control = cleaner_hall.get_node("HighscoreTable").table_scroller
onready var unbeatables_focus_node: Control
onready var sweepers_focus_node: Control
onready var erasers_focus_node: Control
onready var default_focus_node: Control = update_scores_btn


func _ready() -> void:

	# btns
	back_btn.add_to_group(Batnz.group_cancel_btns)

	if Profiles.html5_mode:
		update_scores_btn.hide()
		publish_unpublished_btn.hide()
		default_focus_node = back_btn

	# naberem tabele
	for hall in halls:
		var hall_table: Control = hall.get_node("HighscoreTable")
		# novo hall ime, ker se vidi v tabih
		hall.name = hall.name.trim_suffix("Hall")
		all_tables.append(hall_table)
	for sweeper_hall in all_sweeper_halls:
		var hall_table: Control = sweeper_hall.get_node("HighscoreTable")
		# novo hall ime, ker se vidi v tabih
		sweeper_hall.name = "%02d" % (all_sweeper_halls.find(sweeper_hall) + 1)
		sweeper_tables.append(hall_table)
	all_tables.append_array(sweeper_tables) # dodam sweeper tabele med vse tabele

	# load HS on start ... with global update? ... premaknjeno v home za boljšo kontrolo glede na vrsto home open


func load_all_highscore_tables(update_with_global: bool, update_in_background: bool = false):

	var update_object_count: int = 0
	for table in all_tables:
		var game_data_local: Dictionary
		if sweeper_tables.has(table):
			game_data_local = Profiles.game_data_sweeper
			game_data_local["level"] = sweeper_tables.find(table) + 1
		else:
			var table_index: int = all_tables.find(table)
			game_data_local = all_tables_game_data[table_index]

		if update_with_global:
			update_object_count += 1
			var update_count_string: String = "%02d/"  % update_object_count + str(all_tables.size())
			var last_table_in_row: Control = all_tables[all_tables.size() - 1]
			if table == last_table_in_row:
				LootLocker.update_lootlocker_leaderboard(game_data_local, true, update_count_string, update_in_background)
				yield(LootLocker, "connection_closed")
				ConnectCover.cover_label_text = "Finished"
				yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
				ConnectCover.close_cover() # odda signal, ko se zapre
			else:
				LootLocker.update_lootlocker_leaderboard(game_data_local, false, update_count_string, update_in_background)
				yield(LootLocker, "leaderboard_updated")

		table.build_highscore_table(game_data_local, false)

	# print ("All tables updated")

	if update_with_global:
		select_level_node.select_level_btns_holder.set_level_btns()

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
			game_data_local = all_tables_game_data[table_index]
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
			game_data_local = all_tables_game_data[table_index]
		table.build_highscore_table(table.table_game_data, fake_player_ranking, false)

	yield(get_tree().create_timer(1), "timeout")
	ConnectCover.cover_label_text = "Finished"
	yield(get_tree().create_timer(0.2), "timeout")
	ConnectCover.close_cover()


# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_BackBtn_pressed() -> void:

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






#func _input(event):
#
#	var node_to_focus: Control
#	var focused_node: Control = get_focus_owner()
#	if Input.is_action_just_pressed("ui_up"):
#		if not focused_node:
#			focused_node = update_scores_btn
#		match focused_node:
#			update_scores_btn:
#				pass
#			cleaner_focus_node:
#				node_to_focus = update_scores_btn
#			sweepers_focus_node:
#				node_to_focus = update_scores_btn
#			unbeatables_focus_node:
#				node_to_focus = back_btn
#			erasers_focus_node:
#				node_to_focus = back_btn
#			back_btn:
#				pass
#
#	elif Input.is_action_just_pressed("ui_down"):
#		if not focused_node:
#			focused_node = update_scores_btn
#		match focused_node:
#			update_scores_btn:
#				node_to_focus = cleaner_focus_node
#			cleaner_focus_node:
#				$GameHalls/Cleaner/Title.modulate = Color.yellow
#				pass
#			sweepers_focus_node:
#				pass
#			unbeatables_focus_node:
#				pass
#			erasers_focus_node:
#				pass
#			back_btn:
#				node_to_focus = erasers_focus_node
#	elif Input.is_action_just_pressed("ui_left"):
#		if not focused_node:
#			focused_node = update_scores_btn
#		match focused_node:
#			update_scores_btn:
#				pass
#			cleaner_focus_node:
#				pass
#			sweepers_focus_node:
#				node_to_focus = cleaner_focus_node
#			unbeatables_focus_node:
#				node_to_focus = sweepers_focus_node
#			erasers_focus_node:
#				node_to_focus = unbeatables_focus_node
#			back_btn:
#				node_to_focus = update_scores_btn
#	elif Input.is_action_just_pressed("ui_right"):
#		if not focused_node:
#			focused_node = update_scores_btn
#		match focused_node:
#			update_scores_btn:
#				node_to_focus = back_btn
#			cleaner_focus_node:
#				node_to_focus = sweepers_focus_node
#			sweepers_focus_node:
#				node_to_focus = unbeatables_focus_node
#			unbeatables_focus_node:
#				node_to_focus = erasers_focus_node
#			erasers_focus_node:
#				pass
#			back_btn:
#				pass
#
#	if node_to_focus:
#		node_to_focus.grab_focus()
