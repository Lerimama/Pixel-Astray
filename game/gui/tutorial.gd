extends Control


enum TutorialStage {NULA, GOALS, TRAVELING, BURSTING, SKILLING, STACKING}
var current_tutorial_stage

var tutorial_open: Node2D # trenutno odprt, ko pregleduješ navodila
var tutorial_active: Node2D # trenutno aktiven je ta, ki je v delu
var tutorials_done: Array
var tutorial_step_todu: Array 

var next_stage
var prev_stage

onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var traveling: VBoxContainer = $TutorialPanel/Traveling
onready var bursting: VBoxContainer = $TutorialPanel/Bursting
onready var skilling: VBoxContainer = $TutorialPanel/Skilling
onready var stacking: VBoxContainer = $TutorialPanel/Stacking
onready var end_tutorial: VBoxContainer = $TutorialPanel/EndTutorial
onready var pause_menu: Control = $"../PauseMenu"

# za belleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]



func _ready() -> void:
	
	Global.tutorial_gui = self
	current_tutorial_stage = TutorialStage.NULA

func _process(delta: float) -> void:
	manage_tutorial_stages()
	printt ("skills", all_skills)
		
	

func start():
	
	current_tutorial_stage = TutorialStage.GOALS
	visible = true
	get_tree().paused = true # goals ne podeduje tega
	animation_player.play("goals_in")


func manage_tutorial_stages():
	
		
#	printt ("tut_stage", TutorialStage.keys()[current_tutorial_stage])
	match current_tutorial_stage:
		TutorialStage.GOALS:
			pass
		TutorialStage.TRAVELING:
#			traveling.visible = true
#			bursting.visible = false
#			skilling.visible = false
#			stacking.visible = false
#			end_tutorial.visible = false
			
			if Input.is_action_pressed("ui_up"):
				traveling_directions.erase(Vector2.UP)
				if traveling_directions.empty():
					change_tutorial_stage(traveling, bursting)		
			elif Input.is_action_pressed("ui_down"):
				traveling_directions.erase(Vector2.DOWN)
				if traveling_directions.empty():
					change_tutorial_stage(traveling, bursting)		
			elif Input.is_action_pressed("ui_left"):
				traveling_directions.erase(Vector2.LEFT)
				if traveling_directions.empty():
					change_tutorial_stage(traveling, bursting)		
			elif Input.is_action_pressed("ui_right"):
				traveling_directions.erase(Vector2.RIGHT)
				if traveling_directions.empty():
					change_tutorial_stage(traveling, bursting)		
#			if traveling_directions.empty():
#				current_tutorial_stage = TutorialStage.BURSTING
				
		TutorialStage.BURSTING:
			pass
#			traveling.visible = false
#			bursting.visible = true
#			skilling.visible = false
#			stacking.visible = false
#			end_tutorial.visible = false	
		TutorialStage.SKILLING:
			pass
		TutorialStage.STACKING:
			pass
	
func set_tutorial_stage(active_stage_node):
	
	printt("set", active_stage_node)
	match active_stage_node:
		bursting:
#			printt("prev stage", current_tutorial_stage)
			current_tutorial_stage = TutorialStage.BURSTING
#			printt("new stage", current_tutorial_stage)
		skilling:
			current_tutorial_stage = TutorialStage.SKILLING
		stacking:
			current_tutorial_stage = TutorialStage.STACKING

func bursting_done():
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
	change_tutorial_stage(bursting, skilling)		


func skilling_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	change_tutorial_stage(skilling, stacking)		
	
	
func stacking_done():
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	change_tutorial_stage(stacking, end_tutorial)		
	
func push_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("push")
	if all_skills.empty():
		skilling_done()
	
func pull_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("pull")
	if all_skills.empty():
		skilling_done()
	
func teleport_done():
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	all_skills.erase("teleport")
	if all_skills.empty():
		skilling_done()
	

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"goals_in":
			current_tutorial_stage = TutorialStage.GOALS
			$Goals/Menu/StartBtn.grab_focus()
		"tutorial_start":
			get_tree().paused = false
			current_tutorial_stage = TutorialStage.TRAVELING
			
#			traveling.visible = true
#			bursting.visible = false
#			skilling.visible = false
#			stacking.visible = false
#			end_tutorial.visible = false		
	
func change_tutorial_stage(stage_to_hide: Control, stage_to_show: Control):
	
	printt("change", stage_to_hide, stage_to_show)
	
	stage_to_show.visible = true
	stage_to_show.modulate.a = 0
	
	var change_stages = get_tree().create_tween() #.set_ease(Tween.EASE_IN_OUT)	
	change_stages.tween_property(stage_to_hide, "modulate:a", 0, 0)
	change_stages.tween_property(stage_to_show, "modulate:a", 1, 1)
	change_stages.parallel().tween_property(stage_to_hide, "visibilty", false, 0)
	change_stages.tween_callback(self, "set_tutorial_stage", [stage_to_show])
	
#	stage_to_show.visible = true
#	stage_to_hide.visible = false
	
#	change_stages.tween_callback(menu_music, "stop")
	# volume nazaj
#	fade_out.tween_property(menu_music, "volume_db", menu_music_volume_on_node, 0.5)	
	
func start_tutorial():
	pass


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


