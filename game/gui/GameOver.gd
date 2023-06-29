extends Control


var fade_time: float = 0.5

signal name_input_finished

# focus btn
onready var restart_btn: Button = $Content/Menu/RestartBtn

# animacija
onready var undi: ColorRect = $Undi
onready var title: Control = $Title
onready var content: Control = $Content
onready var died_label: Label = $Title/DiedLabel
onready var timeup_label: Label = $Title/TimeupLabel


# level stats
onready var time: Label = $Content/DataContainer/Time
onready var level: Label = $Content/DataContainer/Level
onready var points: Label = $Content/DataContainer/Points
onready var cells_travelled: Label = $Content/DataContainer/CellsTravelled
onready var skills_used: Label = $Content/DataContainer/SkillsUsed
onready var astray_pixels: Label = $Content/DataContainer/AstrayPixels
onready var pixels_off: Label = $Content/DataContainer/PixelsOff

# hs
onready var name_input_popup: Control = $NameInputPopup
onready var highscore_table: VBoxContainer = $Content/HighscoreTable
onready var name_input: LineEdit = $NameInputPopup/NameInput


func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	modulate.a = 0
	
	name_input_popup.visible = false
	content.modulate.a = 0
#	title.visible = true
#	title.modulate.a = 1
	

func fade_in(gameover_reason: String):
	
	match gameover_reason:
		"game_time":
			timeup_label.visible = true
			died_label.visible = false
		"player_life":
			timeup_label.visible = false
			died_label.visible = true
			
	modulate.a = 0	
	visible = true
#	set_process_input(false)
	
	# hud + title
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	
	write_gameover_data()
	highscore_table.get_highscore_table()
	
	yield(get_tree().create_timer(2), "timeout")

	# title out, content in
	var fade = get_tree().create_tween()
	fade.tween_property(title, "modulate:a", 0, 1)
	fade.parallel().tween_property(undi, "modulate:a", 0.9, 1)
	fade.tween_property(content, "modulate:a", 1, 1).set_delay(0.3)
	fade.tween_callback(self, "pause_tree")
	
	restart_btn.grab_focus()
	

func fade_in_empty(gameover_reason: String):
	
	match gameover_reason:
		"game_time":
			timeup_label.visible = true
			died_label.visible = false
		"player_life":
			timeup_label.visible = false
			died_label.visible = true
			
	modulate.a = 0	
	visible = true
#	set_process_input(false)
	
	# hud + title + name input
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_callback(self, "open_name_input").set_delay(1)


func show_content():
	
	# title se odfejda v close_name_input()
	
	write_gameover_data()
	highscore_table.get_highscore_table()
	
	var fade_in_tween = get_tree().create_tween()		
	fade_in_tween.tween_property(content, "modulate:a", 1, 1).set_delay(0.3)
	fade_in_tween.tween_callback(self, "pause_tree")

	restart_btn.grab_focus()


func write_gameover_data():
	
	var player_gameover_stats: Dictionary = Global.game_manager.player_stats
	var game_gameover_stats: Dictionary = Global.game_manager.game_stats

	# write stats
	time.text = "Time: " + str(Global.hud.game_time.mins.text) + "min " + str(Global.hud.game_time.secs.text) + " sec" # čas vzmem direkt iz tajmerja
	points.text = "Points scored: %04d" % player_gameover_stats["player_points"]
	cells_travelled.text = "Cells travelled: %04d" % player_gameover_stats["cells_travelled"]
	skills_used.text = "Skills used: %04d" % player_gameover_stats["skills_used"]
	
	level.text = "Level reched: %02d" % game_gameover_stats["level_no"]
	astray_pixels.text = "Pixels astray: %02d" % game_gameover_stats["stray_pixels_count"]
	pixels_off.text = "Pixels offed: %02d" % game_gameover_stats["off_pixels_count"]
	
	
# INPUT --------------------------------------------------------------------	


func open_name_input():
	
	print ("GO - open name input")
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	
	# setam input label
	name_input.text = input_invite_text
	name_input.grab_focus()
	
# pogrebam string
func confirm_name_input():
	
	# zapišem ime v končno statistiko igralca
	Global.game_manager.player_stats["player_name"] = input_string
	close_name_input()
	
# samo zaprem
func close_name_input (): 
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(title, "modulate:a", 0, 0.5)
	fade_out_tween.parallel().tween_property(undi, "modulate:a", 0.9, 0.5)
	fade_out_tween.parallel().tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade_out_tween.tween_property(name_input_popup, "visible", false, 0.01)
	
	emit_signal("name_input_finished")
	


# PAVZIRANJE --------------------------------------------------------------------	

func pause_tree():
	
#	Global.node_creation_parent.pause_mode = 
	get_tree().paused = true
	pass


func unpause_tree():
	
	get_tree().paused = false
	set_process_input(true) # zato da se lahko animacija izvede


# SIGNALI --------------------------------------------------------------------	


var input_invite_text: String = "Your name ..."
var input_string: String# = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

# signal, ki redno beleži vnešeni string
func _on_NameEdit_text_changed(new_text: String) -> void:
	input_string = new_text
	
func _on_PopupNameEdit_text_entered(new_text: String) -> void:
	printt("input_string", input_string)
	if input_string == input_invite_text or input_string.empty():
		input_string = Profiles.default_player_stats["player_name"] #Moe
		confirm_name_input()
	else:
		confirm_name_input()
	

func _on_PopupConfirmBtn_pressed() -> void:
	printt("btn input_string", input_string)
	if input_string == input_invite_text or input_string.empty():
		input_string = Profiles.default_player_stats["player_name"] #Moe
		confirm_name_input()
	else:
		confirm_name_input()
	
	
func _on_PopupCancelBtn_pressed() -> void:
	close_name_input()
	
	
func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()


