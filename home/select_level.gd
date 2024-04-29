extends Control


onready var enigma_btn: Button = $LevelGrid/GridContainer/EnigmaBtn
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var btn_grid_container: GridContainer = $LevelGrid/GridContainer
onready var spectrum_rect: TextureRect = $Spectrum
onready var level_grid_btns: Array = btn_grid_container.get_children()


func _ready() -> void:
	
	Profiles.game_data_enigma["level"] = 1
	
	# get solved enigmas
	var solved_levels: Array = Global.data_manager.read_solved_status_from_file(Profiles.game_data_enigma)

	# obarvaj na mavrico
	# setam sliko spektruma (za žrebanje in prvi level)
	var spectrum_image: Image
	var spectrum_texture: Texture = spectrum_rect.texture
	spectrum_image = spectrum_texture.get_data()
	spectrum_image.lock()
	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	var color_split_offset: float = spectrum_texture_width / level_grid_btns.size() - 1# razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv	
	# obarvam gumbe, ki so "solved" 
	var level_grid_btns: Array = btn_grid_container.get_children()
	for btn in level_grid_btns:
		var btn_color_position_x: float = level_grid_btns.find(btn) * color_split_offset # lokacija barve v spektrumu
		var btn_color: Color = spectrum_image.get_pixel(btn_color_position_x, 0) # barva na lokaciji v spektrumu
		# za vsak gumb preverim če pripada rešenemu level
		if level_grid_btns.find(btn) + 1 in solved_levels:
			btn.modulate = btn_color
		
		
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
