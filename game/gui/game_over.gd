extends Control
class_name GameOver

signal name_input_finished

var player_final_score: float # score je lahko time al pa točke
var game_final_time: float # unrounded hunds
var p1_final_stats: Dictionary
var p2_final_stats: Dictionary

var played_game_key: int # ob odprtju
var gameover_game_data: Dictionary # napolnem ob odprtju
var gameover_reason: int
var new_record_set: bool = false # za barvanje in texte titlov
var current_scoreline_marked: bool = false # za ugotavljanje, kdaj hs table chidren dobijo pozicijo

onready var gameover_menu: HBoxContainer = $Menu
onready var select_level_btns_holder: GridContainer = $GameSummary/ContentSweeper/LevelBtnsHolder/LevelBtnsGrid
onready var header_futer_covers: ColorRect = $HeaderFuterCovers
onready var background: ColorRect = $Background
onready var publish_popup: Control = $PublishPopup
#onready var ranking_score_limit: int = Global.game_manager.game_settings["ranking_score_limit"] # samo points, ker drugače je razlog CLEANED

# gameover title
var selected_gameover_title: Control
var selected_gameover_jingle: String
onready var gameover_title_holder: Control = $GameoverTitle
onready var gameover_title_cleaned: Control = $GameoverTitle/ReasonCleaned
onready var gameover_title_time: Control = $GameoverTitle/ReasonTime
onready var gameover_title_life: Control = $GameoverTitle/ReasonLife
onready var gameover_title_fail: Control = $GameoverTitle/Fail

# game summary
var highscore_table: Control
onready var game_summary: Control = $GameSummary

# name input
var input_string: String
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var name_input_label: Label = $NameInputPopup/Label


func _input(event: InputEvent) -> void: # unhandled ne pride skozi

	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):# and name_input.has_focus():
#			Analytics.save_ui_click("InputCancelEsc")
			Global.sound_manager.play_gui_sfx("btn_cancel")
			_on_CancelBtn_pressed()
			accept_event()
		if Input.is_action_just_pressed("ui_accept"):# and not input_confirm_btn.has_focus():
#			Analytics.save_ui_click("InputConfirmAccept")
			Global.sound_manager.play_gui_sfx("btn_confirm")
			_on_ConfirmBtn_pressed()
			accept_event()


func _ready() -> void:

	Global.gameover_gui = self

	hide()
	gameover_title_holder.hide()
	game_summary.hide()
	name_input_popup.hide()
	gameover_menu.hide()

	# menu btn group
	$Menu/RestartBtn.add_to_group(Batnz.group_critical_btns)
	$Menu/QuitBtn.add_to_group(Batnz.group_critical_btns)

	$Menu/QuitBtn.add_to_group(Batnz.group_cancel_btns)
	$Menu/ExitGameBtn.add_to_group(Batnz.group_cancel_btns)
	.add_to_group(Batnz.group_cancel_btns)

	if Profiles.html5_mode:
		$Menu/ExitGameBtn.hide()
		$Menu/QuitBtn.focus_neighbour_left = "../RestartBtn"
		$Menu/RestartBtn.focus_neighbour_right = "../QuitBtn"


func _process(delta: float) -> void:

	# za ugotavljanje, kdaj hs table chidren dobijo pozicijo
	if visible:
		if highscore_table and not current_scoreline_marked:
			if gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME and not gameover_reason == Global.game_manager.GameoverReason.CLEANED:
				pass
			else:
				var second_scoreline = highscore_table.hs_table.get_child(1) # prvi ima vedno pozicijo 0
				if not second_scoreline.rect_position.y == 0:
					current_scoreline_marked = true
					highscore_table.scroll_to_scoreline(player_final_score, p1_final_stats["player_name"], gameover_game_data["highscore_type"])


func open_gameover(current_gameover_reason: int):

#	Analytics.save_selected_game_data([true, Global.game_manager.strays_in_game_count])
	Profiles.tutorial_mode = false

	gameover_game_data = Global.game_manager.game_data
	played_game_key = Global.game_manager.game_data["game"]
	gameover_reason = current_gameover_reason
	p1_final_stats = Global.game_manager.current_players_in_game[0].player_stats
	game_final_time = Global.hud.game_timer.game_time_hunds
	new_record_set = Global.hud.new_record_set

	if played_game_key == Profiles.Games.THE_DUEL:
		p2_final_stats = Global.game_manager.current_players_in_game[1].player_stats
		_set_duel_gameover_title()
	else:
		if gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: # kadar se meri čas, obstaja cilj, da rankiraš
			player_final_score = game_final_time
		else:
			player_final_score = p1_final_stats["player_points"]
		_set_gameover_title()

	show_gameover_title()


