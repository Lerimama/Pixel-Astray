extends Control

onready var enigma_btn: Button = $Eternal/Enigma01Btn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var enigma_01_btn: Button = $LevelGrid/GridContainer/Enigma01Btn
onready var enigma_02_btn: Button = $LevelGrid/GridContainer/Enigma02Btn
onready var btn_grid_container: GridContainer = $LevelGrid/GridContainer

onready var enigma_level_btn_01: Button = $LevelGrid/GridContainer/Enigma01Btn
onready var enigma_level_btn_02: Button = $LevelGrid/GridContainer/Enigma02Btn
onready var enigma_01_btn_2: Button = $LevelGrid/GridContainer/Enigma01Btn2
onready var enigma_01_btn_3: Button = $LevelGrid/GridContainer/Enigma01Btn3
onready var enigma_01_btn_4: Button = $LevelGrid/GridContainer/Enigma01Btn4
onready var enigma_02_btn_2: Button = $LevelGrid/GridContainer/Enigma02Btn2
onready var enigma_01_btn_5: Button = $LevelGrid/GridContainer/Enigma01Btn5
onready var enigma_02_btn_3: Button = $LevelGrid/GridContainer/Enigma02Btn3
onready var enigma_01_btn_6: Button = $LevelGrid/GridContainer/Enigma01Btn6
onready var enigma_01_btn_7: Button = $LevelGrid/GridContainer/Enigma01Btn7
onready var enigma_01_btn_8: Button = $LevelGrid/GridContainer/Enigma01Btn8
onready var enigma_02_btn_4: Button = $LevelGrid/GridContainer/Enigma02Btn4


func _ready() -> void:
	
	# get solved enigmas
	var solved_levels: Array = Global.data_manager.read_solved_status_from_file(Profiles.game_data_enigma)
	# za vsak gumb preverim če pripada rešenemu level
	for btn in btn_grid_container.get_children():
		var btn_index: int = btn_grid_container.get_children().find(btn)
		var btn_level_conditions: Dictionary = Profiles.enigma_level_conditions[btn_index + 1]
		if solved_levels.has(btn_level_conditions["level_name"]):
			btn.modulate = Global.color_green
		

func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_enigma_level")
	get_viewport().set_disable_input(true)
	

func play_selected_level(selected_level: int):
	
	# set enigma game data
	Profiles.set_game_data(Profiles.Games.ENIGMA)
	# spremeni game data level v level name iz level conditions
	Profiles.current_game_data["level"] = Profiles.enigma_level_conditions[selected_level]["level_name"]
	Profiles.current_game_data["level_number"] = selected_level
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_enigma_level")
	get_viewport().set_disable_input(true)


func _on_Enigma01_Btn_pressed() -> void:
	play_selected_level(1)
	
func _on_Enigma02_Btn_pressed() -> void:
	play_selected_level(2)
