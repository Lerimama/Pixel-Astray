extends Control


func _ready() -> void:
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # za_poenoten slajder v settingsih in pavzi
#	add_color_schemes()
	
func _process(delta: float) -> void:
	
	# pravilno stanje settingsov
	
	# menu music
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicCheckBox.pressed = false
	else:
		$MenuMusicCheckBox.pressed = true

	# game music
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicCheckBox.pressed = false
	else:
		$GameMusicCheckBox.pressed = true
	
	# game sfx
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxCheckBox.pressed = false
	else:
		$GameSfxCheckBox.pressed = true
	
	# camera shake
	if Global.main_node.camera_shake_on:
		$CamerShakeCheckBox.pressed = true
	else:
		$CamerShakeCheckBox.pressed = false
	
#onready var color_options: OptionButton = $ColorOptions
#onready var color_scheme_icon: TextureRect = $ColorOptions/ColorSchemeIcon
#
#func add_color_schemes():
#	color_options.add_item("red", 0)
#	color_options.add_item("blue", 1)
#	color_options.add_icon_item(color_scheme_icon.texture, "icon", 2)
#
#	var available_color_schemes: Array = color_options.get_children()
#
#	print (available_color_schemes.size())
#	for color_scheme in available_color_schemes:
#		color_options.add_icon_item(color_scheme, "blue", 2)

	
	
func _on_MenuMusicCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu_music")
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.stop_music("menu_music")
		Global.sound_manager.menu_music_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")

	
func _on_GameMusicCheckBox_toggled(button_pressed: bool) -> void: 
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_MusicHSlider_value_changed(value: float) -> void:
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxCheckBox_toggled(button_pressed: bool) -> void:
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.game_sfx_set_to_off = true
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_CamerShakeCheckBox_toggled(button_pressed: bool) -> void:
	
	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.main_node.camera_shake_on = true
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.main_node.camera_shake_on = false
		Global.sound_manager.play_gui_sfx("btn_cancel")



#func _on_StrayCountOptionButton_item_selected(index: int) -> void:
#	match index:
#		0: Profiles.default_level_data["strays_start_count"] = Profiles.settings_strays_amount_1
#		1: Profiles.default_level_data["strays_start_count"] = Profiles.settings_strays_amount_2
#		2: Profiles.default_level_data["strays_start_count"] = Profiles.settings_strays_amount_3
#		3: Profiles.default_level_data["strays_start_count"] = Profiles.settings_strays_amount_4
#		4: Profiles.default_level_data["strays_start_count"] = Profiles.settings_strays_amount_5


onready var colors: HBoxContainer = $ColorSchemeOptions/Colors
onready var selected_color_scheme: Dictionary = Profiles.game_color_schemes["color_scheme_1"]


func color_scheme_selector(pressed_btn_name: String):
	
	var available_color_schemes: Array = colors.get_children()
	
	for color_btn in available_color_schemes:
		if color_btn.name != pressed_btn_name: # deselect all other
			color_btn.set_pressed_no_signal(false)
		if color_btn.name == pressed_btn_name and not color_btn.is_pressed(): # retoggle pressed button
			color_btn.set_pressed_no_signal(true)
	
	print("selected_color_scheme ", selected_color_scheme)	


func _on_ColorBtn_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_1"]
	color_scheme_selector("ColorBtn")
	
func _on_ColorBtn2_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_2"]
	color_scheme_selector("ColorBtn2")
	Global.game_manager.reset_intro_colors()

func _on_ColorBtn3_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_3"]
	color_scheme_selector("ColorBtn3")

func _on_ColorBtn4_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_4"]
	color_scheme_selector("ColorBtn4")

func _on_ColorBtn5_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_5"]
	color_scheme_selector("ColorBtn5")

func _on_ColorBtn6_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_6"]
	color_scheme_selector("ColorBtn6")

func _on_ColorBtn7_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_7"]
	color_scheme_selector("ColorBtn7")

func _on_ColorBtn8_toggled(button_pressed: bool) -> void:
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_8"]
	color_scheme_selector("ColorBtn8")