func show_gameover_title():

	visible = true
	selected_gameover_title.show()
	gameover_title_holder.modulate.a = 0
	var background_alpha: float = 0.9 # cca 230

	get_tree().set_pause(true) # setano čez celotno GO proceduro

	# animacija
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(gameover_title_holder, "show")
	fade_in.tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property(gameover_title_holder, "modulate:a", 1, 0.7).set_ease(Tween.EASE_IN)
	fade_in.parallel().tween_property(background, "modulate:a", background_alpha, 0.5).set_ease(Tween.EASE_IN).set_delay(0.2)

	# skrije futer in header, če ni zoomouta
	if Global.game_manager.game_settings["always_zoomed_in"]:
		fade_in.parallel().tween_property(header_futer_covers, "modulate:a", 1, 0.7).set_ease(Tween.EASE_IN)
	yield(fade_in, "finished")

	# summary or menu
	if gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:
		show_menu()
		return
	# vpis, če je sweeper je CLEANED
	elif gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME and gameover_reason == Global.game_manager.GameoverReason.CLEANED:
		_open_name_input()
		yield(self, "name_input_finished")
	# vpis, ostale igre in je score na limitom
	elif gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS and player_final_score > Global.game_manager.game_settings["ranking_score_limit"]: # samo points, ker drugače je razlog CLEANED:
		_open_name_input()
		yield(self, "name_input_finished")
	# ni vpisa, če ne ustreza
	else:
		yield(get_tree().create_timer(Global.get_it_time), "timeout")
		var title_fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		title_fade_out.tween_property(gameover_title_holder, "modulate:a", 0, 0.5)
		title_fade_out.tween_callback(gameover_title_holder, "hide")
		yield(title_fade_out, "finished")

	_set_game_summary()


func show_game_summary():

	# hide title and name_popup > show game summary
	game_summary.modulate.a = 0
	game_summary.visible = true
	var summary_fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	summary_fade_in.tween_property(game_summary, "modulate:a", 1, 0.7).set_delay(0.2).set_ease(Tween.EASE_IN)
	summary_fade_in.parallel().tween_callback(self, "show_menu").set_delay(0.2)


func show_menu():

	var restart_btn: Button = $Menu/RestartBtn
	var focus_btn: Button = restart_btn
	if Profiles.tilemap_paths[played_game_key].size() > 1:
		for level_btn in select_level_btns_holder.all_level_btns:
			if level_btn.name.ends_with(gameover_game_data["level_name"]):
				focus_btn = level_btn
	elif played_game_key == Profiles.Games.THE_DUEL:
		restart_btn.text = "REMATCH"

	gameover_menu.modulate.a = 0
	gameover_menu.show()
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(gameover_menu, "show")
	fade_in.tween_property(gameover_menu, "modulate:a", 1, 0.5).set_ease(Tween.EASE_IN)
	yield(fade_in,"finished")
	get_viewport().set_disable_input(false) # na začetku se disejbla do konca publishanja
	focus_btn.grab_focus()


func play_selected_level(selected_level: String):

	Profiles.game_data[played_game_key]["level_name"] = selected_level

	# set sweeper level
	Global.game_manager.game_settings["pregame_screen_on"] = false

	#	Analytics.save_selected_game_data([true, Global.game_manager.strays_in_game_count])
	Global.main_node.reload_game()



# SETUP ----------------------------------------------------------------------------------------


