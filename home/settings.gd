extends Control


onready var randomize_btn: Button = $ColorSchemeOptions/RandomizeBtn
onready var reset_btn: Button = $ColorSchemeOptions/ResetBtn	
onready var gradient_icon: TextureRect = $ColorSchemeOptions/RandomizeBtn/GradientIcon
onready var spectrum_icon: TextureRect = $ColorSchemeOptions/RandomizeBtn/SpectrumIcon

onready var intro: Node2D = $"%Intro"
onready var select_level_node: Control = $"../SelectLevel"
onready var select_game_node: Control = $"../SelectGame"


func _ready() -> void:

	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	
	# menu music state
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicBtn.pressed = false
	else:
		$MenuMusicBtn.pressed = true
	
	# game music state
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.pressed = false
	else:
		$GameMusicBtn.pressed = true
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten

	# game sfx state
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.pressed = false
	else:
		$GameSfxBtn.pressed = true
	
	# cam shake state
	if Profiles.camera_shake_on:
		$CameraShakeBtn.pressed = true
	else:
		$CameraShakeBtn.pressed = false

	# pregame screen
	if Profiles.default_game_settings["show_game_instructions"] == true:
		$InstructionsBtn.pressed = true
	else:
		$InstructionsBtn.pressed = false
		
	# color scheme selector state
	if Profiles.use_default_color_theme:
		spectrum_icon.show()
		gradient_icon.hide()
		reset_btn.hide()
	else:
		spectrum_icon.hide()
		gradient_icon.show()
		reset_btn.show()
		gradient_icon.texture.gradient = Global.game_color_theme_gradient
		
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("settings")
	
		
func _on_MenuMusicBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu_music")
	else:
		Global.sound_manager.stop_music("menu_music")
		Global.sound_manager.menu_music_set_to_off = true


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
	else:
		Global.sound_manager.game_music_set_to_off = true


func _on_MusicHSlider_value_changed(value: float) -> void:
	
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:
	
	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Profiles.camera_shake_on = true
	else:
		Profiles.camera_shake_on = false


func _on_InstructionsBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Profiles.default_game_settings["show_game_instructions"] = true
	else:
		Profiles.default_game_settings["show_game_instructions"] = false
		
		
# COLOR SCHEMES ----------------------------------------------------------------------------------------------------------------

	
func _on_ResetBtn_pressed() -> void:
	
	spectrum_icon.show()
	gradient_icon.hide()
	reset_btn.hide()
	
	Profiles.use_default_color_theme = true
	randomize_btn.grab_focus()
	#	Global.grab_focus_no_sfx(randomize_btn) # _temp ven?

	intro.respawn_title_strays()
	select_level_node.select_level_btns_holder.color_level_btns()
	select_game_node.color_game_btns()


func _on_RandomizeBtn_pressed() -> void:
		
	spectrum_icon.hide()
	gradient_icon.show()
	reset_btn.show()
	
	Profiles.use_default_color_theme = false
	
	var current_color_scheme_gradient: Gradient = Global.get_random_gradient_colors(0) # 0 je za pravilno izbiro rezultata funkcije
	gradient_icon.texture.gradient = current_color_scheme_gradient
	
	intro.respawn_title_strays()
	select_level_node.select_level_btns_holder.set_level_btns()
	select_game_node.color_game_btns()
