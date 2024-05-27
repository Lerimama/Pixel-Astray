extends Control


onready var sweeper_btn: Button = $LevelGrid/BtnsHolder/Btn01
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var btn_grid_container: Control = $LevelGrid/BtnsHolder
onready var level_grid_btns: Array = btn_grid_container.get_children()
onready var solutions_btn: CheckButton = $LevelGrid/SolutionsBtn


func _ready() -> void:
	
	Profiles.game_data_sweeper["level"] = 1 # ni nujno
#	for btn in level_grid_btns:
#		set_btn_tilemap(btn)
	update_sweeper_btns()

	if Profiles.default_game_settings["show_solution_hint"]:
		solutions_btn.pressed = true
	else:
		solutions_btn.pressed = false
		

func _process(delta: float) -> void:
	
	if not get_parent().current_screen == get_parent().Screens.SELECT_LEVEL:
		return
		
	# barvam ozadje gumbov na focus
	var of_color = Global.color_almost_black_pixel
	
	for btn in level_grid_btns:
		# fokusian
		if btn.has_focus():
			btn.get_node("Background").color = btn_colors[level_grid_btns.find(btn)]
			btn.self_modulate = Color.white
		# nefokusiran
		else:
			btn.get_node("Background").color = of_color
			# rešena uganka
			if solved_sweeper_btns.has(btn):
				btn.set("custom_colors/font_color",  Color.white)
				btn.self_modulate = btn_colors[level_grid_btns.find(btn)]
			# nerešena uganka
			else:			
				btn.self_modulate = Color.white
		
				
var btn_colors: Array
var solved_sweeper_btns: Array
func update_sweeper_btns():
	
	var solved_levels: Array = Global.data_manager.read_solved_status_from_file(Profiles.game_data_sweeper)
	
	# naberem gumbe in barve za njih 
	btn_colors = []
	if Profiles.use_custom_color_theme:
		var color_split_offset: float = 1.0 / level_grid_btns.size()
		for btn_count in level_grid_btns.size():
			var color = Global.game_color_theme_gradient.interpolate(btn_count * color_split_offset) # barva na lokaciji v spektrumu
			btn_colors.append(color)	
	else:			
		btn_colors = Global.get_spectrum_colors(level_grid_btns.size())
	
	# poimenujem in obarvam solved gumbe 
	solved_sweeper_btns = []
	for btn in level_grid_btns:
		var btn_index: int = level_grid_btns.find(btn)
		btn.text = "%02d" % (btn_index + 1)
		# za vsak gumb preverim če pripada rešenemu level
		if level_grid_btns.find(btn) + 1 in solved_levels:
			btn.set("custom_colors/font_color",  Color.white)
			btn.self_modulate = btn_colors[btn_index]
			solved_sweeper_btns.append(btn)
			
		
func set_btn_tilemap(btn: Button):
				
		var BtnTilemap: PackedScene
		var tilemap_position_adapt: float
		match btn.name:
			"01":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn")
				tilemap_position_adapt = 0
			"02":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_02.tscn")
				tilemap_position_adapt = 0
			"03":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_03.tscn")
				tilemap_position_adapt = 0
			"04":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_04.tscn")
				tilemap_position_adapt = 2
			"05":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_05.tscn")
				tilemap_position_adapt = 2
			"06":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_06.tscn")
				tilemap_position_adapt = 2
			"07":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_07.tscn")
				tilemap_position_adapt = 2
			"08":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_08.tscn")
				tilemap_position_adapt = 2
			"09":
				BtnTilemap =  preload("res://game/tilemaps/sweeper/tilemap_sweeper_09.tscn")
				tilemap_position_adapt = 2

		var tilemap_scale_div: float = 8
		var cell_size_x: float = 32

		var new_btn_tilemap = BtnTilemap.instance()
		new_btn_tilemap.scale /=  tilemap_scale_div
		new_btn_tilemap.show_behind_parent = true
#		new_btn_tilemap.z_index = -1
		btn.add_child(new_btn_tilemap)

		var tilemap_reduced_size: Vector2 = new_btn_tilemap.get_used_rect().size * cell_size_x/2 / tilemap_scale_div
		# sredinska pozicija
		new_btn_tilemap.position.x = btn.rect_size.x/2 - tilemap_reduced_size.x# - btn.rect_size.x
		new_btn_tilemap.position.y = btn.rect_size.y/2 - tilemap_reduced_size.y
		# daptacija zamika pixilov
		new_btn_tilemap.position.x += tilemap_position_adapt
		new_btn_tilemap.position.y += tilemap_position_adapt
		# barvanje 
		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.edge_tile_id, Color(1,1,1,0))
		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.edge_tile_id, Color.red)
		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.floor_tile_id, Color(1,1,1,0))
		new_btn_tilemap.get_tileset().tile_set_modulate(new_btn_tilemap.spawn_stray_tile_id, Color.white) # prava barva se seta v select levels, v igri se jo itak zamenja s tlemi
		
		new_btn_tilemap.set_process_input(false)
		

func play_selected_level(selected_level: int):
	
	# set sweeper game data
	Profiles.set_game_data(Profiles.Games.SWEEPER)
	# spremeni game data level s tistim v level settings
	Profiles.game_data_sweeper["level"] = selected_level
#	Profiles.current_game_data["level"] = selected_level
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_level")
	get_viewport().set_disable_input(true)

			
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_level")
	get_viewport().set_disable_input(true)


func _on_SolutionsBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		 Profiles.default_game_settings["show_solution_hint"] = true
	else:
		 Profiles.default_game_settings["show_solution_hint"] = false
		


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
