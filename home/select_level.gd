extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var select_level_btns_holder: Control = $LevelBtnsGrid
onready var default_focus_node: Control# = select_level_btns_holder.all_level_btns[0]


func _ready() -> void:


	Profiles.game_data_sweeper["level"] = 1 # ni nujno

	select_level_btns_holder.btns_holder_parent = self
	yield(get_tree().create_timer(0.1), "timeout") # da se zgodi po štartnem branju HS-jev

	select_level_btns_holder.spawn_level_btns()
	select_level_btns_holder.call_deferred("set_level_btns_content")

	# menu btn group
	$BackBtn.add_to_group(Batnz.group_cancel_btns)
	default_focus_node = select_level_btns_holder.all_level_btns[0]

	if not visible: # zazih
		show()


func play_selected_level(selected_level: int):

	# set sweeper level
	Profiles.game_data_sweeper["level"] = selected_level

	# set sweeper game data
	var sweeper_settings = Profiles.set_game_data(Profiles.Games.SWEEPER)

	Global.main_node.home_out()


func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("select_level")
