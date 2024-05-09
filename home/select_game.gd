extends Control

onready var enigma_btn: Button = $GameBtns/EnigmaBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"

onready var riddler_btns_holder: Control = $"../SelectLevel/LevelGrid/VBoxContainer/BtnsHolder" # za število ugank
onready var riddle_count: int = riddler_btns_holder.get_child_count()
onready var riddler_label: Label = $Enigma/Label


func _ready() -> void:
	
	riddler_label.text %= str(riddle_count)

	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_game")
	get_viewport().set_disable_input(true)
	

func play_selected_game(selected_game_enum: int):
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_game")
	get_viewport().set_disable_input(true)
	
		
# at the cleaners -----------------------------------------------------------------------------------------


func _on_TutorialBtn_pressed() -> void:
	play_selected_game(Profiles.Games.TUTORIAL)

	
func _on_EraserSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_S)
func _on_EraserMBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_M)
func _on_EraserLBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_L)


func _on_CleanerSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_S)
func _on_CleanerMBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_M)
func _on_CleanerLBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_L)
	
	
func _on_ScrollerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.SCROLLER)


func _on_TheDuelBtn_pressed() -> void:
	play_selected_game(Profiles.Games.THE_DUEL)


func _on_Enigma_Btn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play("select_enigma_level")
	get_viewport().set_disable_input(true)
