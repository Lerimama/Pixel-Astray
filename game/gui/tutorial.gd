extends Control


enum TutorialStage {NULA, GOALS, TRAVELING, BURSTING, SKILLING, STACKING, END_TUTORIAL}
var current_tutorial_stage

#var tutorial_open: Node2D # trenutno odprt, ko pregleduješ navodila
#var tutorial_active: Node2D # trenutno aktiven je ta, ki je v delu
#var tutorials_done: Array
#var tutorial_step_todu: Array 

var next_stage
var prev_stage

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]

onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var pause_menu: Control = $"../PauseMenu"

# done popup
var done_popup_time: int = 5
onready var done_popup: Control = $DonePopup
onready var label_stage_done: Label = $DonePopup/LabelStageDone
onready var label_next_stage: Label = $DonePopup/LabelNextStage

# stages
onready var traveling: VBoxContainer = $TutorialPanel/Traveling
onready var bursting: VBoxContainer = $TutorialPanel/Bursting
onready var skilling: VBoxContainer = $TutorialPanel/Skilling
onready var stacking: VBoxContainer = $TutorialPanel/Stacking
onready var end_tutorial: VBoxContainer = $TutorialPanel/EndTutorial

# btnz
onready var traveling_btn: Button = $TutorialPanel/Checkpoints/Traveling
onready var bursting_btn: Button = $TutorialPanel/Checkpoints/Bursting
onready var skilling_btn: Button = $TutorialPanel/Checkpoints/Skilling
onready var stacking_btn: Button = $TutorialPanel/Checkpoints/Stacking

onready var stage_done_popup: Control = $TutorialPanel/StageDone
onready var stage_done_label: Label = $TutorialPanel/StageDone/LabelStageDone
onready var next_stage_label: Label = $TutorialPanel/StageDone/LabelNextStage
onready var continue_btn: Button = $TutorialPanel/StageDone/ContinueBtn


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
	
#	if stage_done_popup.visible:
#		if Input.is_action_just_pressed("ui_accept"):
#			continue_btn.set_pressed(true)

	
func _ready() -> void:
	
	Global.tutorial_gui = self
	current_tutorial_stage = TutorialStage.NULA
	
	# visibility setup
	traveling.visible = true
	bursting.visible = false
	skilling.visible = false
	stacking.visible = false
	end_tutorial.visible = false
	
	done_popup.visible = false
	stage_done_popup.visible = false

func start(): # kliče se z GM
	
	current_tutorial_stage = TutorialStage.GOALS
	visible = true
	get_tree().paused = true # goals ne podeduje tega
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
	change_stages.tween_property(stage_done_popup, "modulate:a", 1, 0.5)
	change_stages.tween_callback(continue_btn, "grab_focus")
	
	yield(continue_btn, "pressed")
	
	var next_stage = get_tree().create_tween()
	next_stage.tween_property(stage_done_popup, "modulate:a", 0, 0.5)
	next_stage.tween_property(stage_done_popup, "visible", false, 0)
	next_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5).set_delay(0.5)

	
func apply_popup_text(stage_done):
	match stage_done:
		traveling:
			label_stage_done.text %= "travel around"
			label_next_stage.text %= "destroy pixels and collect their colors"
			# v2
			stage_done_label.text %= "travellll around"
			next_stage_label.text %= "destroy pixels and collect their colors"
		bursting:
			label_stage_done.text = "collect colors"
			label_next_stage.text = "use skills to move stray pixels"
		skilling:
			label_stage_done.text = "move pixels nad teleport through walls"
			label_next_stage.text = "use skill to your advantage"			
		stacking:
			label_stage_done.text = "stacking"
			label_next_stage.text = "maneweeee"
			
			
func set_stage(active_stage_node):
	
	match active_stage_node:
		traveling:
			current_tutorial_stage = TutorialStage.TRAVELING
		bursting:
			current_tutorial_stage = TutorialStage.BURSTING
		skilling:
			current_tutorial_stage = TutorialStage.SKILLING
		stacking:
			current_tutorial_stage = TutorialStage.STACKING


# TRAVELING -----------------------------------------------------------------------
# BURSTING -----------------------------------------------------------------------
# SKILLING -----------------------------------------------------------------------
# STACKING -----------------------------------------------------------------------
onready var icon_done = preload("res://assets/resources/icon_done.tres")
onready var icon_not_done = preload("res://assets/resources/icon_not_done.tres")


func finish_traveling():
	traveling_btn.modulate = Global.color_green
	traveling_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.TRAVELING:
		return	
	change_stage(traveling, bursting)		
	
