extends Control


var highscores_loaded: bool = false
var fake_player_ranking: int = 0 # številka je ranking izven lestvice, da ni označenega plejerja
var publish_btn_text: String = "    PUBLISH %s LOCAL SCORES ONLINE" # presledek more bit zaradi ikon
var focus_color: Color = Global.color_yellow
var all_tables: Array = []

# jp in kb scrollanje
var scroll_delta: float = 0
var scroll_delta_limit: float = 5
var scroll_delta_tick: float = 0.5
var waiting_for_scroll: bool = false # ko držiš tipko in še ne skorlaš


onready var update_scores_btn: Button = $UpdateScoresBtn
onready var publish_unpublished_btn: Button = $PublishUnpublishedBtn
onready var back_btn: TextureButton = $BackBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var game_halls: HBoxContainer = $GameHalls
onready var default_focus_node: Control = $GameHalls/Cleaner
onready var HighscoresHall: PackedScene = preload("res://home/highscores/highscores_hall.tscn")


func _input(event):

	# ko je fokusiran tab container
	if get_focus_owner():
		if get_focus_owner() is TabContainer:
			var focused_tab_container: TabContainer = get_focus_owner()
			var current_tab_index: int = focused_tab_container.get_current_tab()
			var tab_container_table_scroller: ScrollContainer = focused_tab_container.get_child(current_tab_index).get_child(1).get_node("TableScroller")
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
			# scroll table
			if Input.is_action_pressed("ui_down"):
				scroll_delta += scroll_delta_tick
				tab_container_table_scroller.scroll_vertical += scroll_delta
				get_tree().set_input_as_handled()
			elif Input.is_action_pressed("ui_up"):
				scroll_delta += scroll_delta_tick
				waiting_for_scroll = true
				if scroll_delta > scroll_delta_limit:
					waiting_for_scroll = false
					tab_container_table_scroller.scroll_vertical -= scroll_delta - scroll_delta_limit
				get_tree().set_input_as_handled()
			# defocus na sekcijo
			elif Input.is_action_just_pressed("ui_cancel"):
				get_focus_owner().get_parent().grab_focus()
				get_tree().set_input_as_handled()
			else:
				scroll_delta = 0

			if Input.is_action_just_released("ui_up"):
				if waiting_for_scroll:
					waiting_for_scroll = false
					get_focus_owner().get_parent().grab_focus()

		elif get_focus_owner() == $GameHalls/Cleaner:
			var cleaner_hs_table: Control = get_focus_owner().get_child(1).get_child(1) # ne morem iskat po imenu, ker se node ob bildanju preimenuje
			if cleaner_hs_table.has_node("TableScroller"):
				var container_table_scroller: ScrollContainer = cleaner_hs_table.get_node("TableScroller")
				if Input.is_action_pressed("ui_down"):
					scroll_delta += scroll_delta_tick
					waiting_for_scroll = true
					if scroll_delta > scroll_delta_limit:
						waiting_for_scroll = false
						container_table_scroller.scroll_vertical += scroll_delta
					get_tree().set_input_as_handled()
				elif Input.is_action_pressed("ui_up"):
					scroll_delta += scroll_delta_tick
					waiting_for_scroll = true
					if scroll_delta > scroll_delta_limit:
						waiting_for_scroll = false
					container_table_scroller.scroll_vertical -= scroll_delta
					get_tree().set_input_as_handled()
				else:
					scroll_delta = 0
				if Input.is_action_just_released("ui_down"):
					if waiting_for_scroll:
						waiting_for_scroll = false
						update_scores_btn.grab_focus()
				elif Input.is_action_just_released("ui_up"):
					if waiting_for_scroll:
						waiting_for_scroll = false
						update_scores_btn.grab_focus()


func _ready() -> void:

	# btns
	back_btn.add_to_group(Batnz.group_cancel_btns)

	if Profiles.html5_mode:
		update_scores_btn.hide()
		publish_unpublished_btn.hide()
		default_focus_node = back_btn

	# debug
	for sweeper_hall in $GameHalls/Sweepers/TabContainer.get_children():
		sweeper_hall.queue_free()
	for eraser_hall in $GameHalls/Erasers/TabContainer.get_children():
		eraser_hall.queue_free()

	for sweeper_tilemap_index in Profiles.tilemap_paths[Profiles.Games.SWEEPER].size():
		# spawn
		var new_hall: Control = HighscoresHall.instance()
		$GameHalls/Sweepers/TabContainer.add_child(new_hall)
		# imena tabov in tabel
		var table_level_name: String = Global.get_level_out_of_path(Profiles.tilemap_paths[Profiles.Games.SWEEPER][sweeper_tilemap_index])
		var hall_table: Control = new_hall.get_node("HighscoreTable")
		new_hall.name = table_level_name
		hall_table.name = "Sweeper_" + new_hall.name + "_Table"
		# append
		all_tables.append(hall_table)

	for eraser_tilemap_index in Profiles.tilemap_paths[Profiles.Games.ERASER].size():
		# spawn
		var new_hall: Control = HighscoresHall.instance()
		$GameHalls/Erasers/TabContainer.add_child(new_hall)
		# imena tabov in tabel
		var table_level_name: String = Global.get_level_out_of_path(Profiles.tilemap_paths[Profiles.Games.ERASER][eraser_tilemap_index])
		var hall_table: Control = new_hall.get_node("HighscoreTable")
		new_hall.name = table_level_name
		hall_table.name = "Eraser_" + new_hall.name + "_Table"
		# append
		all_tables.append(hall_table)

	var other_halls: Array = [
		$GameHalls/Cleaner/CleanerHall,
		$GameHalls/Unbeatables/TabContainer/DefenderHall,
		$GameHalls/Unbeatables/TabContainer/HunterHall,
		]
	for hall in other_halls:
		# imena tabov in tabel
		var hall_table: Control = hall.get_node("HighscoreTable")
		hall.name = hall.name.trim_suffix("Hall")
		hall_table.name = hall.name + "Table"
		# append
		all_tables.append(hall_table)

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
		section.get_node("ScrollHint").hide() # s tem je disejblan

	var tab_containers: Array = [$GameHalls/Unbeatables/TabContainer, $GameHalls/Sweepers/TabContainer, $GameHalls/Erasers/TabContainer]
	for container in tab_containers:
		container.connect("focus_entered", self, "_on_hall_focused", [container])
		container.connect("focus_exited", self, "_on_hall_unfocused", [container])


