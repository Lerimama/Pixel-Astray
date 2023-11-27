extends Control


signal name_input_finished

var selected_title: Control
var selected_summary: Control
var selected_menu: Control
var selected_jingle: String
var focus_btn: Button

var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

onready var background: ColorRect = $Background
onready var highscore_table: VBoxContainer = $GameSummary/HighscoreTable
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var gameover_title: Control = $FinalTitle
onready var game_summary: Control = $GameSummary


func _input(event: InputEvent) -> void:
	
	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if (selected_menu != null and selected_menu.modulate.a == 1) or (game_summary.visible and game_summary.modulate.a == 1):
#	if selected_summary != null and selected_summary.modulate.a == 1:
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

	if Global.game_manager.game_settings["start_players_count"] == 2:
		set_duel_title()
		show_gameover_title()
		Global.sound_manager.stop_music("game_on_game-over")
		yield(get_tree().create_timer(3), "timeout") # showoff time
		Global.hud.fade_out()
		
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		set_tutorial_title()
		yield(get_tree().create_timer(2), "timeout") # showoff time
		Global.tutorial_gui.animation_player.play("tutorial_end")
		Global.hud.fade_out()
		Global.sound_manager.stop_music("game_on_game-over")
		show_gameover_title()
		
	else: # katerakoli igra
		set_game_title(gameover_reason)
		yield(get_tree().create_timer(3), "timeout") # showoff time
		Global.hud.fade_out()
		Global.sound_manager.stop_music("game_on_game-over")
		show_gameover_title()
	

func show_gameover_title():
	
	visible = true
	selected_title.visible = true
	gameover_title.modulate.a = 0
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title, "set_visible", [true])#.set_delay(1)
	fade_in.tween_property(gameover_title, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "play_sfx", [selected_jingle])
	fade_in.parallel().tween_property(background, "modulate:a", 0.6, 1).set_delay(0.5)
	fade_in.tween_callback(self, "show_menu").set_delay(2)


func show_menu():
	
	if Global.game_manager.game_settings["start_players_count"] == 2 or Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		selected_menu.visible = false
		selected_menu.modulate.a = 0
		var fade_in = get_tree().create_tween()
		fade_in.tween_callback(selected_menu, "set_visible", [true])#.set_delay(1)
		fade_in.tween_property(selected_menu, "modulate:a", 1, 1)
		fade_in.parallel().tween_callback(focus_btn, "grab_focus")		
	else:	
		if Global.game_manager.game_settings["manage_highscores"]:
			var score_is_ranking = Global.data_manager.manage_gameover_highscores(Global.game_manager.p1_stats["player_points"], Global.game_manager.game_data["game"]) # yield čaka na konec preverke
			if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
				open_name_input()
				yield(Global.data_manager, "highscores_updated")
			highscore_table.get_highscore_table(Global.game_manager.game_data["game"], Global.data_manager.current_player_ranking)
		yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
		show_game_summary()

	
func show_game_summary():

	write_gameover_data()
	
	game_summary.visible = true	
	game_summary.modulate.a = 0	

	# hide title, name_popup > show game summary
	var fade = get_tree().create_tween()
	fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade.parallel().tween_property(gameover_title, "modulate:a", 0, 1)
	fade.tween_callback(name_input_popup, "set_visible", [false])
	fade.parallel().tween_callback(gameover_title, "set_visible", [false])
	fade.tween_property(game_summary, "modulate:a", 1, 1).set_delay(0.5)
	fade.parallel().tween_property(background, "modulate:a", 1, 1)
	fade.tween_callback(self, "pause_tree") # šele tukaj, da se tween sploh zgodi
	fade.tween_callback(focus_btn, "grab_focus") # šele tukaj, da se tween sploh zgodi,če 

			
func write_gameover_data():
	
	$GameSummary/DataContainer/Game.text %= Global.game_manager.game_data["game_name"]
	$GameSummary/DataContainer/Level.text %= Global.game_manager.game_data["level"]
	$GameSummary/DataContainer/Points.text %= str(Global.game_manager.p1_stats["player_points"])
	$GameSummary/DataContainer/Time.text %= str(Global.hud.game_timer.time_since_start)
	$GameSummary/DataContainer/CellsTraveled.text %= str(Global.game_manager.p1_stats["cells_traveled"])
	$GameSummary/DataContainer/BurstCount.text %= str(Global.game_manager.p1_stats["burst_count"])
	$GameSummary/DataContainer/SkillsUsed.text %= str(Global.game_manager.p1_stats["skill_count"])
	$GameSummary/DataContainer/PixelsOff.text %= str(Global.game_manager.p1_stats["colors_collected"])
	$GameSummary/DataContainer/AstrayPixels.text %= str(Global.game_manager.strays_in_game_count)


