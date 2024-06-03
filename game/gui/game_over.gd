extends Control
class_name GameOver


signal name_input_finished

var p1_final_stats: Dictionary
var p2_final_stats: Dictionary
var current_gameover_reason: int
var score_is_ranking # včasih bool včasih object?!
var sweeper_solved: bool = false				

# menu
onready var gameover_menu: HBoxContainer = $Menu
		
# gameover title
var selected_gameover_title: Control
var selected_gameover_jingle: String
onready var gameover_title_holder: Control = $GameoverTitle
onready var gameover_title_cleaned: Control = $GameoverTitle/ReasonCleaned
onready var gameover_title_time: Control = $GameoverTitle/ReasonTime
onready var timeup_label: Label = $GameoverTitle/ReasonTime/TimeupLabel
onready var gameover_title_life: Control = $GameoverTitle/ReasonLife
onready var background: ColorRect = $Background

# game summary
onready var game_summary: Control = $GameSummary
onready var game_summary_tables: Control = $GameSummary/Tables
onready var gameover_stat_points: Label = game_summary_tables.get_node("DataContainer/Points")
onready var gameover_stat_time: Label = game_summary_tables.get_node("DataContainer/Time")
onready var gameover_stat_pixels_off: Label = game_summary_tables.get_node("DataContainer/PixelsOff")
onready var gameover_stat_astray_pixels: Label = game_summary_tables.get_node("DataContainer/AstrayPixels")
onready var gameover_stat_game: Label = game_summary_tables.get_node("DataContainer/Game")
onready var gameover_stat_level: Label = game_summary_tables.get_node("DataContainer/Level")
onready var gameover_stat_cells_traveled: Label = game_summary_tables.get_node("DataContainer/CellsTraveled")
onready var gameover_stat_burst_count: Label = game_summary_tables.get_node("DataContainer/BurstCount")
onready var gameover_stat_skills_used: Label = game_summary_tables.get_node("DataContainer/SkillsUsed")
onready var gameover_stats_title: Label = game_summary_tables.get_node("DataContainer/Title")
onready var highscore_table: VBoxContainer = $GameSummary/Tables/HighscoreTable

# name input
var input_string: String
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var name_input_label: Label = $NameInputPopup/Label


func _input(event: InputEvent) -> void:

	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
		if Input.is_action_just_pressed("ui_accept"):
			_on_ConfirmBtn_pressed()
			accept_event()
			
	# change focus sounds
	if (gameover_menu != null and gameover_menu.modulate.a == 1) or (game_summary.visible and game_summary.modulate.a == 1):
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_gui = self
	
	visible = false
	gameover_title_holder.visible = false
	game_summary.visible = false
	name_input_popup.visible = false
	gameover_menu.visible = false	

		
func open_gameover(gameover_reason: int):
	
	current_gameover_reason = gameover_reason
	
	p1_final_stats = Global.game_manager.current_players_in_game[0].player_stats
	
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		p2_final_stats = Global.game_manager.current_players_in_game[1].player_stats
		set_duel_gameover_title()
	else:
		if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW: # kadar se meri čas, obstaja cilj, da rankiraš
			if current_gameover_reason == Global.game_manager.GameoverReason.CLEANED:
				score_is_ranking = Global.data_manager.manage_gameover_highscores(get_current_score(), Global.game_manager.game_data) 
				# yield čaka na konec preverke ... tip ni opredeljen, ker je ranking, če ni skora kot objecta, če je ranking
		else:
			score_is_ranking = Global.data_manager.manage_gameover_highscores(get_current_score(), Global.game_manager.game_data) 
			# yield čaka na konec preverke ... tip ni opredeljen, ker je ranking, če ni skora kot objecta, če je ranking
		set_gameover_title()
		
	Global.hud.slide_out()
	yield(Global.game_camera, "zoomed_out")
	
	show_gameover_title()	
		
			
func set_gameover_title():
	
	var gameover_subtitle: Label
	
	# najprej standard text
	match current_gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_gameover_title = gameover_title_cleaned
			gameover_subtitle = selected_gameover_title.get_child(1)
			gameover_subtitle.text = "You are full of colors again!"
			name_input_label.text = "Great work!"
			selected_gameover_jingle = "win_jingle"
		Global.game_manager.GameoverReason.LIFE:
			selected_gameover_title = gameover_title_life
			gameover_subtitle = selected_gameover_title.get_child(1)
			gameover_subtitle.text = "You are forever colorless!"
			name_input_label.text = "But still ... "
			selected_gameover_jingle = "lose_jingle"
		Global.game_manager.GameoverReason.TIME:
			selected_gameover_title = gameover_title_time
			gameover_subtitle = selected_gameover_title.get_child(1)
			gameover_subtitle.text = "Your cleaning time has expired."
			name_input_label.text = "But still ... "
			selected_gameover_jingle = "lose_jingle"
	
	# potem glede na igro	
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		match current_gameover_reason:
			Global.game_manager.GameoverReason.CLEANED: 
				Global.data_manager.write_solved_status_to_file(Global.game_manager.game_data) # uganka je bila rešena
			Global.game_manager.GameoverReason.TIME:
				gameover_subtitle.text = "Your momentum is completely gone."
	elif Global.game_manager.game_data["game"] == Profiles.Games.DEFENDER:
		match current_gameover_reason:
			Global.game_manager.GameoverReason.LIFE:
				gameover_subtitle.text = "You are forever colorless!"
			Global.game_manager.GameoverReason.TIME:
				selected_gameover_title = gameover_title_time
				gameover_subtitle.text = "You are surrounded by colors."
		
	# obarvam, če rezultat na lestvici		
	if score_is_ranking:
		selected_gameover_title.modulate = Global.color_green
		
		
