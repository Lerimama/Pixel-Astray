extends Control


enum TutorialStage {IDLE, TRAVEL, COLLECT, MULTICOLLECT, SKILLS, WINLOSE}
var current_tutorial_stage: int = TutorialStage.IDLE

var tutorial_on: bool = false

# za beleženje stage rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var skill_types: Array = ["push", "pull", "teleport"]
var winlose_stage_time: float = 14
var winlose_burst_count: int = 0 # raste z vsak on_hit_stray
var winlose_burst_count_limit: int = 3

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var winlose_content: Control = $Checkpoints/WinLoseContent
onready var controls: Control = $Checkpoints/Controls
onready var checkpoints: Control = $Checkpoints
onready var travel_content: Control = $Checkpoints/TravelingContent
onready var collect_content: Control = $Checkpoints/BurstingContent
onready var multicollect_content: Control = $Checkpoints/StackingContent
onready var skills_content: Control = $Checkpoints/SkillingContent
onready var viewport_container: ViewportContainer = $"../../GameView/ViewportContainer"
onready var finish_hint: HBoxContainer = $ActionHint


func _input(event: InputEvent) -> void:
	
	if current_tutorial_stage == TutorialStage.TRAVEL:
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
			
	
func _ready() -> void:
	
	Global.tutorial_gui = self # za skillse iz plejerja
	
	if Global.game_manager.game_data["game"] == Profiles.Games.CLASSIC:
		if Profiles.default_game_settings["tutorial_mode"]:
			tutorial_on = true
	
	visible = false
	
	# skrijem elemente
	travel_content.visible = false
	collect_content.visible = false
	multicollect_content.visible = false
	skills_content.visible = false
	winlose_content.visible = false
	finish_hint.visible = false
	controls.visible = false
		
	# setam točke kjer tekst govori o točkah
	var color_collected_points: int = Profiles.default_game_settings["color_picked_points"]
	var white_eliminated_points: int = Profiles.default_game_settings["white_eliminated_points"]
	var collecting_points_line: RichTextLabel = $"%PointsLabel"
	collecting_points_line.bbcode_text = "You get " + str(color_collected_points) + " points per color collected and " + str(white_eliminated_points) + " per white eliminated."
	var cleaned_points: int = Profiles.default_game_settings["cleaned_reward_points"]
	var cleaning_points_line: RichTextLabel = $"%PointsCleanedLabel"
	cleaning_points_line.bbcode_text = "You get rewarded %s bonus points if you manage to clean the screen." % cleaned_points


func open_tutorial(): # kliče se z GM
	
	show()
	travel_content.show()
	controls.show()
	animation_player.play("tutorial_start_with_sidebar")


func finish_travel(): 
	
	if not current_tutorial_stage == TutorialStage.TRAVEL:
		return	
	# change_stage(travel_content, winlose_content, TutorialStage.WINLOSE) # debug
	change_stage(travel_content, collect_content, TutorialStage.COLLECT)
	
		
func finish_collect(): 
	
	if not current_tutorial_stage == TutorialStage.COLLECT:
		return
	change_stage(collect_content, skills_content, TutorialStage.SKILLS)	
	

func finish_skills():
	
	if not current_tutorial_stage == TutorialStage.SKILLS:
		return
	
	# setam naslednjo fazo
	change_stage(skills_content, multicollect_content, TutorialStage.MULTICOLLECT)		
	

func finish_multicollect(): # tole je zdaj "stacked colors"
	
	if not current_tutorial_stage == TutorialStage.MULTICOLLECT:
		return
	change_stage(multicollect_content, winlose_content, TutorialStage.WINLOSE)		
	
	# tutorial se ugasne, ko spucaš določeno število straysov
	# yield(get_tree().create_timer(winlose_stage_time), "timeout") # pavza za branje
	
	
func close_tutorial():
	
	if not tutorial_on:
		return
	tutorial_on = false
	current_tutorial_stage = TutorialStage.IDLE # disejblan gui

	# animiram hint
	var hint_fade = get_tree().create_tween()
	hint_fade.tween_property(finish_hint, "modulate:a",0, 0.5).from(0.0).set_ease(Tween.EASE_IN)
	hint_fade.tween_callback(finish_hint, "hide")	
	
	animation_player.play("tutorial_end_with_sidebar")
		
	# če se igra nadaljuje
	if Global.game_manager.game_on:
		Global.sound_manager.stop_music("game_music_on_gameover")
		yield(get_tree().create_timer(1), "timeout")
		Global.sound_manager.current_music_track_index = Global.game_manager.game_settings["game_music_track_index"]
		Global.sound_manager.play_music("game_music")
		
	
# UTILITI ------------------------------------------------------------------------------------------------------------------	


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_enum: int):
	
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
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

	if not current_tutorial_stage == TutorialStage.SKILLS: # ker plejer kliče dokler traja tutorial
		return
	
	match skill_number:
		1:
			skill_types.erase("push")
		2:
			skill_types.erase("pull")
		3:
			skill_types.erase("teleport")
				
	if skill_types.empty():
		finish_skills()
		

func on_hit_stray(colors_collected_count: int):

	if current_tutorial_stage == TutorialStage.COLLECT: 
		yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
		finish_collect()
	elif current_tutorial_stage == TutorialStage.MULTICOLLECT and colors_collected_count > 1:
		yield(get_tree().create_timer(Profiles.get_it_time), "timeout")
		finish_multicollect()
	elif current_tutorial_stage == TutorialStage.WINLOSE:
		winlose_burst_count += 1
		if winlose_burst_count > winlose_burst_count_limit:
			close_tutorial()
			
		
# SIGNALS ------------------------------------------------------------------------------------------------------------------	

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"tutorial_start_with_sidebar":
			
			current_tutorial_stage = TutorialStage.TRAVEL
			
			finish_hint.show()
			var hint_fade = get_tree().create_tween()
			hint_fade.tween_property(finish_hint, "modulate:a",1, 0.7).from(0.0).set_ease(Tween.EASE_IN)
			
			
		"tutorial_end_with_sidebar":
			hide()

			
