extends Control


signal name_input_finished

var selected_title: Control
var selected_summary: Control
var selected_jingle: String
var focus_btn: Button

var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

onready var background: ColorRect = $Background
onready var highscore_table: VBoxContainer = $GameSummary/Game/HighscoreTable
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var final_title: Control = $FinalTitle
onready var game_summary: Control = $GameSummary


func _input(event: InputEvent) -> void:
	
	if name_input_popup.visible == true:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if selected_summary != null and selected_summary.modulate.a == 1:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	final_title.visible = false
	game_summary.visible = false
	name_input_popup.visible = false
	

func show_final_title(gameover_reason):

	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		
		var player_label: Label = $FinalTitle/Duel/Win/PlayerLabel
		var difference_label: Label = $FinalTitle/Duel/Win/ColorsLabel
		var difference: int = abs(Global.game_manager.p1_stats["colors_collected"] - Global.game_manager.p2_stats["colors_collected"])
		
		if Global.game_manager.p1_stats["colors_collected"] > Global.game_manager.p2_stats["colors_collected"]:
			player_label.text = "Player 1"
			if difference == 1:
				difference_label.text %= str(difference) + " color."
			else:
				difference_label.text %= str(difference) + " colors."
			$FinalTitle/Duel/Win.visible = true
		elif Global.game_manager.p1_stats["colors_collected"] < Global.game_manager.p2_stats["colors_collected"]:
			player_label.text = "Player 2"
			if difference == 1:
				difference_label.text %= str(difference) + " color."
			else:
				difference_label.text %= str(difference) + " colors."
			$FinalTitle/Duel/Win.visible = true
		else: # tie
			player_label.text = "You both collected same amount of colors."	
			$FinalTitle/Duel/Draw.visible = true
		selected_title = $FinalTitle/Duel
		selected_summary = $GameSummary/Duel
		focus_btn = $GameSummary/Duel/Menu/RestartBtn
		selected_jingle = "win_jingle"
		
		
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		selected_title = $FinalTitle/Tutorial
		selected_summary = $GameSummary/Tutorial
		focus_btn = $GameSummary/Tutorial/Menu/QuitBtn
	
	else:
		set_gameover_title(gameover_reason)
		selected_summary = $GameSummary/Game
		focus_btn = $GameSummary/Game/Menu/RestartBtn
	
	visible = true
	selected_title.visible = true	
	final_title.modulate.a = 0		
	
	# title in 
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(final_title, "set_visible", [true]).set_delay(1)
	fade_in.tween_property(final_title, "modulate:a", 1, 1)
	fade_in.parallel().tween_property(background, "modulate:a", 0.6, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "play_sfx", [selected_jingle])
	fade_in.tween_callback(self, "check_if_ranking").set_delay(2)


func check_if_ranking():
	
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL or Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		show_game_summary()
	else:
		var score_is_ranking = Global.data_manager.manage_gameover_highscores(Global.game_manager.p1_stats["player_points"], Global.game_manager.game_data["game"]) # yield čaka na konec preverke
		if not score_is_ranking: # če ni rankinga = false
			yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
			highscore_table.get_highscore_table(Global.game_manager.game_data["game"], Global.data_manager.current_player_ranking)
			show_game_summary()
		else: # če je ranking, manage_gameover_highscores počaka na signal iz name_input
			open_name_input()
			yield(Global.data_manager, "highscores_updated")
			highscore_table.get_highscore_table(Global.game_manager.game_data["game"], Global.data_manager.current_player_ranking)
			show_game_summary()
	

func show_game_summary():

	selected_summary.visible = true	
	game_summary.modulate.a = 0	
	
	write_gameover_data()

	# hide title, name_popup > show game summary
	var fade = get_tree().create_tween()
	fade.tween_property(name_input_popup, "modulate:a", 0, 1)
	fade.parallel().tween_property(final_title, "modulate:a", 0, 1)
	fade.tween_callback(name_input_popup, "set_visible", [false])
	fade.parallel().tween_callback(final_title, "set_visible", [false])
	fade.tween_callback(game_summary, "set_visible", [true])
	fade.tween_property(game_summary, "modulate:a", 1, 1).set_delay(0.5)
	fade.parallel().tween_property(background, "modulate:a", 1, 1)
	fade.tween_callback(self, "pause_tree") # šele tukaj, da se tween sploh zgodi
	fade.tween_callback(focus_btn, "grab_focus") # šele tukaj, da se tween sploh zgodi,če 


