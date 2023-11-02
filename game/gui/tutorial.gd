extends Control


enum TutorialStage {MISSION, BASICS, TRAVELING, BURSTING, SKILLING, STACKING, TUTORIAL_END}
var current_tutorial_stage

var next_stage
var prev_stage

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]

onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var mission: Control = $MissionPanel
onready var hud_explain: Control = $HudExplain

# stages
onready var basics: VBoxContainer = $TutorialPanel/Basics
onready var traveling: VBoxContainer = $TutorialPanel/Traveling
onready var bursting: VBoxContainer = $TutorialPanel/Bursting
onready var skilling: VBoxContainer = $TutorialPanel/Skilling
onready var stacking: VBoxContainer = $TutorialPanel/Stacking
onready var tutorial_end: VBoxContainer = $TutorialPanel/EndTutorial

# done popup
onready var stage_done_popup: Control = $TutorialPanel/StageDone
onready var stage_done_label: Label = $TutorialPanel/StageDone/Content/LabelStageDone
onready var next_stage_label: Label = $TutorialPanel/StageDone/Content/LabelNextStage
onready var continue_btn: Button = $TutorialPanel/StageDone/ContinueBtn

# btnz
onready var basics_btn: Button = $Checkpoints/Basics
onready var traveling_btn: Button = $Checkpoints/Traveling
onready var bursting_btn: Button = $Checkpoints/Bursting
onready var skilling_btn: Button = $Checkpoints/Skilling
onready var stacking_btn: Button = $Checkpoints/Stacking
#onready var traveling_btn: Button = $TutorialPanel/Checkpoints/Traveling
#onready var bursting_btn: Button = $TutorialPanel/Checkpoints/Bursting
#onready var skilling_btn: Button = $TutorialPanel/Checkpoints/Skilling
#onready var stacking_btn: Button = $TutorialPanel/Checkpoints/Stacking
#onready var icon_done = preload("res://assets/resources/icon_done.tres")
#onready var icon_not_done = preload("res://assets/resources/icon_not_done.tres")


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

	
func _process(delta: float) -> void:
	pass
	
	
func _ready() -> void:
	
	Global.tutorial_gui = self
	
	# visibile
	mission.visible = true
	basics.visible = true
	
	# invisibile
	traveling.visible = false
	hud_explain.visible = false
	stage_done_popup.visible = false
	bursting.visible = false
	skilling.visible = false
	stacking.visible = false
	tutorial_end.visible = false


func start(): # kliče se z GM
	
	current_tutorial_stage = TutorialStage.MISSION
	visible = true
	hud_explain.visible = true
	hud_explain.modulate.a = 0
	Global.game_manager.player_pixel.set_physics_process(false)
#	animation_player.play("goals_in_with_labels")
	animation_player.play("goals_in")
	

func change_stage(stage_to_hide: Control, stage_to_show: Control):
	
	stage_to_show.visible = true
	stage_to_show.modulate.a = 0
	
	stage_done_popup.visible = true
	stage_done_popup.modulate.a = 0
	
	apply_popup_text(stage_to_hide)
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	
	var change_stages = get_tree().create_tween()
	# current stage
	change_stages.tween_callback(self, "set_stage", [stage_to_show])
	change_stages.tween_property(stage_to_hide, "modulate:a", 0, 0.5)
	change_stages.tween_property(stage_to_hide, "visible", false, 0)
	# done popup
	# change_stages.tween_callback(Global.game_manager.player_pixel, "set_physics_process", [false])
	change_stages.tween_property(stage_done_popup, "modulate:a", 1, 0.5)
	change_stages.tween_callback(continue_btn, "grab_focus")
	
	yield(continue_btn, "pressed")
	
	var next_stage = get_tree().create_tween()
	next_stage.tween_property(stage_done_popup, "modulate:a", 0, 0.5)
	next_stage.tween_property(stage_done_popup, "visible", false, 0)
	next_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5).set_delay(0.5)
	# next_stage.tween_callback(Global.game_manager.player_pixel, "set_physics_process", [true])

		
func apply_popup_text(stage_done):
	
	match stage_done:
		basics:
			stage_done_label.text %= "bbb"
			next_stage_label.text %= "bbb"			
		traveling:
			stage_done_label.text %= "travellll around"
			next_stage_label.text %= "destroy pixels and collect their colors"
		bursting:
			stage_done_label.text = "collect colors"
			next_stage_label.text = "use skills to move stray pixels"
		skilling:
			stage_done_label.text = "move pixels nad teleport through walls"
			next_stage_label.text = "use skill to your advantage"			
		stacking:
			stage_done_label.text = "stacking"
			next_stage_label.text = "maneweeee"
			
			
func set_stage(active_stage_node):
	
	match active_stage_node:
		basics:
			current_tutorial_stage = TutorialStage.BASICS
			basics_btn.modulate = Global.color_white
		traveling:
			current_tutorial_stage = TutorialStage.TRAVELING
			traveling_btn.modulate = Global.color_white
#			Global.game_manager.player_pixel.pixel_color = Global.color_white
		bursting:
			current_tutorial_stage = TutorialStage.BURSTING
			bursting_btn.modulate = Global.color_white
		skilling:
			current_tutorial_stage = TutorialStage.SKILLING
			skilling_btn.modulate = Global.color_white
		stacking:
			current_tutorial_stage = TutorialStage.STACKING
			stacking_btn.modulate = Global.color_white


# STAGES -----------------------------------------------------------------------


func finish_basics():
	basics_btn.modulate = Global.color_green
#	traveling_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.BASICS:
		return	
	change_stage(basics, traveling)
	

func finish_traveling():
	traveling_btn.modulate = Global.color_green
#	traveling_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.TRAVELING:
		return	
	change_stage(traveling, bursting)		
	
	
func finish_bursting():

	bursting_btn.modulate = Global.color_green
#	bursting_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
		
		
	change_stage(bursting, skilling)		


func finish_skilling():
	skilling_btn.modulate = Global.color_green
#	skilling_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	change_stage(skilling, stacking)		

	
func finish_stacking():
	stacking_btn.modulate = Global.color_green
#	stacking_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	change_stage(stacking, tutorial_end)		


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
	if not current_tutorial_stage == TutorialStage.TUTORIAL_END:
		return
#	stacking_btn.icon = icon_done
	stacking_btn.modulate = Global.color_green	
	
	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
#		"goals_in_with_labels":
		"goals_in":
			current_tutorial_stage = TutorialStage.MISSION
			$MissionPanel/Menu/StartBtn.grab_focus()
		"tutorial_start":
#		"tutorial_start_with_labels":
			set_stage(basics)
			Global.game_manager.player_pixel.set_physics_process(true)
			

func _on_StartBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_confirm")
#	animation_player.play("tutorial_start_with_labels")
	animation_player.play("tutorial_start")
#	animation_player.play("tutorial_start_new")
	$MissionPanel/Menu/StartBtn.disabled = true
#	$TutorialPanel/Checkpoints/Bursting.grab_focus()


func _on_ContinueBtn_pressed() -> void:
	
	if current_tutorial_stage == TutorialStage.BURSTING:
		
		Global.game_manager.stray_pixels_count = 5
		Global.game_manager.generate_strays()


func _on_QuitBtn_pressed() -> void:
	Global.sound_manager.play_gui_sfx("btn_cancel")
	Global.main_node.game_out()
	
	$MissionPanel/Menu/QuitBtn.disabled = true # da ne moreš multiklikatpass # Replace with function body.
