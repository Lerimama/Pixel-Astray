extends Control


signal name_input_finished

var fade_time: float = 0.5

# popup
var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

# hs
onready var name_input_popup: Control = $NameInputPopup
onready var highscore_table: VBoxContainer = $ContentGame/HighscoreTable
onready var name_input: LineEdit = $NameInputPopup/NameInput

# animacija
onready var undi: ColorRect = $Undi
#onready var died_label: Label = $Title/DiedLabel
#onready var timeup_label: Label = $Title/TimeupLabel
#onready var cleaned_label: Label = $Title/CleanedLabel
onready var title_succes: Control = $TitleSucces
onready var title_fail_time: Control = $TitleFailTime
onready var title_fail_life: Control = $TitleFailLife
onready var content_practice: Control = $ContentPractice
onready var content_game: Control = $ContentGame

var current_title: Node # za določanje trenutnega napisa ob koncu igre

func _input(event: InputEvent) -> void:
	
	if name_input_popup.visible == true:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if content_game.modulate.a == 1:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
	elif content_practice.modulate.a == 1:
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	modulate.a = 0
	
	name_input_popup.visible = false
	content_game.modulate.a = 0
	content_game.visible = false
	content_practice.modulate.a = 0
	content_practice.visible = false


func fade_in_practice(gameover_reason):
	
	var restart_btn = $ContentPractice/Menu/RestartBtn # za focus
	
	match gameover_reason:
		"reason_cleaned":
			title_succes.visible = true
			title_fail_time.visible = false
			title_fail_life.visible = false
			
			current_title = title_succes

		"reason_time":
			title_succes.visible = false
			title_fail_time.visible = true
			title_fail_life.visible = false
			
			current_title = title_fail_time
			
		"reason_life":
			title_succes.visible = false
			title_fail_time.visible = false
			title_fail_life.visible = true
			
			current_title = title_fail_life
			
	modulate.a = 0	
	visible = true
	
	# hud + title
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_callback(Global.sound_manager, "play_sfx", ["loose_jingle"])
	
	write_gameover_data()
	yield(get_tree().create_timer(3), "timeout")

	# title out, content in
	content_practice.visible = true
	var fade = get_tree().create_tween()
	fade.tween_property(current_title, "modulate:a", 0, 1)
	fade.parallel().tween_property(undi, "modulate:a", 0.9, 1)
	fade.tween_property(content_practice, "modulate:a", 1, 1)#.set_delay(0.3)
	fade.tween_callback(self, "pause_tree") # šele tukaj, da se tween sploh zgodi
	fade.tween_callback(restart_btn, "grab_focus") # šele tukaj, da se tween sploh zgodi,če 

# brez HS
func fade_in(gameover_reason):
	
	var restart_btn = $ContentGame/Menu/RestartBtn # za focus
	
	match gameover_reason:
		"reason_cleaned":
			title_succes.visible = true
			title_fail_time.visible = false
			title_fail_life.visible = false
			
			current_title = title_succes

		"reason_time":
			title_succes.visible = false
			title_fail_time.visible = true
			title_fail_life.visible = false
			
			current_title = title_fail_time
			
		"reason_life":
			title_succes.visible = false
			title_fail_time.visible = false
			title_fail_life.visible = true
			
			current_title = title_fail_life
			
	modulate.a = 0	
	visible = true
	
	# hud + title
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_callback(Global.sound_manager, "play_sfx", ["loose_jingle"])
	
	write_gameover_data()
#	highscore_table.get_highscore_table(Global.data_manager.current_player_ranking)
	highscore_table.get_highscore_table(Global.game_manager.game_stats["level"], Global.data_manager.current_player_ranking)
	
	content_game.visible = true
	
	yield(get_tree().create_timer(3), "timeout")

	# title out, content in
	var fade = get_tree().create_tween()
	fade.tween_property(current_title, "modulate:a", 0, 1)
	fade.parallel().tween_property(undi, "modulate:a", 0.9, 1)
	fade.tween_property(content_game, "modulate:a", 1, 1)#.set_delay(0.3)
	fade.tween_callback(self, "pause_tree") # šele tukaj, da se tween sploh zgodi
	fade.tween_callback(restart_btn, "grab_focus") # šele tukaj, da se tween sploh zgodi,če 

	
# jes HS
func fade_in_empty(gameover_reason):

	var restart_btn = $ContentGame/Menu/RestartBtn # za focus
	
	match gameover_reason:
		"reason_cleaned":
			title_succes.visible = true
			title_fail_time.visible = false
			title_fail_life.visible = false
			
			current_title = title_succes

		"reason_time":
			title_succes.visible = false
			title_fail_time.visible = true
			title_fail_life.visible = false
			
			current_title = title_fail_time
			
		"reason_life":
			title_succes.visible = false
			title_fail_time.visible = false
			title_fail_life.visible = true
			
			current_title = title_fail_life
				
	modulate.a = 0	
	visible = true
	
	# hud + title + name input
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_callback(self, "open_name_input").set_delay(1)
	fade_in.parallel().tween_callback(Global.sound_manager, "play_sfx", ["win_jingle"])


