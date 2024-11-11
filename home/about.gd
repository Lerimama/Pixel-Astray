extends Control


onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var default_focus_node: Control = $BackBtn


func _ready() -> void:
	
	# menu btn group
	$BackBtn.add_to_group(Global.group_menu_cancel_btns)
	
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	animation_player.play_backwards("about")


func _on_NameAuthor_meta_clicked(meta) -> void:
	# print("meta", meta)
	OS.shell_open(meta)
