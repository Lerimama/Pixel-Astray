extends Control


var pause_fade_time: float = 0.5

signal name_input_finished

# level stats
onready var score: Label = $Score
onready var time: Label = $DataContainer/VBoxContainer/Time
onready var level: Label = $DataContainer/VBoxContainer/Level
onready var points: Label = $DataContainer/VBoxContainer/Points

onready var cells_travelled: Label = $DataContainer/VBoxContainer2/CellsTravelled
onready var skills_used: Label = $DataContainer/VBoxContainer2/SkillsUsed
onready var astray_pixels: Label = $DataContainer/VBoxContainer2/AstrayPixels
onready var pixels_off: Label = $DataContainer/VBoxContainer2/PixelsOff

# hs
onready var input_highscore_popup: Control = $InputHighscorePopup
onready var highscore_table: VBoxContainer = $HighscoreTable
onready var name_edit: LineEdit = $InputHighscorePopup/VBoxContainer/NameEdit


func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
#	highscore_table.visible = false ... sem dal na ready
	input_highscore_popup.visible = false

	
func fade_in():

	var final_player_stats: Dictionary = Global.game_manager.player_stats
	var final_game_stats: Dictionary = Global.game_manager.game_stats

	# write stats
	time.text = "SKILLS USED: %04d" % final_player_stats["skills_used"]
	points.text = "POINTS: %04d" % final_player_stats["player_points"]
	cells_travelled.text = "CELLS TRAVELLED: %04d" % final_player_stats["cells_travelled"]
	skills_used.text = "SKILLS USED: %04d" % final_player_stats["skills_used"]
	
	level.text = "LEVEL REACHED: %02d" % final_game_stats["level_no"]
	astray_pixels.text = "PIXELS ASTRAY: %02d" % final_game_stats["stray_pixels_count"]
	pixels_off.text = "PIXELS OFFED: %02d /" % final_game_stats["off_pixels_count"]
	
	score.text = "Dosegel si %s tock." % final_player_stats["player_points"]
	
	modulate.a = 0
	visible = true
	set_process_input(false)
	
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")


# HS --------------------------------------------------------------------	

func open_highscore_input():
	
	input_highscore_popup.visible = true
	name_edit.grab_focus()
	print ("GO - open input")
	
	
func confirm_highscore_input(text_string):
	
	Global.game_manager.player_stats["player_name"] = text_string
	input_highscore_popup.visible = false
	emit_signal("name_input_finished")
	
	
func cancel_highscore_input():
	
	input_highscore_popup.visible = false
	emit_signal("name_input_finished")



# PAVZIRANJE --------------------------------------------------------------------	

func pause_tree():
	
	get_tree().paused = true
	# set_process_input(true) # zato da se lahko animacija izvede


func unpause_tree():
	
	get_tree().paused = false
	visible = false
	set_process_input(true) # zato da se lahko animacija izvede


# SIGNALI --------------------------------------------------------------------	

func _on_PopupNameEdit_text_entered(new_text: String) -> void:
	confirm_highscore_input(new_text)

func _on_PopupConfirmBtn_pressed(new_text: String) -> void:
	confirm_highscore_input(new_text)
	
func _on_PopupCancelBtn_pressed() -> void:
	cancel_highscore_input()
	
	
func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()
	

