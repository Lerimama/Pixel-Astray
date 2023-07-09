extends Node2D


# grupe zvokov	
onready var game: Node2D = $Game
onready var gui: Node2D = $Gui
onready var stepping: Node2D = $Game/Stepping
onready var blinking: Node2D = $Game/Blinking
onready var blinking_static: Node2D = $Game/BlinkingStatic
onready var burst: Node2D = $Game/Burst
onready var music: Node2D = $Music


func _ready() -> void:
	Global.sound_manager = self
	randomize()

var music_index: int = 0 
func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("m"):
		music.get_child(music_index).stop() 
		music_index += 1
		if music_index >= music.get_child_count():
			music_index = 0
		music.get_child(music_index).play() 
		print(music_index)
	
	
var skill_success_count: int = 0

func play_sfx(event: String):
	
	# če zvoka ni tukaj, pomeni da ga kličem direktno
	match event:
		
		"stepping":
			select_random_sound(stepping).play()
		"blinking":
			select_random_sound(blinking_static).play()
			select_random_sound(blinking).play()
		"last_breath":
			pass
				
		# burst
		"hit_stray":
			$Game/HitStray.play()
		"hit_wall":
			$Game/HitWall.play()
			$Game/HitDizzy.play()
		"burst":
			$Game/Burst/Burst.play()
		"burst_limit":
#			$Game/Burst/BurstLimit.play()
			pass
		"burst_cocking":
			if $Game/Burst/BurstCocking.is_playing():
				return
			$Game/Burst/BurstCocking.play()	
		"burst_cocked":
			pass	
							
		# skills
		"pull":
			$Game/Skills/Pull.play()
		"pulled":
			$Game/Skills/Pulled.play()
			$Game/Skills/PullStoneSlide.play()
		"push":
			$Game/Skills/Pull.play()
		"pushed":
			$Game/Skills/Pulled.play()
			$Game/Skills/PushStoneSlide.play()
		"teleport":
			$Game/Skills/TeleportIn.play()
		"skilled":
			$Game/Skills/Skilled.play()
		"skill_fail":
			$Game/Skills/SkillFail.play()
		"skill_success":
#			skill_success_count += 1
#			if skill_success_count < Profiles.game_rules["skills_in_row_limit"]:
#				$Game/Skills/SkillSuccessA.play()
#			else:
#				$Game/Skills/SkillSuccessB.play()
#				skill_success_count = 0
			pass
			
		# jingles
		"win_jingle":
			$Game/Jingles/WinJingle.play()
		"loose_jingle":
			$Game/Jingles/LooseJingle.play()
			
		# gui
		"loose_life": # ni ok ... preveč je soundov
#			$Gui/LooseLife.play()
			pass
		"btn_confirm":
			$Gui/BtnConfirm.play()
		"btn_cancel":
			$Gui/BtnCancel.play()
		"btn_focus_change":
#			$Gui/BtnFocus.play()
			pass
		"countdown_a":
			$Gui/CoundownA.play()
		"countdown_b":
			$Gui/CoundownB.play()
		"fade_in_out":
			$Gui/FadeInOut.play()
			
		# muska
		"menu_music":
			$Gui/MenuMusic.play()
		
		"game_music":
			$Music/GameMusic1.play()
			
func stop_sfx(sfx_to_stop: String):
	
	match sfx_to_stop:
			"teleport":
				$Game/Skills/TeleportLoop.stop()
				$Game/Skills/TeleportOut.play()
			"skilled":
				$Game/Skills/Skilled.stop()
			"burst_cocking":
				$Game/Burst/BurstCocking.stop()
			"menu_music":
				$Gui/MenuMusic.stop()
			"game_music":
				$Music/GameMusic1.stop()
	


func select_random_sound(sound_group):
	
	var random_index = randi() % sound_group.get_child_count()
	var selected_sound = sound_group.get_child(random_index)
	return selected_sound
	
	
func _on_TeleportStart_finished() -> void:
	$Game/Skills/TeleportLoop.play()
	
	
# random gumbi -------------------------------------------------------------------------------------


var game_click_count = 0
var gui_click_count = 0

onready var all_game_sounds: Array = game.get_children()
onready var all_gui_sounds: Array = gui.get_children()


func na_gumbe(sfx_name =  null):
	
	var all_sounds = all_gui_sounds
	var sound_to_play = all_sounds[sfx_name]
	sound_to_play.play()

	if sfx_name:
		get_node(sfx_name).play()
	else:
		var c = randi() % get_child_count()
		get_child(c).play() 


func _on_GameSfxBtn_button_up() -> void:
	
	all_game_sounds[game_click_count].play()
	
	printt ("game_click_count", game_click_count, game.get_child_count())
	game_click_count += 1 
	if game_click_count == game.get_child_count():
		game_click_count = 0	
	

func _on_GuiSfxBtn_button_up() -> void:
	
	all_gui_sounds[gui_click_count].play()
	printt ("gui_click_count", gui_click_count, gui.get_child_count())
	gui_click_count += 1 
	if gui_click_count == gui.get_child_count():
		gui_click_count = 0	


func _on_ResetCountBtn_pressed() -> void:
	game_click_count = 0
	gui_click_count = 0