#func _set_gameover_title():
#
#	match gameover_reason:
#		Global.game_manager.GameoverReason.CLEANED:
#			selected_gameover_jingle = "win_jingle"
#			selected_gameover_title = gameover_title_cleaned
#			selected_gameover_title.modulate = Global.color_green
#			name_input_label.text = Profiles.game_text["name_input_label_GOOD"]
#			selected_gameover_title.get_node("Subtitle").text = Profiles.game_data[played_game_key]["game_over_subtitle_CLEANED"]
#		Global.game_manager.GameoverReason.LIFE:
#			selected_gameover_jingle = "lose_jingle"
#			selected_gameover_title = gameover_title_life
#			selected_gameover_title.modulate = Global.color_red
#			name_input_label.text = Profiles.game_text["name_input_label_BAD"]
#			if played_game_key == Profiles.Games.SWEEPER:
#				selected_gameover_title = gameover_title_fail
#			selected_gameover_title.get_node("Subtitle").text = Profiles.game_data[played_game_key]["game_over_subtitle_LIFE"]
#		Global.game_manager.GameoverReason.TIME:
#			selected_gameover_jingle = "lose_jingle"
#			selected_gameover_title = gameover_title_time
#			selected_gameover_title.modulate = Global.color_red
#			name_input_label.text = Profiles.game_text["name_input_label_BAD"]
#			if played_game_key == Profiles.Games.CLEANER:
#				selected_gameover_title.get_node("Subtitle").text = Profiles.game_data[played_game_key]["game_over_subtitle_TIME"]
#				if player_final_score > Global.game_manager.game_settings["ranking_score_limit"]: # _temp go reason
#					selected_gameover_jingle = "win_jingle"
#					name_input_label.text = Profiles.game_text["name_input_label_GOOD"]
#					selected_gameover_title.modulate = Global.color_green
#			selected_gameover_title.get_node("Subtitle").text = Profiles.game_data[played_game_key]["game_over_subtitle_TIME"]
#
#	# rekord povozi vse
#	if new_record_set:
#		selected_gameover_jingle = "win_jingle"
#		name_input_label.text = Profiles.game_text["name_input_label_GOOD"]
#		selected_gameover_title.modulate = Global.color_green
#		selected_gameover_title.get_node("Subtitle").text = Profiles.game_data[played_game_key]["game_over_subtitle_RECORD"]


func _set_gameover_title():

	match gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			name_input_label.text = "Great work!"
			selected_gameover_jingle = "win_jingle"
			selected_gameover_title = gameover_title_cleaned
			selected_gameover_title.modulate = Global.color_green
			if played_game_key == Profiles.Games.SWEEPER:
				selected_gameover_title.get_node("Subtitle").text = "That was impressive!"
			else:
				selected_gameover_title.get_node("Subtitle").text = "You are the brightest of them all!"
		Global.game_manager.GameoverReason.LIFE:
			name_input_label.text = "But still ... "
			selected_gameover_jingle = "lose_jingle"
			if played_game_key == Profiles.Games.SWEEPER:
				selected_gameover_title = gameover_title_fail
				selected_gameover_title.get_node("Subtitle").text = "You missed the target."
			else:
				selected_gameover_title = gameover_title_life
				selected_gameover_title.get_node("Subtitle").text = "Can't handle the colors?"
			selected_gameover_title.modulate = Global.color_red
		Global.game_manager.GameoverReason.TIME:
			name_input_label.text = "But still ... "
			selected_gameover_jingle = "lose_jingle"
			selected_gameover_title = gameover_title_time
			selected_gameover_title.modulate = Global.color_red
			if played_game_key == Profiles.Games.SWEEPER:
				selected_gameover_title.get_node("Subtitle").text = "You need to be faster!"
			elif played_game_key == Profiles.Games.ERASER: # ostanejo samo beli
				selected_gameover_title.get_node("Subtitle").text = "Can't handle the White?"
			elif played_game_key == Profiles.Games.CLEANER:
				selected_gameover_title.get_node("Subtitle").text = "Time is up!"
				if player_final_score > Global.game_manager.game_settings["ranking_score_limit"]: # _temp go reason
					selected_gameover_jingle = "win_jingle"
					name_input_label.text = "Great work!"
					selected_gameover_title.modulate = Global.color_green
			elif played_game_key == Profiles.Games.HUNTER:
				selected_gameover_title.get_node("Subtitle").text = "Your screen is drowning in colors."
			elif played_game_key == Profiles.Games.DEFENDER:
				selected_gameover_title.get_node("Subtitle").text = "You were overpowered."
			else:
				selected_gameover_title.get_node("Subtitle").text = "Can't handle the time?"

	# rekord povozi vse
	if new_record_set:
		selected_gameover_jingle = "win_jingle"
		name_input_label.text = "Great work!"
		selected_gameover_title.get_node("Subtitle").text = "You've set a new record!"
		selected_gameover_title.modulate = Global.color_green


func _set_duel_gameover_title():

	selected_gameover_title = $GameoverTitle/Duel
	selected_gameover_jingle = "win_jingle"

	var winner_label: Label = selected_gameover_title.get_node("Win/PlayerLabel")
	var winning_reason_label: Label = selected_gameover_title.get_node("Win/ReasonLabel")
	var loser_name: String
	var draw_label: Label = selected_gameover_title.get_node("Draw/DrawLabel")

	# če je kdo brez lajfa, zmaga preživeli
	if p1_final_stats["player_life"] == 0 and p2_final_stats["player_life"] > 0: # P1 zmaga
		selected_gameover_title.get_node("Win").visible = true
		loser_name = "Player 2"