func show_content():
	
	var restart_btn = $ContentGame/Menu/RestartBtn # za focus
	
	# title se odfejda v "close_name_input()"
	write_gameover_data()
	highscore_table.get_highscore_table(Global.game_manager.game_stats["level"], Global.data_manager.current_player_ranking)
	
	content_game.visible = true

	var fade_in_tween = get_tree().create_tween()		
	fade_in_tween.tween_property(content_game, "modulate:a", 1, 1)#.set_delay(0.3)
	fade_in_tween.tween_callback(self, "pause_tree")
	fade_in_tween.tween_callback(restart_btn, "grab_focus")


func write_gameover_data():
	
	var player_gameover_stats: Dictionary = Global.game_manager.player_stats
	var game_gameover_stats: Dictionary = Global.game_manager.game_stats

	var time_used: int = Global.hud.game_timer.time_since_start
	
	var current_level_key = Global.game_manager.game_stats["level"]
	var current_level_name = Profiles.Levels.keys()[current_level_key]

	if current_level_key == Profiles.Levels.PRACTICE:
		$ContentPractice/DataContainer/Level.text %= current_level_name
		$ContentPractice/DataContainer/Points.text %= str(player_gameover_stats["player_points"])
		$ContentPractice/DataContainer/Time.text %= str(time_used)
		$ContentPractice/DataContainer/CellsTravelled.text %= str(player_gameover_stats["cells_travelled"])
		$ContentPractice/DataContainer/BurstCount.text %= str(player_gameover_stats["burst_count"])
		$ContentPractice/DataContainer/SkillsUsed.text %= str(player_gameover_stats["skill_count"])
		$ContentPractice/DataContainer/PixelsOff.text %= str(game_gameover_stats["off_pixels_count"])
		$ContentPractice/DataContainer/AstrayPixels.text %= str(game_gameover_stats["stray_pixels_count"])
	else:
		$ContentGame/DataContainer/Level.text %= str(current_level_name)
		$ContentGame/DataContainer/Points.text %= str(player_gameover_stats["player_points"])
		$ContentGame/DataContainer/Time.text %= str(time_used)
		$ContentGame/DataContainer/CellsTravelled.text %= str(player_gameover_stats["cells_travelled"])
		$ContentGame/DataContainer/BurstCount.text %= str(player_gameover_stats["burst_count"])
		$ContentGame/DataContainer/SkillsUsed.text %= str(player_gameover_stats["skill_count"])
		$ContentGame/DataContainer/PixelsOff.text %= str(game_gameover_stats["off_pixels_count"])
		$ContentGame/DataContainer/AstrayPixels.text %= str(game_gameover_stats["stray_pixels_count"])


# PAVZIRANJE --------------------------------------------------------------------	


func pause_tree():
	get_tree().paused = true


func unpause_tree():
	
	get_tree().paused = false
	set_process_input(true) # zato da se lahko animacija izvede
	
	
# POPUP INPUT --------------------------------------------------------------------	

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
	Global.game_manager.player_stats["player_name"] = input_string
	close_name_input()

	
func close_name_input (): 
	# samo zaprem
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade_out_tween.parallel().tween_property(undi, "modulate:a", 0.9, 1)
	fade_out_tween.parallel().tween_property(current_title, "modulate:a", 0, 1)
	fade_out_tween.tween_property(name_input_popup, "visible", false, 0.01)
	fade_out_tween.tween_callback(self, "emit_signal", ["name_input_finished"]).set_delay(0.5)


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
		input_string = Global.game_manager.player_stats["player_name"]
		confirm_name_input()
	else:
		confirm_name_input()
		

func _on_CancelBtn_pressed() -> void:
	$NameInputPopup/HBoxContainer/CancelBtn.grab_focus() # da se obarva ko stisnem ESC
	Global.sound_manager.play_gui_sfx("btn_cancel")
	close_name_input()


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_confirm")
	unpause_tree()
	Global.main_node.reload_game()
	
	if Global.game_manager.game_stats["level"] == Profiles.Levels.PRACTICE:
		$ContentPractice/Menu/RestartBtn.disabled = true # da ne moreš multiklikat
	else:
		$ContentGame/Menu/RestartBtn.disabled = true # da ne moreš multiklikat
	
	
func _on_QuitBtn_pressed() -> void:
	
	Global.sound_manager.play_sfx("btn_cancel")
	unpause_tree()
	Global.main_node.game_out()
	
	if Global.game_manager.game_stats["level"] == Profiles.Levels.PRACTICE:
		$ContentPractice/Menu/QuitBtn.disabled = true # da ne moreš multiklikat
	else:
		$ContentGame/Menu/QuitBtn.disabled = true # da ne moreš multiklikat