func load_all_highscore_tables(update_with_global: bool, update_in_background: bool = false):

	highscores_loaded = false

	var update_object_count: int = 0
	for table in all_tables:
		var table_game_data: Dictionary = _get_tables_game_data(table)
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
	$"../SelectSweeper".select_level_btns_holder.set_level_btns_content() #
	$"../SelectEraser".select_level_btns_holder.set_level_btns_content() #

	highscores_loaded = true


func publish_all_unpublished_scores():

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

		var game_data_local: Dictionary = _get_tables_game_data(table)
		table.build_highscore_table(table.table_game_data, false)

	yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
	ConnectCover.close_cover()

	get_viewport().set_disable_input(false)


func reset_all_local_scores():

	ConnectCover.open_cover(false)
	ConnectCover.cover_label_text = "Reseting ..."

	for table in all_tables:
		Data.delete_highscores_file(table.table_game_data)

	# rebuild tables
	for table in all_tables:
		var game_data_local: Dictionary = _get_tables_game_data(table)
		table.build_highscore_table(table.table_game_data, fake_player_ranking, false)

	yield(get_tree().create_timer(0.5), "timeout")
	ConnectCover.cover_label_text = "Finished"
	yield(get_tree().create_timer(0.2), "timeout")
	ConnectCover.close_cover()


func _get_tables_game_data(hs_table: Control):

	var hs_table_game_data: Dictionary

	if hs_table.name.begins_with("Cleaner"):
		hs_table_game_data = Profiles.game_data[Profiles.Games.CLEANER]
	elif hs_table.name.begins_with("Sweeper"):
		hs_table_game_data = Profiles.game_data[Profiles.Games.SWEEPER]
		hs_table_game_data["level_name"] = hs_table.name.get_slice("_", 1)
	elif hs_table.name.begins_with("Hunter"):
		hs_table_game_data = Profiles.game_data[Profiles.Games.HUNTER]
	elif hs_table.name.begins_with("Defender"):
		hs_table_game_data = Profiles.game_data[Profiles.Games.DEFENDER]
	elif hs_table.name.begins_with("Eraser"):
		hs_table_game_data = Profiles.game_data[Profiles.Games.ERASER]
		hs_table_game_data["level_name"] = hs_table.name.get_slice("_", 1)

	#	printt("hs_table_game_data", hs_table.name)
	return hs_table_game_data


# HALLS NAV --------------------------------------------------------------------------------------------------------------


func _on_hall_unfocused(hall_unfocused: Control):
	hall_unfocused.self_modulate = Color.white
	# section unfocus
	hall_unfocused.get_node("../Title").modulate = Global.color_gui_gray_trans
	hall_unfocused.get_node("../Undi/Edge").modulate.a = 0
	hall_unfocused.get_node("../ScrollHint").modulate.a = 0


func _on_hall_focused(hall_focused: Control):
	hall_focused.self_modulate = focus_color
	# section focus
	hall_focused.get_node("../ScrollHint").modulate.a = 1
	hall_focused.get_node("../Title").modulate = Global.color_gui_gray_trans
	hall_focused.get_node("../Undi/Edge").modulate = focus_color


func _on_section_focused(focused_section: Control):
	# section focus
	focused_section.get_node("ScrollHint").modulate.a = 1
	focused_section.get_node("Title").modulate = focus_color
	focused_section.get_node("Undi/Edge").modulate = focus_color


func _on_section_unfocused(unfocused_section: Control):
	# section unfocus
	unfocused_section.get_node("ScrollHint").modulate.a = 0
	unfocused_section.get_node("Title").modulate = Global.color_gui_gray_trans
	unfocused_section.get_node("Undi/Edge").modulate.a = 0


# BUTTONS --------------------------------------------------------------------------------------------------------------


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("highscores")
	get_parent().menu_in()


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

