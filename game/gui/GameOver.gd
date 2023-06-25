extends Control


var fade_time: float = 0.5

signal name_input_finished

# focus btn
onready var restart_btn: Button = $Content/Menu/RestartBtn

# animacija
onready var undi: ColorRect = $Undi
onready var title: Control = $Title
onready var content: Control = $Content

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
	title.visible = true
	title.modulate.a = 1
	

func fade_in():

	visible = true
#	set_process_input(false)
	
	# hud int tile in
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
	

func fade_in_empty():

	visible = true
#	set_process_input(false)
	
	# hud z napisom
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_callback(self, "open_name_input").set_delay(1)


func write_gameover_data():
	
	var player_gameover_stats: Dictionary = Global.game_manager.player_stats
	var game_gameover_stats: Dictionary = Global.game_manager.game_stats

	# write stats
	time.text = "Skills used: %04d" % player_gameover_stats["skills_used"]
	points.text = "Points scored: %04d" % player_gameover_stats["player_points"]
	cells_travelled.text = "Cells travelled: %04d" % player_gameover_stats["cells_travelled"]
	skills_used.text = "Skills used: %04d" % player_gameover_stats["skills_used"]
	
	level.text = "Level reched: %02d" % game_gameover_stats["level_no"]
	astray_pixels.text = "Pixels astray: %02d" % game_gameover_stats["stray_pixels_count"]
	pixels_off.text = "Pixels offed: %02d" % game_gameover_stats["off_pixels_count"]
	
	
# INPUT --------------------------------------------------------------------	


func open_name_input():
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	
	name_input.grab_focus()
	print ("GO - open input")
	
	
func confirm_name_input():
	
	Global.game_manager.player_stats["player_name"] = input_string
	close_name_input()
	
	
func close_name_input(): 

	write_gameover_data()
	highscore_table.get_highscore_table()
	
	# title out, content in
	var fade = get_tree().create_tween()
	fade.tween_property(title, "modulate:a", 0, 0.5)
	fade.parallel().tween_property(undi, "modulate:a", 0.9, 0.5)
	fade.parallel().tween_property(name_input_popup, "modulate:a", 0, 0.5)
	fade.tween_property(name_input_popup, "visible", true, 0.01)
	fade.tween_property(content, "modulate:a", 1, 1).set_delay(0.3)
	fade.tween_callback(self, "pause_tree")

	restart_btn.grab_focus()
	
	emit_signal("name_input_finished")
	


# PAVZIRANJE --------------------------------------------------------------------	

func pause_tree():
	
#	Global.node_creation_parent.pause_mode = 
	get_tree().paused = true


func unpause_tree():
	
	get_tree().paused = false
	set_process_input(true) # zato da se lahko animacija izvede


# SIGNALI --------------------------------------------------------------------	

func _on_PopupNameEdit_text_entered(new_text: String) -> void:
	input_string = new_text
	confirm_name_input()
	
	
func _on_NameEdit_text_changed(new_text: String) -> void:
	input_string = new_text

var input_string: String# = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

func _on_PopupConfirmBtn_pressed() -> void:
	print (input_string)
	if input_string.empty():
		close_name_input()
	confirm_name_input()
	
	
func _on_PopupCancelBtn_pressed() -> void:
	close_name_input()
	
	
func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()


