extends Control


enum TutorialStage {MISSION, TRAVELING, BURSTING, SKILLING, STACKING, WINLOSE}
var current_tutorial_stage

var stage_height_traveling: int = 232
var stage_height_bursting: int = 392
var stage_height_skilling: int = 392
var stage_height_stacking: int = 336
var stage_height_winlose: int = 336

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]

onready var animation_player: AnimationPlayer = $AnimationPlayer
# stages
onready var mission_panel: Control = $MissionPanel
onready var hud_guide: Control = $HudGuide
onready var traveling_content: Control = $Checkpoints/TravelingContent
onready var bursting_content: Control = $Checkpoints/BurstingContent
onready var skilling_content: Control = $Checkpoints/SkillingContent
onready var stacking_content: Control = $Checkpoints/StackingContent
onready var winlose_content: Control = $Checkpoints/WinLoseContent
# labels
onready var traveling_label: Label = $Checkpoints/Traveling
onready var bursting_label: Label = $Checkpoints/Bursting
onready var skilling_label: Label = $Checkpoints/Skilling
onready var stacking_label: Label = $Checkpoints/Stacking
onready var winlose_label: Label = $Checkpoints/WinLose


func _input(event: InputEvent) -> void:

	if current_tutorial_stage == TutorialStage.TRAVELING:
		if Input.is_action_pressed("ui_up"):
			traveling_directions.erase(Vector2.UP)
		elif Input.is_action_pressed("ui_down"):
			traveling_directions.erase(Vector2.DOWN)
		elif Input.is_action_pressed("ui_left"):
			traveling_directions.erase(Vector2.LEFT)
		elif Input.is_action_pressed("ui_right"):
			traveling_directions.erase(Vector2.RIGHT)
		
		if traveling_directions.empty():
			finish_traveling()	

	
#func _process(delta: float) -> void:
#	pass
	
	
func _ready() -> void:
	
	Global.tutorial_gui = self # za statse iz GMja
	
	mission_panel.visible = true
	hud_guide.visible = true
	hud_guide.modulate.a = 0
		
	traveling_content.visible = true
	traveling_content.rect_min_size.y = 0
	
	bursting_content.visible = true
	bursting_content.rect_min_size.y = 0
	
	skilling_content.visible = true
	skilling_content.rect_min_size.y = 0
	
	stacking_content.visible = true
	stacking_content.rect_min_size.y = 0
	
	winlose_content.visible = true
	winlose_content.rect_min_size.y = 0


func start(): # kliče se z GM
	
	current_tutorial_stage = TutorialStage.MISSION
	Global.game_manager.player_pixel.set_physics_process(false)
	animation_player.play("mission_in")


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_height: int):
	
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	
	var close_stage = get_tree().create_tween()
	close_stage.tween_callback(self, "set_stage", [next_stage])
	close_stage.tween_property(stage_to_hide, "rect_min_size:y", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	close_stage.parallel().tween_callback(self, "open_stage", [next_stage, next_stage_height])
	

func open_stage(stage_to_show, stage_height):
	
	var open_stage = get_tree().create_tween()
	open_stage.tween_callback(self, "set_stage", [stage_to_show])
	open_stage.tween_property(stage_to_show, "rect_min_size:y", stage_height, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	open_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5)

			
func set_stage(active_stage_node):
	
	match active_stage_node:
		traveling_content:
			current_tutorial_stage = TutorialStage.TRAVELING
			traveling_label.modulate = Global.color_white
		bursting_content:
			current_tutorial_stage = TutorialStage.BURSTING
			bursting_label.modulate = Global.color_white
		skilling_content:
			current_tutorial_stage = TutorialStage.SKILLING
			skilling_label.modulate = Global.color_white
		stacking_content:
			current_tutorial_stage = TutorialStage.STACKING
			stacking_label.modulate = Global.color_white
		winlose_content:
			current_tutorial_stage = TutorialStage.WINLOSE
			winlose_label.modulate = Global.color_white


# STAGES ------------------------------------------------------------------------------------------------------------------	


func finish_traveling():
	
	traveling_label.modulate = Global.color_green
	if not current_tutorial_stage == TutorialStage.TRAVELING:
		return	
	change_stage(traveling_content, bursting_content, stage_height_bursting)
	
	yield(get_tree().create_timer(5), "timeout")		
	Global.game_manager.stray_pixels_count = 5
	Global.game_manager.generate_strays()	

	
func finish_bursting():

	bursting_label.modulate = Global.color_green
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
	change_stage(bursting_content, skilling_content, stage_height_skilling)		


func finish_skilling():
	skilling_label.modulate = Global.color_green
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	change_stage(skilling_content, stacking_content, stage_height_stacking)		

	
func finish_stacking():
	
	stacking_label.modulate = Global.color_green
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	change_stage(stacking_content, winlose_content, stage_height_winlose)		


func push_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("push")
	if all_skills.empty():
		finish_skilling()

	
func pull_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("pull")
	if all_skills.empty():
		finish_skilling()

	
func teleport_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("teleport")
	if all_skills.empty():
		finish_skilling()


func finish_tutorial():
	if not current_tutorial_stage == TutorialStage.WINLOSE:
		return
	stacking_label.modulate = Global.color_green	


# SIGNALS ------------------------------------------------------------------------------------------------------------------	

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"mission_in":
			current_tutorial_stage = TutorialStage.MISSION
			$MissionPanel/Menu/StartBtn.grab_focus()
		"tutorial_start":
			open_stage(traveling_content, stage_height_traveling)
			Global.game_manager.player_pixel.set_physics_process(true)
			

func _on_StartBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_confirm")
	animation_player.play("tutorial_start")
	$MissionPanel/Menu/StartBtn.disabled = true


func _on_QuitBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.main_node.game_out()
	$MissionPanel/Menu/QuitBtn.disabled = true # da ne moreš multiklikatpass # Replace with function body.
