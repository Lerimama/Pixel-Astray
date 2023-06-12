extends Control


var pause_fade_time: float = 0.5



onready var score: Label = $Score

onready var time: Label = $DataContainer/VBoxContainer/Time
onready var level: Label = $DataContainer/VBoxContainer/Level
onready var points: Label = $DataContainer/VBoxContainer/Points
onready var cells_travelled: Label = $DataContainer/VBoxContainer2/CellsTravelled
onready var skills_used: Label = $DataContainer/VBoxContainer2/SkillsUsed
onready var astray_pixels: Label = $DataContainer/VBoxContainer2/AstrayPixels
onready var pixels_off: Label = $DataContainer/VBoxContainer2/PixelsOff


func _input(event: InputEvent) -> void:

	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_Q:
			fade_in()
			accept_event()


func _ready() -> void:
	
	Global.gameover_menu = self
	visible = false

	
func fade_in():

	var final_player_stats: Dictionary = Global.game_manager.player_stats
	var final_game_stats: Dictionary = Global.game_manager.game_stats

	# write stats
	time.text = "SKILLS USED: %04d" % final_player_stats["skills_used"]
	level.text = "SKILLS USED: %04d" % final_player_stats["skills_used"]
	points.text = "POINTS: %04d" % final_player_stats["player_points"]
	cells_travelled.text = "CELLS TRAVELLED: %04d" % final_player_stats["cells_travelled"]
	skills_used.text = "SKILLS USED: %04d" % final_player_stats["skills_used"]
	astray_pixels.text = "PIXELS ASTRAY: %02d" % final_game_stats["stray_pixels_count"]
	pixels_off.text = "PIXELS OFFED: %02d /" % final_game_stats["off_pixels_count"]
	
	score.text = "Dosegel si %s tock." % final_player_stats["player_points"]
	
	modulate.a = 0
	visible = true
	set_process_input(false)
	
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")
	

func pause_tree():
	
	get_tree().paused = true
#	set_process_input(true) # zato da se lahko animacija izvede


func unpause_tree():
	
	get_tree().paused = false
	visible = false
	set_process_input(true) # zato da se lahko animacija izvede


func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
#	Global.reload_scene(Global.current_scene, game_scene_path, Global.main_node)
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()
#	Global.release_scene(Global.current_scene)
#	Global.spawn_new_scene(home_scene_path, Global.main_node)
	