#		winning_reason_label.text = "Player 2 couldn't handle all the saturation."
		winning_reason_label.text = loser_name + Profiles.game_data[played_game_key]["game_over_subtitle_LIFE"]
		return
	elif p2_final_stats["player_life"] == 0 and p1_final_stats["player_life"] > 0: # P2 zmaga
		selected_gameover_title.get_node("Win").visible = true
		loser_name = "Player 1"
#		winning_reason_label.text = "Player 1 couldn't handle all the saturation."
		winning_reason_label.text = loser_name + Profiles.game_data[played_game_key]["game_over_subtitle_LIFE"]
		return
#match gameover_reason:
#			Global.game_manager.GameoverReason.CLEANED:
	# če sta oba preživela ali oba umrla
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	if points_difference == 0: # draw
		selected_gameover_title.get_node("Draw").visible = true
		draw_label.text = Profiles.game_data[played_game_key]["game_over_subtitle_TIME_DRAW"]
#		draw_label.text = "You both collected the same amount of points."
	else: # win
		selected_gameover_title.get_node("Win").visible = true
		if points_difference > 0: # P1 zmaga
			winner_label.text = "Player 1"
			loser_name = "Player 2"
		elif points_difference < 0: # P2 zmaga
			winner_label.text = "Player 2"
			loser_name = "Player 1"
		if abs(points_difference) == 1:
			winning_reason_label.text = winner_label.text + Profiles.game_data[played_game_key]["game_over_subtitle_TIME_TIGHT"]
		else:
			winning_reason_label.text =  winner_label.text + Profiles.game_data[played_game_key]["game_over_subtitle_TIME_WIN"] % str(abs(points_difference)) + loser_name + "."
#			winning_reason_label.text =  winner_label.text + " was " + str(abs(points_difference)) + " points better than " + loser_name + "."


func _set_game_summary():

	# set content node
	var selected_content: Control
	if Profiles.tilemap_paths[played_game_key].size() > 1:
		selected_content = $GameSummary/ContentSweeper
	else:
		selected_content = $GameSummary/Content

	# hs table
	highscore_table = selected_content.get_node("Hs/HighscoreTable")
	highscore_table.build_highscore_table(gameover_game_data, true, false)

	# data panel nodes
	var summary_title: Label = selected_content.get_node("Title")
	var stats_title: Label = selected_content.get_node("Data/DataContainer/Title")
	var stat_level_reached: Label = selected_content.get_node("Data/DataContainer/Level")
	var stat_score: Label = selected_content.get_node("Data/DataContainer/Points")
	var stat_time: Label = selected_content.get_node("Data/DataContainer/Time")
	var stat_colors_collected: Label = selected_content.get_node("Data/DataContainer/PixelsOff")
	var stat_pixels_astray: Label = selected_content.get_node("Data/DataContainer/AstrayPixels")
	var stat_pixels_traveled: Label = selected_content.get_node("Data/DataContainer/CellsTraveled")
	var stat_bursts_count: Label = selected_content.get_node("Data/DataContainer/BurstCount")
	var stat_skills_used: Label = selected_content.get_node("Data/DataContainer/SkillsUsed")

	if played_game_key == Profiles.Games.SWEEPER:
		summary_title.text = "Sweeper %s Summary" % gameover_game_data["level_name"]
		stats_title.text = "Game stats"
		stat_time.text = "Time: " + Global.get_clock_time(player_final_score)
		stat_pixels_astray.text = "Pixels left astray: " + str(Global.game_manager.strays_in_game_count)
		# select level btns
		select_level_btns_holder.btns_holder_parent = self
		select_level_btns_holder.spawn_level_btns(Profiles.Games.SWEEPER)
		select_level_btns_holder.set_level_btns_content()
		# summary content show/hide
		$GameSummary/ContentSweeper.show()
		$GameSummary/Content.hide()
	elif played_game_key == Profiles.Games.ERASER:
		summary_title.text = "Eraser %s Summary" % gameover_game_data["level_name"]
		stats_title.text = "Game stats"
		stat_time.text = "Time: " + Global.get_clock_time(player_final_score)
		stat_pixels_astray.text = "Pixels left astray: " + str(Global.game_manager.strays_in_game_count)
		# select level btns
		select_level_btns_holder.btns_holder_parent = self
		select_level_btns_holder.spawn_level_btns(Profiles.Games.ERASER)
		select_level_btns_holder.set_level_btns_content()
		# summary content show/hide
		$GameSummary/ContentSweeper.show()
		$GameSummary/Content.hide()
	else:
		summary_title.text = "%s Summary" % gameover_game_data["game_name"]
		stats_title.text = "Game stats"
		# level reached, če je level game
		if Global.game_manager.current_level > 0:
			stat_level_reached.text = "Level reached: " + str(Global.game_manager.current_level)
			stat_level_reached.show()
		else:
			stat_level_reached.hide()
		# stats
		stat_score.text = "Score total: " + str(p1_final_stats["player_points"])
		if gameover_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: # kadar se meri čas, obstaja cilj, da rankiraš
			stat_time.show()
			stat_time.text = "Time: " + Global.get_clock_time(player_final_score)
		else:
			stat_time.hide()
		stat_colors_collected.text = "Colors collected: " + str(p1_final_stats["colors_collected"])
		stat_pixels_astray.text = "Pixels left astray: " + str(Global.game_manager.strays_in_game_count)
		stat_pixels_traveled.text = "Pixels traveled: " + str(p1_final_stats["cells_traveled"])
		stat_bursts_count.text = "Bursts count: " + str(p1_final_stats["burst_count"])
		stat_skills_used.text = "Skills used: " + str(p1_final_stats["skill_count"])
		# summary content show/hide
		$GameSummary/Content.show()
		$GameSummary/ContentSweeper.hide()

	# summary title color
	if gameover_reason == Global.game_manager.GameoverReason.CLEANED or new_record_set:
		summary_title.modulate = Global.color_green
	else:
		summary_title.modulate = Global.color_red

	show_game_summary() # meni pokažem v tej funkciji


