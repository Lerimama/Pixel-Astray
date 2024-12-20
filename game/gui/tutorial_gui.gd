extends Control


enum TUTORIAL_STAGE {IDLE, TRAVEL, COLLECT, MULTICOLLECT, SKILLS, FIN}
var current_tutorial_stage: int = TUTORIAL_STAGE.IDLE

var tutorial_on: bool = false

# za beleženje stage rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var skill_types: Array = ["push", "pull", "teleport"]
var fin_stage_time: float = 5

onready var checkpoints: Control = $Checkpoints
onready var travel_content: Control = $Checkpoints/TravelingContent
onready var collect_content: Control = $Checkpoints/BurstingContent
onready var skills_content: Control = $Checkpoints/SkillingContent
onready var fin_content: Control = $Checkpoints/FinContent
onready var hud_guide: Control = $HudGuide
onready var action_hint_press: Node2D = $ActionHintPress


func _unhandled_input(event: InputEvent) -> void:
#func _input(event: InputEvent) -> void:

	if current_tutorial_stage == TUTORIAL_STAGE.TRAVEL:
		if Input.is_action_pressed("ui_up"):
			traveling_directions.erase(Vector2.UP)
		elif Input.is_action_pressed("ui_down"):
			traveling_directions.erase(Vector2.DOWN)
		elif Input.is_action_pressed("ui_left"):
			traveling_directions.erase(Vector2.LEFT)
		elif Input.is_action_pressed("ui_right"):
			traveling_directions.erase(Vector2.RIGHT)
		if traveling_directions.empty():
			finish_travel()

	if Input.is_action_just_pressed("next") and action_hint_press.modulate.a == 1:
		_on_HintBtn_pressed()


func _ready() -> void:

	Global.tutorial_gui = self # za skillse iz plejerja

	visible = false

	# skrijem elemente
	travel_content.hide()
	collect_content.hide()
	skills_content.hide()
	fin_content.hide()
	hud_guide.hide()

	action_hint_press.modulate.a = 0
	action_hint_press.hide()


func open_tutorial(): # kliče se z GM

	if not tutorial_on:

		tutorial_on = true

		# skip step hint
		var fade_time: float = 0.3
		var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		fade_in.tween_callback(self, "show")
		fade_in.parallel().tween_callback(action_hint_press, "show")
		fade_in.tween_property(action_hint_press, "modulate:a", 1, fade_time).set_ease(Tween.EASE_IN)

		Global.hud.touch_controls.toggle_tutorial_elements(true)
		open_stage(travel_content)
		current_tutorial_stage = TUTORIAL_STAGE.TRAVEL # more bit


func close_tutorial():

	if tutorial_on:

		tutorial_on = false
		current_tutorial_stage = TUTORIAL_STAGE.IDLE # disejblan gui

		Global.hud.touch_controls.toggle_tutorial_elements(false)

		var fade_time: float = 0.5
		var close_stage = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		for content in checkpoints.get_children():
			if content.visible:
				close_stage.parallel().tween_property(content, "modulate:a", 0, fade_time)
		close_stage.parallel().tween_property(action_hint_press, "modulate:a", 0, fade_time)
		yield(close_stage, "finished")

		hide()

		# če se igra nadaljuje
		if Global.game_manager.game_on:
			var new_track: AudioStreamPlayer = Global.sound_manager.skip_track(0)
			Global.hud.music_player.track_btn.text = new_track.name


#	if not Global.sound_manager.game_music_set_to_off:

#		Analytics.save_ui_click("SkipTrack %d" % (Global.sound_manager.current_music_track_index))



func skip_step():

	match current_tutorial_stage:
		TUTORIAL_STAGE.TRAVEL:
			finish_travel(false)
		TUTORIAL_STAGE.COLLECT:
			finish_collect(false)
		TUTORIAL_STAGE.SKILLS:
			finish_skills(false)
		TUTORIAL_STAGE.FIN:
			close_tutorial()


# STEPS ------------------------------------------------------------------------------------------------------------------


func finish_travel(with_sound: bool = true):

	if current_tutorial_stage == TUTORIAL_STAGE.TRAVEL:
		change_stage(travel_content, collect_content, TUTORIAL_STAGE.COLLECT, with_sound)


func finish_collect(with_sound: bool = true):

	if current_tutorial_stage == TUTORIAL_STAGE.COLLECT:
		change_stage(collect_content, skills_content, TUTORIAL_STAGE.SKILLS, with_sound)


func finish_skills(with_sound: bool = true):

	if current_tutorial_stage == TUTORIAL_STAGE.SKILLS:
		change_stage(skills_content, fin_content, TUTORIAL_STAGE.FIN, with_sound)
		yield(get_tree().create_timer(fin_stage_time), "timeout") # pavza za branje
		close_tutorial()


# UTILITI ------------------------------------------------------------------------------------------------------------------


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_enum: int, with_sound: bool):

	if with_sound:
		Global.sound_manager.play_event_sfx("tutorial_stage_done")
	current_tutorial_stage = next_stage_enum

	var close_stage = get_tree().create_tween()
	close_stage.tween_property(stage_to_hide, "modulate:a", 0, 0.5)#.set_delay(2)
	close_stage.tween_callback(stage_to_hide, "hide")
	close_stage.tween_callback(self, "open_stage", [next_stage])


func open_stage(stage_to_show: Control):

	var open_stage = get_tree().create_tween()
	open_stage.tween_callback(stage_to_show, "show")
	open_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)


func on_skill_used(skill_number: int):

	if current_tutorial_stage == TUTORIAL_STAGE.SKILLS: # ker plejer kliče dokler traja tutorial
		match skill_number:
			1:
				skill_types.erase("push")
				skill_types.erase("teleport")
			2:
				skill_types.erase("pull")
			3:
				skill_types.erase("push")
				skill_types.erase("teleport")
		if skill_types.empty():
			finish_skills()


func on_hit_stray(colors_collected_count: int):

	if current_tutorial_stage == TUTORIAL_STAGE.COLLECT:
		yield(get_tree().create_timer(Global.get_it_time), "timeout")
		finish_collect()
#	elif current_tutorial_stage == TUTORIAL_STAGE.MULTICOLLECT and colors_collected_count > 1:
#		yield(get_tree().create_timer(Global.get_it_time), "timeout")
#		finish_multicollect()


func _on_HintBtn_pressed() -> void:

	skip_step()
