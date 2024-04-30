extends Control


onready var enigma_btn: Button = $LevelGrid/GridContainer/EnigmaBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var btn_grid_container: GridContainer = $LevelGrid/GridContainer
onready var level_grid_btns: Array = btn_grid_container.get_children()
onready var color_spectrum: TextureRect = $"../Spectrum"


func _ready() -> void:
	
	Profiles.game_data_enigma["level"] = 1
	
	# obarvam solved gumbe 
	var solved_levels: Array = Global.data_manager.read_solved_status_from_file(Profiles.game_data_enigma)
	var level_grid_btns: Array = btn_grid_container.get_children()
	var btn_colors: Array = Global.get_spectrum_colors(level_grid_btns.size())
	for btn in level_grid_btns:
		var btn_index: int = level_grid_btns.find(btn)
		# za vsak gumb preverim če pripada rešenemu level
		if level_grid_btns.find(btn) + 1 in solved_levels:
			btn.modulate = btn_colors[btn_index]
		
		
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_enigma_level")
	get_viewport().set_disable_input(true)
	

func play_selected_level(selected_level: int):
	
	# set enigma game data
	Profiles.set_game_data(Profiles.Games.ENIGMA)
	# spremeni game data level s tistim v level settings
	Profiles.game_data_enigma["level"] = selected_level
#	Profiles.current_game_data["level"] = selected_level
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_enigma_level")
	get_viewport().set_disable_input(true)


func _on_EnigmaBtn_pressed() -> void:
	play_selected_level(1)
func _on_EnigmaBtn2_pressed() -> void:
	play_selected_level(2)
func _on_EnigmaBtn3_pressed() -> void:
	play_selected_level(3)
func _on_EnigmaBtn4_pressed() -> void:
	play_selected_level(4)
func _on_EnigmaBtn5_pressed() -> void:
	play_selected_level(5)
func _on_EnigmaBtn6_pressed() -> void:
	play_selected_level(6)
func _on_EnigmaBtn7_pressed() -> void:
	play_selected_level(7)
func _on_EnigmaBtn8_pressed() -> void:
	play_selected_level(8)
func _on_EnigmaBtn9_pressed() -> void:
	play_selected_level(9)