# NAME INPUT -----------------------------------------------------------------------------------


func _open_name_input():

	name_input.placeholder_text = ""
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0
	var fade_in_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	yield(fade_in_tween, "finished")
	Batnz.grab_focus_nofx(name_input)
	name_input.select_all()


func _on_NameEdit_text_changed(new_text: String) -> void:
	# signal, ki redno beleži vnešeni string

	input_string = new_text
	Global.sound_manager.play_gui_sfx("typing")


func _on_PopupNameEdit_text_entered(new_text: String) -> void: # ko stisneš return

	_on_ConfirmBtn_pressed()


func _on_ConfirmBtn_pressed() -> void:


	if input_string.empty(): # če je prazen, je kot bi kenslal
		_on_CancelBtn_pressed()
	else:
		var input_confirm_btn: Button = $NameInputPopup/HBoxContainer/InputConfirmBtn
		input_confirm_btn.grab_focus()
		confirm_name_input()


func confirm_name_input():

	name_input.editable = false

	# pogrebam string in zapišem ime v končno statistiko igralca
	p1_final_stats["player_name"] = input_string

	Data.save_player_score(player_final_score, gameover_game_data)

	# skrijem samo input (GO title se skrije s popupom)
	var input_fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	input_fade_out.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	input_fade_out.tween_callback(name_input_popup, "hide")
	yield(input_fade_out, "finished")

	# publish
	if Profiles.html5_mode:
		publish_popup.publish_score()
	else:
		publish_popup.open_popup()
	yield(publish_popup, "score_published")
	publish_popup.close_popup()

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(gameover_title_holder, "modulate:a", 0, 0.5)
	fade_out.tween_callback(gameover_title_holder, "hide")
	yield(fade_out, "finished")

	emit_signal("name_input_finished") # sporočim DM, da sem končal (ime povleče iz GO stats) ... on kliče "highscores_updated"


func _on_CancelBtn_pressed() -> void:

	var input_cancel_btn: Button = $NameInputPopup/HBoxContainer/InputCancelBtn
	input_cancel_btn.grab_focus()

	name_input.editable = false

	# skrijem input in GO title
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade_out.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 0.5)
	fade_out.tween_callback(name_input_popup, "hide")
	fade_out.parallel().tween_callback(gameover_title_holder, "hide")
	yield(fade_out, "finished")

	emit_signal("name_input_finished") # sporočim DM, da sem končal (ime povleče iz GO stats) ... on kliče "highscores_updated"


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:

#	Analytics.save_selected_game_data([true, Global.game_manager.strays_in_game_count])

	if Profiles.tilemap_paths[played_game_key].size() > 1:
		Profiles.game_data[played_game_key]["level_name"] = gameover_game_data["level_name"]

	Global.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

	Global.main_node.game_out(played_game_key)


func _on_ExitGameBtn_pressed() -> void:

	Global.main_node.quit_exit_game()
