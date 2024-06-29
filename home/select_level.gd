extends Control


#var unfocused_color: Color = Global.color_almost_black_pixel
#var btn_colors: Array
#var solved_sweeper_btns: Array

#var unlocked_label_path: String = "VBoxContainer/Label"
#var locked_label_path: String = "VBoxContainer/LabelLocked"
#var record_label_path: String = "VBoxContainer/Record"
#var owner_label_path: String = "VBoxContainer/Owner"

#var all_level_btns: Array# = btn_grid_container.get_children()

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var solutions_btn: CheckButton = $SolutionsBtn
#onready var pixel_astray_level_btn: Button = $SelectLevelBtnsHolder/PixelAstrayLevelBtn
#onready var LevelBtn: PackedScene = preload("res://home/level_btn.tscn")

# neu
onready var select_level_btns_holder: Control = $SelectLevelBtnsHolder
#onready var btn_grid_container_parent: Control = self

func _ready() -> void:
	
	Profiles.game_data_sweeper["level"] = 1 # ni nujno

	select_level_btns_holder.select_level_btns_holder_parent = self
	select_level_btns_holder.spawn_level_btns()
	select_level_btns_holder.set_level_btns()
	select_level_btns_holder.connect_level_btns()	
	
	if Profiles.solution_hint_on:
		solutions_btn.pressed = true
	else:
		solutions_btn.pressed = false
	
	solutions_btn.modulate = Global.color_gui_gray # rešitev, ker gumb se na začetku obarva kot fokusiran	

	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	
	if not visible: # varovalka
		show()
	


func play_selected_level(selected_level: int):

	# set sweeper level
	Profiles.game_data_sweeper["level"] = selected_level

	# set sweeper game data
	var sweeper_settings = Profiles.set_game_data(Profiles.Games.SWEEPER)
	# zmeraj gre na next level iz GO menija, se navoidla ugasnejo (so ugasnjena po defoltu)
	if Profiles.default_game_settings["show_game_instructions"] == true: # igra ima navodila, če so navodila vklopljena 
		sweeper_settings["show_game_instructions"] = true
	sweeper_settings["always_zoomed_in"] = false
	Global.sound_manager.play_gui_sfx("menu_fade")
	animation_player.play("play_level")

			
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_level")


func _on_SolutionsBtn_toggled(button_pressed: bool) -> void: # trenutno skirt in defokusiran
	
	if button_pressed:
		 Profiles.solution_hint_on = true
	else:
		 Profiles.solution_hint_on = false
