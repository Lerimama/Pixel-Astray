extends Node2D

onready var game: Node2D = $Game
onready var gui: Node2D = $Gui


onready var all_game_sounds: Array = game.get_children()
onready var all_gui_sounds: Array = gui.get_children()


func _ready() -> void:
	Global.sound_manager = self
	randomize()
	
func play(sfx_name = null):
	
	
#	var sound_to_play = all_sounds[sfx_no]
#	sound_to_play.play()

	if sfx_name:
		get_node(sfx_name).play()
	else:
		var c = randi() % get_child_count()
		get_child(c).play() 




var game_click_count = 0
var gui_click_count = 0


func _on_GameSfxBtn_button_up() -> void:
	
	all_game_sounds[game_click_count].play()
	
	printt ("game_click_count", game_click_count, game.get_child_count())
	game_click_count += 1 
	if game_click_count == game.get_child_count():
		game_click_count = 0	
	

func _on_GuiSfxBtn_button_up() -> void:
	
	all_gui_sounds[gui_click_count].play()
	printt ("gui_click_count", gui_click_count, gui.get_child_count())
	gui_click_count += 1 
	if gui_click_count == gui.get_child_count():
		gui_click_count = 0	


func _on_ResetCountBtn_pressed() -> void:
	game_click_count = 0
	gui_click_count = 0