func set_gameover_title(gameover_reason):
	
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
			
			
func write_gameover_data():
	
	var game_name: String = Global.game_manager.game_data["game_name"]
	var level_reached: String = Global.game_manager.game_data["level"]
	var player_points: int = Global.game_manager.p1_stats["player_points"]
	var time_used: int = Global.hud.game_timer.time_since_start
	var cells_traveled: int = Global.game_manager.p1_stats["cells_traveled"]
	var burst_count: int = Global.game_manager.p1_stats["burst_count"]
	var skills_count: int = Global.game_manager.p1_stats["skill_count"]
	var colors_collected: int = Global.game_manager.p1_stats["colors_collected"]
	var astray_pixels: int = Global.game_manager.strays_in_game_count
	
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		$GameSummary/Duel/DataContainerP1/Points.text %= str(player_points)
		$GameSummary/Duel/DataContainerP1/CellsTraveled.text %= str(cells_traveled)
		$GameSummary/Duel/DataContainerP1/BurstCount.text %= str(burst_count)
		$GameSummary/Duel/DataContainerP1/SkillsUsed.text %= str(skills_count)
		$GameSummary/Duel/DataContainerP1/PixelsOff.text %= str(colors_collected)
		$GameSummary/Duel/DataContainerP1/AstrayPixels.text %= str(astray_pixels)
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		$GameSummary/Tutorial/DataContainer/Points.text %= str(player_points)
		$GameSummary/Tutorial/DataContainer/CellsTraveled.text %= str(cells_traveled)
		$GameSummary/Tutorial/DataContainer/BurstCount.text %= str(burst_count)
		$GameSummary/Tutorial/DataContainer/SkillsUsed.text %= str(skills_count)
		$GameSummary/Tutorial/DataContainer/PixelsOff.text %= str(colors_collected)
		$GameSummary/Tutorial/DataContainer/AstrayPixels.text %= str(astray_pixels)
	else:
		$GameSummary/Game/DataContainer/Game.text %= game_name
		$GameSummary/Game/DataContainer/Level.text %= level_reached
		$GameSummary/Game/DataContainer/Points.text %= str(player_points)
		$GameSummary/Game/DataContainer/Time.text %= str(time_used)
		$GameSummary/Game/DataContainer/CellsTraveled.text %= str(cells_traveled)
		$GameSummary/Game/DataContainer/BurstCount.text %= str(burst_count)
		$GameSummary/Game/DataContainer/SkillsUsed.text %= str(skills_count)
		$GameSummary/Game/DataContainer/PixelsOff.text %= str(colors_collected)
		$GameSummary/Game/DataContainer/AstrayPixels.text %= str(astray_pixels)

			
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

	# disable btnz in input
	$NameInputPopup/HBoxContainer/ConfirmBtn.disabled = true
	$NameInputPopup/HBoxContainer/CancelBtn.disabled = true
	name_input.editable = false
		
	# sporočim data managerju, da sem končal
	emit_signal("name_input_finished")
		

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
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		$GameSummary/Duel/Menu/RestartBtn.disabled = true
	elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		$GameSummary/Tutorial/Menu/RestartBtn.disabled = true
	else:
		$GameSummary/Game/Menu/RestartBtn.disabled = true
	
	
func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.main_node.game_out()
	
	# disable btn, da ni multiklik
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		$GameSummary/Duel/Menu/QuitBtn.disabled = true
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		$GameSummary/Tutorial/Menu/QuitBtn.disabled = true
	else:
		$GameSummary/Game/Menu/QuitBtn.disabled = true 
	
