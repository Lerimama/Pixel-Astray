extends Control



func _ready() -> void:

	hide()
	$PublishBtn.add_to_group(Global.group_menu_confirm_btns)
	$SkipBtn.add_to_group(Global.group_menu_cancel_btns)


func open_popup():
	
	#	modulate.a = 0
	show()
	#	var fade_in = get_tree().create_tween()
	#	fade_in.tween_property(self, "modulate:a", 1.0, 0.5)
	#	yield(fade_in, "finished")
	$PublishBtn.grab_focus()
	
	
func _on_PublishBtn_pressed() -> void:
	
#	Global.sound_manager.play_gui_sfx("btn_confirm")
	get_tree().set_pause(false) # setano čez celotno GO proceduro
#	$Confirm.hide() 
#	$PublishBtn.hide() 
#	$SkipBtn.hide()
	ConnectCover.open_and_connect(Global.gameover_gui.p1_final_stats)
	yield(ConnectCover, "connection_closed")
	#	var fade_out = get_tree().create_tween()
	#	fade_out.tween_callback(ConnectCover, "hide")
	#	fade_out.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	#	yield(fade_out, "finished")
	ConnectCover.hide()
	hide()


func _on_SkipBtn_pressed() -> void:
	
	hide()
	
#	Global.sound_manager.play_gui_sfx("btn_cancel")

