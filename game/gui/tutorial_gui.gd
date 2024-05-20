extends Control


enum TutorialStage {MISSION, TRAVEL, COLLECT, MULTICOLLECT, SKILLS, WINLOSE}
var current_tutorial_stage: int

var tutorial_finished: bool = false

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var wall_stray: KinematicBody2D # zabeležim ga na začetku skill faze in potem preverjam njegov obstoj, da vidim, če je skills izpolnjen 

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var hud_guide: Control = $HudGuide
onready var mission_panel: Control = $MissionPanel
onready var controls: Control = $Controls
onready var checkpoints: Control = $Checkpoints
onready var travel_content: Control = $Checkpoints/TravelingContent
onready var collect_content: Control = $Checkpoints/BurstingContent
onready var multicollect_content: Control = $Checkpoints/StackingContent
onready var skills_content: Control = $Checkpoints/SkillingContent
onready var winlose_content: Control = $Checkpoints/WinLoseContent


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("l"):
		printt ("current_stage", TutorialStage.keys()[current_tutorial_stage])
	
	if current_tutorial_stage == TutorialStage.MISSION: # namesto menija
		if Input.is_action_just_pressed("ui_accept"):
			Global.sound_manager.play_gui_sfx("btn_confirm")
			animation_player.play("tutorial_start")
			
			current_tutorial_stage = 0 # anti dablklik
			Global.sound_manager.play_music("game_music")
			Global.sound_manager.skip_track() # skipa prvi komad in zapleja drugega
#			yield(get_tree().create_timer(1), "timeout")
#			start_travel()
#			print("in")
			
	elif current_tutorial_stage == TutorialStage.TRAVEL:
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
	
	Global.tutorial_gui = self # za statse iz GMja
	visible = false
	
	mission_panel.visible = true
	hud_guide.visible = true
	hud_guide.modulate.a = 0
		
	travel_content.visible = false
	collect_content.visible = false
	multicollect_content.visible = false
	skills_content.visible = false
	winlose_content.visible = false


func _process(delta: float) -> void:
	
	# preverjam prisotnost belega
	wall_stray = null
	if current_tutorial_stage == TutorialStage.SKILLS:
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.WALL:
				wall_stray = stray
		if not wall_stray:
			yield(get_tree().create_timer(1.5), "timeout") # zamik, da lahko uredi še stvari za skills fazo
			finish_skills()


func open_tutorial(): # kliče se z GM
	
	visible = true
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	animation_player.play("mission_in")
	

func start_travel():
	
	# spawn wall
	var show_player = get_tree().create_tween()
	for player in Global.game_manager.current_players_in_game:
		show_player.tween_property(player, "modulate", Color.white, 0.5)
	
	# na začetku spawnam enega belega
	Global.game_manager.set_strays()
	
	var signaling_player: KinematicBody2D
	for player in Global.game_manager.current_players_in_game:
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	current_tutorial_stage = TutorialStage.TRAVEL
	
	Global.hud.game_timer.start_timer()
	Global.game_manager.game_on = true
	
	for player in Global.game_manager.current_players_in_game:
		Global.game_camera.camera_target = player
		
	open_stage(travel_content)

	var show_controls = get_tree().create_tween()
	show_controls.tween_callback(controls, "show")
	show_controls.tween_property(controls, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)	
	get_tree().call_group(Global.group_players, "set_physics_process", true)
	

# STAGES ------------------------------------------------------------------------------------------------------------------	


func finish_travel(): 
	# kliče _input()
	# ko uporabi vse 4 smeri premikanja
	# naslednji spawn je ena barva (na obvezno celico)
	
	if not current_tutorial_stage == TutorialStage.TRAVEL:
		return	
	Global.game_manager.upgrade_level("cleaned")
	# setam naslednjo fazo
	Global.game_manager.start_strays_spawn_count = 1
	Global.game_manager.prev_stage_stray_count = 1
	change_stage(travel_content, collect_content, TutorialStage.COLLECT)
	
		
func finish_collect(): 
	# kliče GM upgrade_level()
	# ko pobere edino barvo, 
	# 1 white ostaja
	# naslednji spawn je stack barv (na obvezne celice)
	
	if not current_tutorial_stage == TutorialStage.COLLECT:
		return
	# setam naslednjo fazo
	Global.game_manager.prev_stage_stray_count = 1 # če ostane beli se šteje za spucano
	Global.game_manager.start_strays_spawn_count = Global.game_manager.required_spawn_positions.size()
	change_stage(collect_content, multicollect_content, TutorialStage.MULTICOLLECT)	
	
	
func finish_multicollect(): # tole je zdaj "stacked colors"
	# kliče GM upgrade_level()
	# ko pobere cel stack barv
	# 1 white staja
	# naslednji spawn je obroč barv okrog belega (na random celice)
	
	if not current_tutorial_stage == TutorialStage.MULTICOLLECT:
		return
	# setam naslednjo fazo
	Global.game_manager.prev_stage_stray_count = 1 # če ostane beli se šteje za spucano
	Global.game_manager.start_strays_spawn_count = Global.game_manager.random_spawn_positions.size()
	change_stage(multicollect_content, skills_content, TutorialStage.SKILLS)		
	
	
func finish_skills():
	# ko spuca belega (preverja FP
	# ni več spawna
	# če spuca vse razen belega, reagira v kodi ki zaznava "cleaned"
	
	if not current_tutorial_stage == TutorialStage.SKILLS:
		return
	# setam naslednjo fazo
	Global.game_manager.prev_stage_stray_count = 0
	change_stage(skills_content, winlose_content, TutorialStage.WINLOSE)		

	
func finish_tutorial():
	
	if not current_tutorial_stage == TutorialStage.WINLOSE:
		return
	Global.sound_manager.play_sfx("tutorial_stage_done")
	
	var fadeout_delay: float = 3  # čaka končanje GO animacijo plejerja
	var close_final_stage = get_tree().create_tween()
	close_final_stage.tween_callback(Global.game_manager, "game_over", [Global.game_manager.GameoverReason.CLEANED])
	close_final_stage.tween_property(checkpoints, "modulate:a", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(fadeout_delay)
	close_final_stage.parallel().tween_property(controls, "modulate:a", 0, 1).set_ease(Tween.EASE_IN).set_delay(fadeout_delay)	


# UTILITI ------------------------------------------------------------------------------------------------------------------	


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_enum: int):
	
	Global.sound_manager.play_sfx("tutorial_stage_done")
	current_tutorial_stage = next_stage_enum
	
	var close_stage = get_tree().create_tween()
	close_stage.tween_property(stage_to_hide, "modulate:a", 0, 0.5)#.set_delay(2)
	close_stage.tween_callback(stage_to_hide, "hide")
	close_stage.tween_callback(self, "open_stage", [next_stage])
	
	

func open_stage(stage_to_show: Control):
	
	var open_stage = get_tree().create_tween()
	open_stage.tween_callback(stage_to_show, "show")
	open_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)

		
# SIGNALS ------------------------------------------------------------------------------------------------------------------	

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"mission_in":
			current_tutorial_stage = TutorialStage.MISSION
		"tutorial_start":
			start_travel()

			
