extends Control


var pause_fade_time: float = 0.5

signal name_input_finished

var input_string: String # predvsem da zaznava vsako črko in jo lahko potrdiš na gumbu

# level stats
onready var data_container: VBoxContainer = $DataContainer
onready var score: Label = $Score
onready var time: Label = $DataContainer/Time
onready var level: Label = $DataContainer/Level
onready var points: Label = $DataContainer/Points
onready var cells_travelled: Label = $DataContainer/CellsTravelled
onready var skills_used: Label = $DataContainer/SkillsUsed
onready var astray_pixels: Label = $DataContainer/AstrayPixels
onready var pixels_off: Label = $DataContainer/PixelsOff

# hs
onready var input_highscore_popup: Control = $InputHighscorePopup
onready var highscore_table: VBoxContainer = $HighscoreTable
onready var name_edit: LineEdit = $InputHighscorePopup/VBoxContainer/NameEdit

onready var menu: HBoxContainer = $Menu



func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
#	highscore_table.visible = false ... sem dal na ready
	input_highscore_popup.visible = false
	highscore_table.visible = false
	data_container.visible = false
	menu.visible = false
	
func fade_in():

	var player_gameover_stats: Dictionary = Global.game_manager.player_stats
	var game_gameover_stats: Dictionary = Global.game_manager.game_stats

	# write stats
	time.text = "SKILLS USED: %04d" % player_gameover_stats["skills_used"]
	points.text = "POINTS: %04d" % player_gameover_stats["player_points"]
	cells_travelled.text = "CELLS TRAVELLED: %04d" % player_gameover_stats["cells_travelled"]
	skills_used.text = "SKILLS USED: %04d" % player_gameover_stats["skills_used"]
	
	level.text = "LEVEL REACHED: %02d" % game_gameover_stats["level_no"]
	astray_pixels.text = "PIXELS ASTRAY: %02d" % game_gameover_stats["stray_pixels_count"]
	pixels_off.text = "PIXELS OFFED: %02d /" % game_gameover_stats["off_pixels_count"]
	
	score.text = "Dosegel si %s tock." % player_gameover_stats["player_points"]
	
	modulate.a = 0
	visible = true
	set_process_input(false)
	
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")


func show_all_content():
	highscore_table.open_highscore_table()
	data_container.visible = true
	menu.visible = true
	

# HS --------------------------------------------------------------------	

func open_highscore_input():
	
	input_highscore_popup.visible = true
	name_edit.grab_focus()
	print ("GO - open input")
	
	
func confirm_highscore_input():
	
	Global.game_manager.player_stats["player_name"] = input_string
	input_highscore_popup.visible = false
	emit_signal("name_input_finished")
	
	
func cancel_highscore_input():
	
	input_highscore_popup.visible = false
	emit_signal("name_input_finished")



# PAVZIRANJE --------------------------------------------------------------------	

func pause_tree():
	
	get_tree().paused = true


func unpause_tree():
	
	get_tree().paused = false
	set_process_input(true) # zato da se lahko animacija izvede


# SIGNALI --------------------------------------------------------------------	

func _on_PopupNameEdit_text_entered(new_text: String) -> void:
	input_string = new_text
	confirm_highscore_input()
	
	
func _on_NameEdit_text_changed(new_text: String) -> void:
	input_string = new_text


func _on_PopupConfirmBtn_pressed() -> void:
	print (input_string)
	confirm_highscore_input()
	
func _on_PopupCancelBtn_pressed() -> void:
	cancel_highscore_input()
	
	
func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()
	pass


