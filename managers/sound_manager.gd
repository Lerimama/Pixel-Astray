extends Node2D


var skill_success_count: int = 0


# grupe zvokov	
onready var stepping: Node2D = $GameSfx/Stepping
onready var blinking: Node2D = $GameSfx/Blinking
onready var blinking_static: Node2D = $GameSfx/BlinkingStatic
onready var burst: Node2D = $GameSfx/Burst
onready var music: Node2D = $Music


func _ready() -> void:
	Global.sound_manager = self
	randomize()
	

func play_stepping_sfx(current_player_energy_part: float):
	
		# NEW
#		printt("current_player_energy_part", current_player_energy_part)
		select_random_sfx($GameSfx/Stepping/Tapping2).play()
#		$GameSfx/Stepping/Tapping2.pitch_scale = current_player_energy_part

		select_random_sfx($GameSfx/Stepping/Tapping3).play()
#		$GameSfx/Stepping/Tapping3.pitch_scale = current_player_energy_part

		select_random_sfx($GameSfx/Stepping/TappingWahVar).play()
#		select_random_sfx($GameSfx/Stepping/TappingWah).play()
#		$GameSfx/Stepping/StepSlide.pitch_scale = current_player_energy_part
	
		# OLD
#		select_random_sfx($GameSfx/Stepping/Tapping1).play()
#		$GameSfx/Stepping/StepSlide.play()
	
func play_sfx(effect_for: String):
	
	# če zvoka ni tukaj, pomeni da ga kličem direktno
	match effect_for:
		
		"blinking":
			# nekateri so na mute, ker so drugače prepogosti soundi
			select_random_sfx(blinking_static).play()
			select_random_sfx(blinking).play()
		"last_breath":
			if $GameSfx/LastBeat.is_playing():
				return
			$GameSfx/LastBeat.play()
		
		# bursting
		"hit_stray":
			$GameSfx/Burst/HitStray.play()
		"hit_wall":
			$GameSfx/Burst/HitWall.play()
			$GameSfx/Burst/HitDizzy.play()
		"burst":
			yield(get_tree().create_timer(0.1), "timeout")
			$GameSfx/Burst/Burst.play()
			$GameSfx/Burst/BurstLaser.play()
		"burst_cocking":
			if $GameSfx/Burst/BurstCocking.is_playing():
				return
			$GameSfx/Burst/BurstCocking.play()	
							
		# skills
		"pull":
			$GameSfx/Skills/PushPull.play()
		"pulled":
			$GameSfx/Skills/PushedPulled.play()
			$GameSfx/Skills/PullStoneSlide.play()
		"push":
			$GameSfx/Skills/PushPull.play()
		"pushed":
			$GameSfx/Skills/PushedPulled.play()
			$GameSfx/Skills/PushStoneSlide.play()
		"teleport":
			$GameSfx/Skills/TeleportIn.play()
		"skilled":
#			$GameSfx/Skills/SkilledBeep.play()
#			$GameSfx/Skills/SkilledCrystal.play()
#			$GameSfx/Skills/SkilledCrystal_long.play()
			$GameSfx/Skills/SkilledFrcer.play()
		"skill_fail":
#			$GameSfx/Skills/SkillFail.play()
			pass
		"skill_success":
#			skill_success_count += 1
#			if skill_success_count < Profiles.game_rules["skills_in_row_limit"]:
#				$GameSfx/Skills/SkillSuccessA.play()
#			else:
#				$GameSfx/Skills/SkillSuccessB.play()
#				skill_success_count = 0
			pass
			
		# events
		"countdown_a":
			$GameSfx/Events/CoundownA.play()
		"countdown_b":
			$GameSfx/Events/CoundownB.play()
		"win_jingle":
			$GameSfx/Events/Win.play()
		"loose_jingle":
			$GameSfx/Events/Loose.play()
		"record_cheers":
			$GameSfx/Events/RecordFanfare.play()
			
		# gui
		"typing":
			select_random_sfx($GuiSfx/Typing).play()
		"btn_confirm":
			$GuiSfx/BtnConfirm.play()
		"btn_cancel":
			$GuiSfx/BtnCancel.play()
		"btn_focus_change":
			$GuiSfx/BtnFocus.play()
		"menu_fade":
			$GuiSfx/MenuFade.play()
		"screen_slide":
			$GuiSfx/ScreenSlide.play()
			
			
func stop_sfx(sfx_to_stop: String):
	
	match sfx_to_stop:
			"teleport":
				$GameSfx/Skills/TeleportLoop.stop()
				$GameSfx/Skills/TeleportOut.play()
			"skilled":
				$GameSfx/Skills/SkilledFrcer.stop()
				pass
			"burst_cocking":
				$GameSfx/Burst/BurstCocking.stop()
			"last_breath":
				$GameSfx/LastBeat.stop()


func select_random_sfx(sound_group):
	
	var random_index = randi() % sound_group.get_child_count()
	var selected_sound = sound_group.get_child(random_index)
	return selected_sound
	
	
func _on_TeleportStart_finished() -> void:
	$GameSfx/Skills/TeleportLoop.play()
	
		
# MUSKA --------------------------------------------------------------------------------------------------------


var current_music_index = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro
onready var game_music: Node2D = $Music/GameMusic


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("n"):
		skip_music()
		
	if Input.is_action_just_pressed("m"):
		if game_music.get_child(current_music_index - 1).stream_paused == false:
			game_music.get_child(current_music_index - 1).stream_paused = true
			Global.hud.music_label.get_node("OffIcon").visible = true
			Global.hud.music_label.get_node("OnIcon").visible = false
			
		else:
			game_music.get_child(current_music_index - 1).stream_paused = false
			Global.hud.music_label.get_node("OnIcon").visible = true
			Global.hud.music_label.get_node("OffIcon").visible = false


func play_music(music_for: String):
	
#	return
	
	match music_for:
		"menu":
			$Music/MenuMusic/WarmUpShort.play()
		"game":
			game_music.get_child(current_music_index - 1).play()
			Global.hud.music_label.text = "%02d" % current_music_index
			printt("music_index ", current_music_index)	
			
			# če je na pavzi ga odpavzam
			game_music.get_child(current_music_index - 1).stream_paused = false
			Global.hud.music_label.get_node("OnIcon").visible = true
			Global.hud.music_label.get_node("OffIcon").visible = false


func stop_music(music_to_stop: String):
	
	match music_to_stop:
		
		"menu":
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property($Music/MenuMusic/WarmUpShort, "volume_db", -80, 0.5)
			fade_out.tween_callback($Music/MenuMusic/WarmUpShort, "stop")
		
		"game":
			for music in game_music.get_children():
				if music.is_playing():
					var current_music_volume = music.volume_db
					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
					fade_out.tween_property(music, "volume_db", -80, 1)
					fade_out.tween_callback(music, "stop")
					fade_out.tween_property(music, "volume_db", current_music_volume, 0.1) # reset glasnosti
					# return


func skip_music():	
	
	current_music_index += 1
	
	if current_music_index > game_music.get_child_count():
		current_music_index = 1
	
	for music in game_music.get_children():
		if music.is_playing():
			var current_music_volume = music.volume_db
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(music, "volume_db", -80, 0.5)
			fade_out.tween_callback(music, "stop")
			fade_out.tween_property(music, "volume_db", current_music_volume, 0.1) # reset glasnosti
			fade_out.tween_callback(self, "play_music", ["game"]).set_delay(0.5)
			return

			
	