func set_duel_gameover_title():
	
	selected_gameover_title = $GameoverTitle/Duel
	selected_gameover_jingle = "win_jingle"

	var winner_label: Label = selected_gameover_title.get_node("Win/PlayerLabel")
	var winning_reason_label: Label = selected_gameover_title.get_node("Win/ReasonLabel")
	var loser_name: String
	var draw_label: Label = selected_gameover_title.get_node("Draw/DrawLabel")
	
	# če je kdo brez lajfa, zmaga preživeli
	if p1_final_stats["player_life"] == 0 and p2_final_stats["player_life"] > 0: # P1 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 1"
		loser_name = "Player 2"
		winning_reason_label.text = "Player 1 cleaned Player 2."
		return
	elif p2_final_stats["player_life"] == 0 and p1_final_stats["player_life"] > 0: # P2 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 2"
		loser_name = "Player 1"
		winning_reason_label.text = "Player 2 cleaned Player 1."
		return
	 
	# če sta oba preživela ali oba umrla
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	if points_difference == 0: # draw
		selected_gameover_title.get_node("Draw").visible = true
		draw_label.text = "You both collected the same amount of points."
	else: # win
		selected_gameover_title.get_node("Win").visible = true
		if points_difference > 0: # P1 zmaga
			winner_label.text = "Player 1"
			loser_name = "Player 2"
		elif points_difference < 0: # P2 zmaga
			winner_label.text = "Player 2"
			loser_name = "Player 1"
		if abs(points_difference) == 1:
			winning_reason_label.text = winner_label.text + " was better by only one point."
		else: 
			winning_reason_label.text =  winner_label.text + " was " + str(abs(points_difference)) + " points better than " + loser_name + "."
			
			
func show_gameover_title():

	visible = true
	selected_gameover_title.visible = true
	gameover_title_holder.modulate.a = 0
	
	var background_fadein_alpha: float = 0.80 # 204A
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title_holder, "show")
	fade_in.tween_property(gameover_title_holder, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property(background, "color:a", background_fadein_alpha, 1.5).set_delay(0.5) # a = cca 140
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		fade_in.parallel().tween_callback(self, "show_menu")
		yield(fade_in, "finished")
		get_tree().set_pause(true) # setano čez celotno GO proceduro
	else:
		yield(fade_in, "finished")
		get_tree().set_pause(true) # setano čez celotno GO proceduro
		set_game_summary()
		if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
			show_game_summary()
		else:
			var current_player_rank: int
			if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
				open_name_input()
				yield(Global.data_manager, "highscores_updated")
				get_viewport().set_disable_input(false) # anti dablklik
				current_player_rank = Global.data_manager.current_player_rank

			highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_rank)
			show_game_summary() # meni pokažem v tej funkciji	


func set_game_summary():

	# main title obarvam glede na GO razlog ali ranking
	var main_title: Label = $GameSummary/Title
	if current_gameover_reason == Global.game_manager.GameoverReason.CLEANED or score_is_ranking:
		main_title.modulate = Global.color_green
	else:
		main_title.modulate = Global.color_red
	
	# title stats tabele
	gameover_stats_title.text = "Your stats" # + str(Global.game_manager.game_data["game_name"]) + " stats"
	
	# game stats name
	gameover_stat_game.text = "Game: " + str(Global.game_manager.game_data["game_name"])
	gameover_stat_time.text = "Time used: " + Global.get_clock_time(Global.hud.game_timer.absolute_game_time)
	if not Global.game_manager.game_data.has("level"):
		gameover_stat_level.hide()
	else:
		gameover_stat_level.text = "Level: " + str(Global.game_manager.game_data["level"])

	# player stats
	if not Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		gameover_stat_points.text = "Score total: " + str(p1_final_stats["player_points"])
		gameover_stat_cells_traveled.text = "Cells traveled: " + str(p1_final_stats["cells_traveled"])
		gameover_stat_burst_count.text = "Burst count: " + str(p1_final_stats["burst_count"])
		gameover_stat_skills_used.text = "Skills used: " + str(p1_final_stats["skill_count"])
		gameover_stat_pixels_off.text = "Colors collected: " + str(p1_final_stats["colors_collected"])
		gameover_stat_astray_pixels.text = "Pixels left astray: " + str(Global.game_manager.strays_in_game_count)


