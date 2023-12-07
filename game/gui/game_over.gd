extends Control


signal name_input_finished

var menu_btn_clicked: bool = false # za disejblanje gumbov

var selected_title: Control
var selected_summary: Control
var selected_menu: Control
var selected_jingle: String

var focus_btn: Button

# players
var players_in_game: Array
var p1_final_stats: Dictionary
var p2_final_stats: Dictionary
	
# name input
var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem, da zaznava vsako črko in jo lahko potrdiš na gumbu
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var name_input_label: Label = $NameInputPopup/Label

onready var background: ColorRect = $Background
onready var highscore_table: VBoxContainer = $GameSummary/HighscoreTable
onready var gameover_title: Control = $FinalTitle
onready var game_summary: Control = $GameSummary
onready var game_summary_hs: Control = $GameSummaryHS


func _input(event: InputEvent) -> void:

	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if (selected_menu != null and selected_menu.modulate.a == 1) or (game_summary.visible and game_summary.modulate.a == 1):
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	gameover_title.visible = false
	game_summary.visible = false
	name_input_popup.visible = false
	
	
func show_gameover(gameover_reason):
	
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	p1_final_stats = players_in_game[0].player_stats
	
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		set_tutorial_title()
		yield(get_tree().create_timer(2), "timeout") # showoff time
		Global.tutorial_gui.animation_player.play("tutorial_end")
		Global.hud.slide_out()
		show_gameover_title()
		
	if players_in_game.size() == 2:
		p2_final_stats = players_in_game[1].player_stats
		set_duel_title()
		show_gameover_title()
		yield(get_tree().create_timer(3), "timeout") # showoff time
		Global.hud.slide_out()
	
	else: # katerakoli igra
		set_game_title(gameover_reason)
		yield(get_tree().create_timer(3), "timeout") # showoff time
		Global.hud.slide_out()
		show_gameover_title()
	

func show_gameover_title():

	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	visible = true
	selected_title.visible = true
	gameover_title.modulate.a = 0
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title, "set_visible", [true])#.set_delay(1)
	fade_in.tween_property(gameover_title, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "play_sfx", [selected_jingle])
	fade_in.parallel().tween_property(background, "modulate:a", 0.7, 1).set_delay(0.5)
	fade_in.tween_callback(self, "show_menu").set_delay(2)


func show_menu():
	
	if players_in_game.size() == 2 or Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		selected_menu.visible = false
		selected_menu.modulate.a = 0
		var fade_in = get_tree().create_tween()
		fade_in.tween_callback(selected_menu, "set_visible", [true])#.set_delay(1)
		fade_in.tween_property(selected_menu, "modulate:a", 1, 1)
		fade_in.parallel().tween_callback(focus_btn, "grab_focus")		
	else:	
		print("sumari")
		if Global.game_manager.game_settings["manage_highscores"]:
			var score_is_ranking = Global.data_manager.manage_gameover_highscores(p1_final_stats["player_points"], Global.game_manager.game_data["game"]) # yield čaka na konec preverke
			if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
				open_name_input()
				yield(Global.data_manager, "highscores_updated")
			highscore_table.get_highscore_table(Global.game_manager.game_data["game"], Global.data_manager.current_player_ranking)
		yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
		show_game_summary()
	
	
func show_game_summary():

	# write stats
	$GameSummary/DataContainer/Game.text %= Global.game_manager.game_data["game_name"]
	$GameSummary/DataContainer/Level.text %= Global.game_manager.game_data["level"]
	$GameSummary/DataContainer/Points.text %= str(p1_final_stats["player_points"])
	$GameSummary/DataContainer/Time.text %= str(Global.hud.game_timer.time_since_start)
	$GameSummary/DataContainer/CellsTraveled.text %= str(p1_final_stats["cells_traveled"])
	$GameSummary/DataContainer/BurstCount.text %= str(p1_final_stats["burst_count"])
	$GameSummary/DataContainer/SkillsUsed.text %= str(p1_final_stats["skill_count"])
	$GameSummary/DataContainer/PixelsOff.text %= str(p1_final_stats["colors_collected"])
	$GameSummary/DataContainer/AstrayPixels.text %= str(Global.game_manager.strays_in_game.size())
	
	game_summary.visible = true	
	game_summary.modulate.a = 0	

	# show game summary (hide title, name_popup)
	var fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade.parallel().tween_property(gameover_title, "modulate:a", 0, 1)
	fade.tween_callback(name_input_popup, "set_visible", [false])
	fade.tween_callback(get_tree(), "set_pause", [true])
	fade.tween_callback(gameover_title, "set_visible", [false])
	fade.tween_property(game_summary, "modulate:a", 1, 1).set_delay(0.5)
	fade.parallel().tween_property(background, "modulate:a", 1, 1)
	fade.tween_callback(focus_btn, "grab_focus")


# TITLES --------------------------------------------------------------	

	
func set_duel_title():
	
	var player_label: Label = $FinalTitle/Duel/Win/PlayerLabel
	var points_difference_label: Label = $FinalTitle/Duel/Win/ColorsLabel
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	
	if points_difference > 0: # P1 zmaga
		player_label.text = "Player 1"
		if points_difference == 1:
			points_difference_label.text %= "only one point."
		else:
			points_difference_label.text %= str(points_difference) + " point."
		$FinalTitle/Duel/Win.visible = true
	elif points_difference < 0: # P2 zmaga
		player_label.text = "Player 2"
		if abs(points_difference) == 1:
			points_difference_label.text %= "only one point."
		else:
			points_difference_label.text %= str(abs(points_difference)) + " point."
		$FinalTitle/Duel/Win.visible = true
	else: # draw
		player_label.text = "You both collected same amount of points."	
		$FinalTitle/Duel/Draw.visible = true
	
	selected_title = $FinalTitle/Duel
	selected_menu = $FinalTitle/Duel/Menu
	focus_btn = $FinalTitle/Duel/Menu/RestartBtn
	selected_jingle = "win_jingle"

	
func set_tutorial_title():
	selected_title = $FinalTitle/Tutorial
	selected_menu = $FinalTitle/Tutorial/Menu
	focus_btn = $FinalTitle/Tutorial/Menu/QuitBtn
	selected_jingle = "win_jingle"	
	
	
func set_game_title(gameover_reason):
	print("reason", gameover_reason)
	match gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_title = $FinalTitle/GameCleaned
			selected_jingle = "win_jingle"
#			name_input_label.text %= "Great work!"
		Global.game_manager.GameoverReason.LIFE:
			selected_title = $FinalTitle/GameLife
			selected_jingle = "lose_jingle"
			name_input_label.text %= "But still ... "
		Global.game_manager.GameoverReason.TIME:
			selected_title = $FinalTitle/GameTime
			selected_jingle = "lose_jingle"
			name_input_label.text %= "But still ... "
	
	focus_btn = $GameSummary/Menu/RestartBtn		
	
	
# NAME INPUT --------------------------------------------------------------------	


func open_name_input():
	
#	name_input_label.text %= "But still ..." 
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in_tween = get_tree().create_tween()
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
	get_tree().paused = false
	set_process_input(true)
	Global.main_node.reload_game()
	
	
func _on_QuitBtn_pressed() -> void:

	if menu_btn_clicked:
		return
	menu_btn_clicked = true
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	get_tree().paused = false
	set_process_input(true)
	Global.main_node.game_out()
