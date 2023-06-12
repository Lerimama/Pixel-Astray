extends Control


var pause_fade_time: float = 0.5
var pause_on: bool = false # samo za esc

#var home_scene_path: String = "res://scenes/Home.tscn"
#var game_scene_path: String = "res://scenes/game/Game.tscn"


func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			if not pause_on:
				pause_play()
			else:
				play_on()
			accept_event()


func _ready() -> void:

	visible = false
	modulate.a = 0

	
func pause_play():
	
	visible = true
	set_process_input(false)
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	fade_in_tween.tween_callback(self, "pause_tree")



func play_on():
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_fade_time)
	fade_out_tween.tween_property(self, "visible:a", false, 0.01)
	
	fade_out_tween.tween_callback(self, "unpause_tree")


func pause_tree():
	
	pause_on = true
	get_tree().paused = true
	# set_process_input(true) # zato da se lahko animacija izvede
		
	
func unpause_tree():
	
	get_tree().paused = false
	pause_on = false
	set_process_input(true) # zato da se lahko animacija izvede
	
	
func _on_PlayBtn_pressed() -> void:
	play_on()


func _on_RestartBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.reload_game()
#	Global.reload_scene(Global.current_scene, game_scene_path, Global.main_node)


func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.main_node.game_out()
#	Global.release_scene(Global.current_scene)
#	Global.spawn_new_scene(home_scene_path, Global.main_node)
