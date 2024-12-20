extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var default_focus_node: Control = $BackBtn
onready var data_collecting_content: Label = $Data


func _ready() -> void:

	# menu btn group
	$BackBtn.add_to_group(Batnz.group_cancel_btns)

	if Profiles.html5_mode:
		data_collecting_content.visible = not Profiles.html5_mode

func _on_BackBtn_pressed() -> void:

	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("about")
	get_parent().menu_in()


func _on_NameAuthor_meta_clicked(meta) -> void:

	# print("meta", meta)
	OS.shell_open(meta)
