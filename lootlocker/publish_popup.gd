extends Control

signal score_published

onready var skip_btn: Button = $HBoxContainer/SkipBtn
onready var publish_btn: Button = $HBoxContainer/PublishBtn


func _ready() -> void:

	hide()
	publish_btn.add_to_group(Global.group_menu_confirm_btns)
	skip_btn.add_to_group(Global.group_menu_cancel_btns)


func open_popup():
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(self, "show")	
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	publish_btn.grab_focus()


func close_popup():
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(self, "modulate:a", 0, 0.5)	
	fade_out.tween_callback(self, "hide")	
	
	
func _on_PublishBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	skip_btn.disabled = true
	publish_btn.disabled = true
	
	get_tree().set_pause(false) # da lahko procedura steče
	LootLocker.submit_score_to_lootlocker(Global.gameover_gui.p1_final_stats)
	yield(LootLocker, "connection_closed")
	
	get_tree().set_pause(true) # spet setano čez celotno GO proceduro
	emit_signal("score_published")


func _on_SkipBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	emit_signal("score_published")
	

