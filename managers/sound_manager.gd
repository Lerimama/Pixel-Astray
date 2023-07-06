extends Node2D

onready var game: Node2D = $Game
onready var gui: Node2D = $Gui


onready var all_game_sounds: Array = game.get_children()
onready var all_gui_sounds: Array = gui.get_children()


func _ready() -> void:
	Global.sound_manager = self
	randomize()

	
onready var stepping: Node2D = $Game/Stepping
onready var blinking: Node2D = $Game/Blinking
onready var blinking_static: Node2D = $Game/BlinkingStatic

func play_sfx(sfx_to_play: String):
	
	# če zvoka ni tukaj, pomeni da ga kličem direktno
	match sfx_to_play:
		"stepping":
			select_random_sound(stepping).play()
		"blinking":
			select_random_sound(blinking_static).play()
			select_random_sound(blinking).play()
		"teleport":
			$Game/TeleportStart.play()

#		Global.sound_manager.game.get_node("StrayOffed").play()	

func stop_sfx(sfx_to_stop: String):
	
	match sfx_to_stop:
#			"stepping":
#				select_random_sound(stepping).play()
#			"blinking":Teleport2
#				select_random_sound(blinking_static).play()
#				select_random_sound(blinking).play()
			"teleport":
				$Game/Teleport.stop()
				$Game/TeleportEnd.play()


func _on_TeleportStart_finished() -> void:
	$Game/Teleport.play()
	
		
#	elif sfx_name == "HitStray"
	
	
	# :else:
		
#	var sound_to_play = all_sounds[sfx_no]
#	sound_to_play.play()
#
#	if sfx_name:
#		get_node(sfx_name).play()
#	else:
#		var c = randi() % get_child_count()
#		get_child(c).play() 
	
		
		
func select_random_sound(sound_group):
	
	var random_index = randi() % sound_group.get_child_count()
	var selected_sound = sound_group.get_child(random_index)
	return selected_sound








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