# TITLES --------------------------------------------------------------	

	
func set_duel_title():
	
	var player_label: Label = $FinalTitle/Duel/Win/PlayerLabel
	var difference_label: Label = $FinalTitle/Duel/Win/ColorsLabel
	var difference: int = abs(Global.game_manager.p1_stats["colors_collected"] - Global.game_manager.p2_stats["colors_collected"])
	
	if Global.game_manager.p1_stats["colors_collected"] > Global.game_manager.p2_stats["colors_collected"]:
		player_label.text = "Player 1"
		if difference == 1:
			difference_label.text %= "only one color."
		else:
			difference_label.text %= str(difference) + " colors."
		$FinalTitle/Duel/Win.visible = true
	elif Global.game_manager.p1_stats["colors_collected"] < Global.game_manager.p2_stats["colors_collected"]:
		player_label.text = "Player 2"
		if difference == 1:
			difference_label.text %= "only one color."
		else:
			difference_label.text %= str(difference) + " colors."
		$FinalTitle/Duel/Win.visible = true
	else: # tie
		player_label.text = "You both collected same amount of colors."	
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
	
	match gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_title = $FinalTitle/GameCleaned
			selected_jingle = "win_jingle"
		Global.game_manager.GameoverReason.LIFE:
			selected_title = $FinalTitle/GameLife
			selected_jingle = "lose_jingle"
		Global.game_manager.GameoverReason.TIME:
			selected_title = $FinalTitle/GameTime
			selected_jingle = "lose_jingle"
	
	focus_btn = $GameSummary/Menu/RestartBtn		
	
			
# PAVZIRANJE DREVESA --------------------------------------------------------------	


func pause_tree():
	get_tree().paused = true


func unpause_tree():
	
	get_tree().paused = false
	set_process_input(true) # zato da se lahko animacija izvede
	
	
# NAME INPUT --------------------------------------------------------------------	

func open_name_input():
	
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
	Global.game_manager.p1_stats["player_name"] = input_string
	close_name_input()

	
func close_name_input (): 

	name_input.editable = false
	emit_signal("name_input_finished") # sporočim data managerju, da sem končal
	
	# disable btnz in input
	yield(get_tree().create_timer(0.2), "timeout")
	$NameInputPopup/HBoxContainer/ConfirmBtn.disabled = true
	$NameInputPopup/HBoxContainer/CancelBtn.disabled = true
		

func _on_NameEdit_text_changed(new_text: String) -> void:
	
	# signal, ki redno beleži vnešeni string
	input_string = new_text
	Global.sound_manager.play_gui_sfx("typing")

	
func _on_PopupNameEdit_text_entered(new_text: String) -> void: # ko stisneš return
	_on_ConfirmBtn_pressed()

	
func _on_ConfirmBtn_pressed() -> void:
	
	$NameInputPopup/HBoxContainer/ConfirmBtn.grab_focus() # da se obarva ko stisnem RETURN
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	if input_string == input_invite_text or input_string.empty():
		input_string = Global.game_manager.p1_stats["player_name"]
		confirm_name_input()
	else:
		confirm_name_input()
		

func _on_CancelBtn_pressed() -> void:
	
	$NameInputPopup/HBoxContainer/CancelBtn.grab_focus() # da se obarva ko stisnem ESC
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	close_name_input()


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.sound_manager.play_gui_sfx("btn_confirm")
	Global.main_node.reload_game()
	
	# disable btn, da ni multiklik
	if Global.game_manager.game_settings["start_players_count"] == 2:
		$FinalTitle/Duel/Menu/RestartBtn.disabled = true
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		$FinalTitle/Tutorial/Menu/RestartBtn.disabled = true
	else:
		$GameSummary/Menu/RestartBtn.disabled = true
	
	
func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.main_node.game_out()
	
	# disable btn, da ni multiklik
	if Global.game_manager.game_settings["start_players_count"] == 2:
		$FinalTitle/Duel/Menu/QuitBtn.disabled = true
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		$FinalTitle/Tutorial/Menu/QuitBtn.disabled = true
	else:
		$GameSummary/Menu/QuitBtn.disabled = true 
	
