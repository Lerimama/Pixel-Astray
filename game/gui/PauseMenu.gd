extends Control


var pause_fade_time: float = 0.5
var pause_on: bool = false # samo za esc

# focus btn
onready var play_btn: Button = $Menu/PlayBtn


func _input(event: InputEvent) -> void:
#func _unhandled_key_input(event: InputEventKey) -> void:
	
	if Global.game_manager.game_on:
		if event is InputEventKey:
			if event.pressed and event.scancode == KEY_ESCAPE:
				if not pause_on:
					pause_game()
				else:
					play_on()
				accept_event()


func _ready() -> void:
	visible = false
	modulate.a = 0

	
func pause_game():
	
	visible = true
	set_process_input(false)
	
	pause_on = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")
	
	play_btn.grab_focus()


func play_on():
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_fade_time)
	fade_out_tween.tween_property(self, "visible", false, 0.01)
	fade_out_tween.tween_callback(self, "unpause_tree")


func pause_tree():
	
#	pause_on = true
	get_tree().paused = true
	set_process_input(true) # zato da se lahko animacija izvede
		
	
func unpause_tree():
	
	get_tree().paused = false
#	pause_on = false
	set_process_input(true) # zato da se lahko animacija izvede
	
	
# MENU ---------------------------------------------------------------------------------------------
	
	
func _on_PlayBtn_focus_exited() -> void:
	if pause_on:
		Global.sound_manager.play_sfx("btn_focus_change")

func _on_PlayBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	pause_on = false
	play_on()


func _on_RestartBtn_focus_exited() -> void:
	if pause_on:
		Global.sound_manager.play_sfx("btn_focus_change")

func _on_RestartBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	pause_on = false
	unpause_tree()
	Global.main_node.reload_game()


func _on_QuitBtn_focus_exited() -> void:
	if pause_on:
		Global.sound_manager.play_sfx("btn_focus_change")

func _on_QuitBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_cancel")
	pause_on = false
	unpause_tree()
	Global.main_node.game_out()
