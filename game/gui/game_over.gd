extends Control


signal name_input_finished

var menu_btn_clicked: bool = false # za disejblanje gumbov
var focus_btn: Button
onready var background: ColorRect = $Background

# players
var players_in_game: Array
var p1_final_stats: Dictionary
var p2_final_stats: Dictionary

# gameover title
var selected_gameover_title: Control
var selected_gameover_menu: Control
var selected_gameover_jingle: String
onready var gameover_title_holder: Control = $GameoverTitle
onready var gameover_title_cleaned: Control = $GameoverTitle/ReasonCleaned
onready var gameover_title_time: Control = $GameoverTitle/ReasonTime
onready var gameover_title_life: Control = $GameoverTitle/ReasonLife
onready var gameover_title_level: Control = $GameoverTitle/Level
onready var gameover_title_duel: Control = $GameoverTitle/Duel
onready var gameover_title_tutorial: Control = $GameoverTitle/Tutorial

# game summary
var selected_game_summary: Control
onready var game_summary_holder: Control = $GameSummary
onready var game_summary_no_hs: Control = $GameSummary/NoHS
onready var game_summary_with_hs: Control = $GameSummary/WithHS
onready var highscore_table: VBoxContainer = $GameSummary/WithHS/HighscoreTable

# name input
var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem, da zaznava vsako črko in jo lahko potrdiš na gumbu
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var name_input_label: Label = $NameInputPopup/Label


func _input(event: InputEvent) -> void:

	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if (selected_gameover_menu != null and selected_gameover_menu.modulate.a == 1) or (selected_game_summary != null and selected_game_summary.visible and selected_game_summary.modulate.a == 1):
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	gameover_title_holder.visible = false
	game_summary_holder.visible = false
	name_input_popup.visible = false
	
	
func open_gameover(gameover_reason):
	
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	
	p1_final_stats = players_in_game[0].player_stats
	
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.animation_player.play("tutorial_end")
		set_tutorial_gameover_title()
	elif players_in_game.size() == 2:
		p2_final_stats = players_in_game[1].player_stats
		set_duel_gameover_title()
	else:
		set_game_gameover_title(gameover_reason)
		
	Global.hud.slide_out()
	yield(Global.player1_camera, "zoomed_out")
	show_gameover_title()	


func show_gameover_title():

	get_tree().call_group(Global.group_players, "set_physics_process", false)
#	get_tree().call_group(Global.group_players, "set_process", false)
	
	visible = true
	selected_gameover_title.visible = true
	gameover_title_holder.modulate.a = 0
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title_holder, "set_visible", [true])#.set_delay(1)
	fade_in.tween_property(gameover_title_holder, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property(background, "modulate:a", 0.7, 1)#.set_delay(0.5)
	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)


func show_gameover_menu():
	
	get_tree().set_pause(true) # setano čez celotno GO proceduro
	
	if players_in_game.size() == 2 or Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		selected_gameover_menu.visible = false
		selected_gameover_menu.modulate.a = 0
		var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		fade_in.tween_callback(selected_gameover_menu, "set_visible", [true])#.set_delay(1)
		fade_in.tween_property(selected_gameover_menu, "modulate:a", 1, 1)
		fade_in.parallel().tween_callback(focus_btn, "grab_focus")		
	else:	
		if Global.game_manager.game_settings["manage_highscores"]:
			var score_is_ranking = Global.data_manager.manage_gameover_highscores(p1_final_stats["player_points"], Global.game_manager.game_data["game"]) # yield čaka na konec preverke
			if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
				open_name_input()
				yield(Global.data_manager, "highscores_updated")
			highscore_table.get_highscore_table(Global.game_manager.game_data["game"], Global.data_manager.current_player_ranking)
			selected_game_summary = game_summary_with_hs
			show_game_summary()
		else:
			selected_game_summary = game_summary_no_hs
			yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
			show_game_summary()


func show_game_summary():
	
	focus_btn = selected_game_summary.get_node("Menu/RestartBtn")

	# get stats
	selected_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
	selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.game_data["level"])
	selected_game_summary.get_node("DataContainer/Points").text %= str(p1_final_stats["player_points"])
	selected_game_summary.get_node("DataContainer/Time").text %= str(Global.hud.game_timer.time_since_start)
	selected_game_summary.get_node("DataContainer/CellsTraveled").text %= str(p1_final_stats["cells_traveled"])
	selected_game_summary.get_node("DataContainer/BurstCount").text %= str(p1_final_stats["burst_count"])
	selected_game_summary.get_node("DataContainer/SkillsUsed").text %= str(p1_final_stats["skill_count"])
	selected_game_summary.get_node("DataContainer/PixelsOff").text %= str(p1_final_stats["colors_collected"])