func show_game_summary():
	
	# hide title and name_popup > show game summary
	game_summary.modulate.a = 0	
	game_summary.visible = true	
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "color:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "hide")
	cross_fade.parallel().tween_callback(gameover_title_holder, "hide")
	cross_fade.parallel().tween_property(game_summary, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.parallel().tween_callback(self, "show_menu")


func show_menu():
	
	# vidnost gumbov v meniju glede na igro
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		if current_gameover_reason == Global.game_manager.GameoverReason.CLEANED:
			gameover_menu.get_node("RestartBtn").text = "SWEEP AGAIN"
		else:
			gameover_menu.get_node("RestartBtn").text = "TRY AGAIN"
		if Global.game_manager.game_data["level"] < Profiles.sweeper_level_settings.size():
#		if Global.game_manager.game_data["level"] < Profiles.sweeper_level_tilemap_paths.size():
			gameover_menu.get_node("NextLevelBtn").show()
	elif Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		gameover_menu.get_node("RestartBtn").text = "REMATCH"
	
	var focus_btn: Button = gameover_menu.get_node("RestartBtn")
	gameover_menu.modulate.a = 0
	gameover_menu.visible = true
		
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(gameover_menu, "show")
	fade_in.tween_property(gameover_menu, "modulate:a", 1, 0.5).from(0.0)
	fade_in.parallel().tween_callback(Global, "grab_focus_no_sfx", [focus_btn])		

	
func get_current_score():
	
	# ranking preverim že tukaj, da lahko obarvam title
	var current_score: float
	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_POINTS:
		current_score = p1_final_stats["player_points"]
	elif Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_COLORS:
		current_score = p1_final_stats["colors_collected"]
	else: # time low and high
		current_score = Global.hud.game_timer.absolute_game_time
	return current_score
	

# NAME INPUT --------------------------------------------------------------------	


func open_name_input():
	#Global.sound_manager.play_gui_sfx("screen_slide")
	
	# generiram random ime s 5 črkami in ga dam za placeholder text
	randomize()
	var ascii_letters_and_digits: String = "abcdefghijklmnopqrstuvwxyz"
	var random_generated_name: String = ""
	for i in 5:
		var random_letter: String = ascii_letters_and_digits[randi() % ascii_letters_and_digits.length()]
		random_generated_name += random_letter
	random_generated_name = random_generated_name.capitalize()
	name_input.placeholder_text = random_generated_name
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	
	Global.grab_focus_no_sfx(name_input)
	name_input.select_all()
	
	
func confirm_name_input():
	
	# pogrebam string in zapišem ime v končno statistiko igralca
	p1_final_stats["player_name"] = input_string
	close_name_input()

	
func close_name_input ():
	
	name_input.editable = false
	emit_signal("name_input_finished") # sporočim DM, da sem končal (ime povleče iz GO stats) ... on kliče "highscores_updated"
	

func _on_NameEdit_text_changed(new_text: String) -> void:
	# signal, ki redno beleži vnešeni string
	
	input_string = new_text
	Global.sound_manager.play_gui_sfx("typing")

	
func _on_PopupNameEdit_text_entered(new_text: String) -> void: # ko stisneš return
	
	_on_ConfirmBtn_pressed()

	
func _on_ConfirmBtn_pressed() -> void:

	Global.grab_focus_no_sfx($NameInputPopup/HBoxContainer/ConfirmBtn)
	get_viewport().set_disable_input(true) # anti dablklik
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	if input_string.empty():
		input_string = name_input.placeholder_text
		confirm_name_input()
	else:
		confirm_name_input()
		
		
func _on_CancelBtn_pressed() -> void:
	
	Global.grab_focus_no_sfx($NameInputPopup/HBoxContainer/CancelBtn)
	get_viewport().set_disable_input(true) # anti dablklik
	close_name_input()


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:

	Global.main_node.reload_game()
	
	
func _on_QuitBtn_pressed() -> void:

	Global.main_node.game_out(Global.game_manager.game_data["game"])


func _on_ExitGameBtn_pressed() -> void:
	get_tree().quit()


func _on_NextLevelBtn_pressed() -> void:

	var next_level_number: int = Global.game_manager.game_data["level"] + 1
	Profiles.game_data_sweeper["level"] = next_level_number
	Global.main_node.reload_game()


func _on_RematchBtn_pressed() -> void:
	
	Global.main_node.reload_game()
