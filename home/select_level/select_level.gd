extends Control


export (Profiles.Games) var game_key: int = -1

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var select_level_btns_holder: Control = $LevelBtnsGrid
onready var default_focus_node: Control# = select_level_btns_holder.all_level_btns[0]


func _ready() -> void:

	select_level_btns_holder.btns_holder_parent = self
	yield(get_tree().create_timer(0.1), "timeout") # da se zgodi po štartnem branju HS-jev

	select_level_btns_holder.spawn_level_btns(game_key)
	select_level_btns_holder.call_deferred("set_level_btns_content")

	# menu btn group
	$BackBtn.add_to_group(Batnz.group_cancel_btns)
	default_focus_node = select_level_btns_holder.all_level_btns[0]
	default_focus_node.add_to_group(Global.group_critical_btns)

	if not visible: # zazih
		show()


func play_selected_level(selected_level: String):

	# set game data level
	var level_game_data = Profiles.game_data[game_key]
	level_game_data["level_name"] = selected_level

	# set game data
	var game_level_settings = Profiles.set_game_data(game_key)

	Global.main_node.home_out()