#	selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game.size())
	selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
	
	selected_game_summary.visible = true	
	game_summary_holder.visible = true	
	game_summary_holder.modulate.a = 0	

	# hide title and name_popup > show game summary
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "modulate:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "set_visible", [false])
	cross_fade.parallel().tween_callback(gameover_title_holder, "set_visible", [false])
	cross_fade.parallel().tween_property(game_summary_holder, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.tween_callback(focus_btn, "grab_focus")


# TITLES --------------------------------------------------------------	

	
func set_tutorial_gameover_title():
	
	selected_gameover_title = gameover_title_tutorial
	selected_gameover_menu = selected_gameover_title.get_node("Menu")
	focus_btn = selected_gameover_menu.get_node("QuitBtn")
	
	if Global.tutorial_gui.current_tutorial_stage == Global.tutorial_gui.TutorialStage.WINLOSE:
		selected_gameover_title.get_node("Finished").visible = true
		selected_gameover_jingle = "win_jingle"	
	else:
		selected_gameover_title.get_node("NotFinished").visible = true
		selected_gameover_jingle = "lose_jingle"	
		
		
func set_duel_gameover_title():
	
	selected_gameover_title = gameover_title_duel
	selected_gameover_menu = selected_gameover_title.get_node("Menu")
	focus_btn = selected_gameover_menu.get_node("RestartBtn")
	selected_gameover_jingle = "win_jingle"
	
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	
	if points_difference == 0: # draw
#		winner_label.text = "You both collected the same amount of points."	
		selected_gameover_title.get_node("Draw").visible = true
	else: # win
		var winner_label: Label = selected_gameover_title.get_node("Win/PlayerLabel")
		var points_difference_label: Label = selected_gameover_title.get_node("Win/DifferenceLabel")
		var loser_name: String
		selected_gameover_title.get_node("Win").visible = true
		if points_difference > 0: # P1 zmaga
			winner_label.text = "Player 1"
			loser_name = "Player 2"
		elif points_difference < 0: # P2 zmaga
			winner_label.text = "Player 2"
			loser_name = "Player 1"
		if abs(points_difference) == 1:
			points_difference_label.text = "Winner was better for only one point."
		else:
			points_difference_label.text =  winner_label.text + " was " + str(abs(points_difference)) + " points better than " + loser_name + "."# + " points."
		
			
func set_game_gameover_title(gameover_reason):
	
	match gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_gameover_title = gameover_title_cleaned
			selected_gameover_jingle = "win_jingle"
			name_input_label.text = "Great work!"
		Global.game_manager.GameoverReason.LIFE:
			selected_gameover_title = gameover_title_life
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
		Global.game_manager.GameoverReason.TIME:
			selected_gameover_title = gameover_title_time
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
	
	
# NAME INPUT --------------------------------------------------------------------	


func open_name_input():
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	
	# setam input label
	name_input.text = input_invite_text
	
	name_input.grab_focus()
	name_input.select_all()
	
	
func confirm_name_input():
	
	# pogrebam string in zapišem ime v končno statistiko igralca
	p1_final_stats["player_name"] = input_string
	close_name_input()

	
func close_name_input ():
	
	name_input.editable = false
	emit_signal("name_input_finished") # sporočim data managerju, da sem končal (ime povleče iz GO stats)
	

func _on_NameEdit_text_changed(new_text: String) -> void:
	
	# signal, ki redno beleži vnešeni string
	input_string = new_text
	Global.sound_manager.play_gui_sfx("typing")

	
func _on_PopupNameEdit_text_entered(new_text: String) -> void: # ko stisneš return
	_on_ConfirmBtn_pressed()

	
func _on_ConfirmBtn_pressed() -> void:

	if name_input.editable == false:
		return
			
	$NameInputPopup/HBoxContainer/ConfirmBtn.grab_focus() # da se obarva ko stisnem RETURN
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	if input_string == input_invite_text or input_string.empty():
		input_string = p1_final_stats["player_name"]
		confirm_name_input()
	else:
		confirm_name_input()
		

func _on_CancelBtn_pressed() -> void:

	if name_input.editable == false:
		return
			
	$NameInputPopup/HBoxContainer/CancelBtn.grab_focus() # da se obarva ko stisnem ESC
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	close_name_input()


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:

	if menu_btn_clicked:
		return
	menu_btn_clicked = true

	Global.sound_manager.play_gui_sfx("btn_confirm")
#	get_tree().paused = false
	Global.main_node.reload_game()
	
	
func _on_QuitBtn_pressed() -> void:

	if menu_btn_clicked:
		return
	menu_btn_clicked = true
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
#	get_tree().paused = false
	Global.main_node.game_out()
