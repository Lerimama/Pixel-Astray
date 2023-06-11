extends Control


var pause_fade_time: float = 0.5
var pause_on: bool = false
var new_tween: SceneTreeTween

var home_scene_path: String = "res://scenes/Home.tscn"
var game_scene_path: String = "res://scenes/game/Game.tscn"

onready var score: Label = $Score


#func _input(event: InputEvent) -> void:
#
#	if event is InputEventKey:
#		if event.pressed and event.scancode == KEY_ESCAPE:
#			if not pause_on:
#				pause()
#			else:
#				unpause()
#			accept_event()


func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	modulate.a = 0

	
func fade_in(player_score):
	
#	pause_tree()
	visible = true
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "modulate:a", 1, pause_fade_time)
	new_tween.tween_callback(self, "pause_tree")
	
	score.text = "Dosegel si %s tock." % player_score


func pause_tree():
	
	pause_on = true
	get_tree().paused = true
	set_process_input(true) # zato da se lahko animacija izvede
	

func fade_out():
	
	Global.game_manager.start_game()
	new_tween = get_tree().create_tween()
	new_tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	new_tween.tween_property(self, "modulate:a", 0, pause_fade_time)
	new_tween.tween_callback(self, "unpause_tree")
	
	
func unpause_tree():
	
	get_tree().paused = false
	pause_on = false
	visible = false
	set_process_input(true) # zato da se lahko animacija izvede


func _on_RestartBtn_pressed() -> void:
	
#	fade_out()
	unpause_tree()
	Global.reload_scene(Global.current_scene, game_scene_path, Global.main_root)
	

func _on_QuitBtn_pressed() -> void:
	
	unpause_tree()
	Global.release_scene(Global.current_scene)
	Global.spawn_new_scene(home_scene_path, Global.main_root)
	
