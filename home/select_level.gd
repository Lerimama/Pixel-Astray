extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var select_level_btns_holder: Control = $LevelBtnsGrid
onready var default_focus_node: Control# = select_level_btns_holder.all_level_btns[0]


func _ready() -> void:


	Profiles.game_data_sweeper["level"] = 1 # ni nujno

	select_level_btns_holder.select_level_btns_holder_parent = self
	yield(get_tree().create_timer(0.1), "timeout") # da se zgodi po štartnem branju HS-jev
	select_level_btns_holder.spawn_level_btns()
	select_level_btns_holder.set_level_btns()
	select_level_btns_holder.connect_level_btns()

#	if Profiles.solution_hint_on:
#		solutions_btn.pressed = true
#	else:
#		solutions_btn.pressed = false
#
#	solutions_btn.modulate = Global.color_gui_gray # rešitev, ker gumb se na začetku obarva kot fokusiran

	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	default_focus_node = select_level_btns_holder.all_level_btns[0]

	if not visible: # zazih
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

	Global.main_node.home_out()


func _on_BackBtn_pressed() -> void:
	#	print ("pressed")

	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_level")