func finish_bursting():

	bursting_btn.modulate = Global.color_green
	bursting_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
		
		
	change_stage(bursting, skilling)		


func finish_skilling():
	skilling_btn.modulate = Global.color_green
	skilling_btn.icon = icon_done
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	change_stage(skilling, stacking)		
	
	
func finish_stacking():
	stacking_btn.icon = icon_done
	stacking_btn.modulate = Global.color_green
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	change_stage(stacking, end_tutorial)		


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

func end_tutorial():
	if not current_tutorial_stage == TutorialStage.END_TUTORIAL:
		return
	stacking_btn.icon = icon_done
	stacking_btn.modulate = Global.color_green	
	
	
	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"goals_in":
			current_tutorial_stage = TutorialStage.GOALS
			$Goals/Menu/StartBtn.grab_focus()
		"tutorial_start":
			get_tree().paused = false
			set_stage(traveling)
		"done_popup_in":
			Global.game_manager.player_pixel.set_physics_process(false)
		"done_popup_out":
			Global.game_manager.player_pixel.set_physics_process(true)
			done_popup.visible = false
			
	

func _on_StartBtn_pressed() -> void:
	animation_player.play("tutorial_start")
	$TutorialPanel/Checkpoints/Bursting.grab_focus()

func _on_Traveling_pressed() -> void:

	traveling.visible = true
	bursting.visible = false
	skilling.visible = false
	stacking.visible = false
	end_tutorial.visible = false

func _on_Bursting_pressed() -> void:
	traveling.visible = false
	bursting.visible = true
	skilling.visible = false
	stacking.visible = false
	end_tutorial.visible = false

func _on_Skilling_pressed() -> void:
	traveling.visible = false
	bursting.visible = false
	skilling.visible = true
	stacking.visible = false
	end_tutorial.visible = false

func _on_Stacking_pressed() -> void:
	traveling.visible = false
	bursting.visible = false
	skilling.visible = false
	stacking.visible = true
	end_tutorial.visible = false


# --------------------------------------------------------------------------------------------------


#func change_stage(stage_to_hide: Control, stage_to_show: Control):
	
#	# v1
#	stage_to_show.visible = true
#	stage_to_show.modulate.a = 0
#	# done popup
#	done_popup.visible = true
#	done_popup.modulate.a = 0
#	apply_popup_text(stage_to_hide)
#	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
#	animation_player.play("done_popup_in")
#
#	# change stage
#	var change_stages = get_tree().create_tween()
#	change_stages.tween_callback(self, "set_stage", [stage_to_show])
#	change_stages.tween_property(stage_to_hide, "modulate:a", 0, 0.5)
#	change_stages.tween_property(stage_to_hide, "visible", false, 0)
#	change_stages.tween_property(stage_to_show, "modulate:a", 1, 1).set_delay(0.5)
#	change_stages.tween_callback(animation_player, "play", ["done_popup_out"]).set_delay(2)



#func _process(delta: float) -> void:
#	manage_tutorial_stages()
#
#func manage_tutorial_stages():
#
##	printt ("tut_stage", TutorialStage.keys()[current_tutorial_stage])
#	match current_tutorial_stage:
#		TutorialStage.GOALS:
#			pass
#		TutorialStage.TRAVELING:
#
##			if Input.is_action_pressed("ui_up"):
##				traveling_directions.erase(Vector2.UP)
##				if traveling_directions.empty():
##					change_tutorial_stage(traveling, bursting)		
##			elif Input.is_action_pressed("ui_down"):
##				traveling_directions.erase(Vector2.DOWN)
##				if traveling_directions.empty():
##					change_tutorial_stage(traveling, bursting)		
##			elif Input.is_action_pressed("ui_left"):
##				traveling_directions.erase(Vector2.LEFT)
##				if traveling_directions.empty():
##					change_tutorial_stage(traveling, bursting)		
##			elif Input.is_action_pressed("ui_right"):
##				traveling_directions.erase(Vector2.RIGHT)
##				if traveling_directions.empty():
##					change_tutorial_stage(traveling, bursting)		
##			if traveling_directions.empty():
##				current_tutorial_stage = TutorialStage.BURSTING
#			pass	
#		TutorialStage.BURSTING:
#			pass
#		TutorialStage.SKILLING:
#			pass
#		TutorialStage.STACKING:
#			pass	


func _on_ContinueBtn_pressed() -> void:
	pass # Replace with function body.
