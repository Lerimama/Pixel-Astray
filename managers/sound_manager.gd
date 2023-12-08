	extends Node2D


var game_sfx_set_to_off: bool = false
var menu_music_set_to_off: bool = false
var game_music_set_to_off: bool = false

var currently_playing_track_index = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro

onready var teleport_loop: AudioStreamPlayer = $GameSfx/Skills/TeleportLoop # za preverjanje v igri, če se predvaja
onready var game_music: Node2D = $Music/GameMusic
onready var menu_music = $Music/MenuMusic/WarmUpShort
onready var menu_music_volume_on_node = menu_music.volume_db # za reset po fejdoutu (game_over)
onready var game_music_tracks: Array = game_music.get_children()
	
	
func _ready() -> void:
	
	Global.sound_manager = self
	randomize()
	
# SFX --------------------------------------------------------------------------------------------------------

	
func play_stepping_sfx(current_player_energy_part: float):

		if game_sfx_set_to_off:
			return		

		var selected_tap = select_random_sfx($GameSfx/Stepping)
		selected_tap.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
		selected_tap.play()
	
	
func play_sfx(effect_for: String):
	
	if game_sfx_set_to_off:
		return	
		
	# če zvoka ni tukaj, pomeni da ga kličem direktno
	match effect_for:
		"blinking":
			select_random_sfx($GameSfx/Blinking).play() # nekateri so na mute, ker so drugače prepogosti soundi
			select_random_sfx($GameSfx/BlinkingStatic).play()
		"heartbeat":
			$GameSfx/Heartbeat.play()
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
		"burst_stop":
			$GameSfx/Burst/BurstStop.play()
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
		# intro
		"thunder_strike":
			$GameSfx/Burst/Burst.play()
		"intro_stepping":
			$GameSfx/Burst/Burst.play()
			var selected_tap = select_random_sfx($GameSfx/Stepping)
			selected_tap.play()
			
			
func play_gui_sfx(effect_for: String):
	
	match effect_for:
		# events
		"countdown_a":
			$GuiSfx/Events/CoundownA.play()
		"countdown_b":
			$GuiSfx/Events/CoundownB.play()
		"win_jingle":
			$GuiSfx/Events/Win.play()
		"lose_jingle":
			$GuiSfx/Events/Loose.play()
		"record_cheers":
			$GuiSfx/Events/RecordFanfare.play()
		"tutorial_stage_done":
			$GuiSfx/Events/TutorialStageDone.play()
		# input
		"typing":
			select_random_sfx($GuiSfx/Inputs/Typing).play()
		"btn_confirm":
			$GuiSfx/Inputs/BtnConfirm.play()
		"btn_cancel":
			$GuiSfx/Inputs/BtnCancel.play()
		"btn_focus_change":
			$GuiSfx/Inputs/BtnFocus.play()
		# menu
		"menu_fade":
			$GuiSfx/MenuFade.play()
		"screen_slide":
			$GuiSfx/ScreenSlide.play()
		
		
func stop_sfx(sfx_to_stop: String):
	
	match sfx_to_stop:
		"teleport":
			if $GameSfx/Skills/TeleportLoop.is_playing(): # konec teleportanja
				$GameSfx/Skills/TeleportLoop.stop()
				$GameSfx/Skills/TeleportOut.play()
			else: # zazih ob koncu igre
				$GameSfx/Skills/TeleportLoop.stop()
		"burst_cocking":
			$GameSfx/Burst/BurstCocking.stop()
		"heartbeat":
			$GameSfx/Heartbeat.stop()
		"lose_jingle": 
			$GameSfx/Events/Loose.stop()
		"win_jingle":
			$GameSfx/Events/Win.stop()
	

func select_random_sfx(sound_group):
	
	var random_index = randi() % sound_group.get_child_count()
	var selected_sound = sound_group.get_child(random_index)
	return selected_sound
	
	
func _on_TeleportStart_finished() -> void:
	$GameSfx/Skills/TeleportLoop.play()
	
		
# MUSKA --------------------------------------------------------------------------------------------------------
		

func play_music(music_for: String):
	
	match music_for:
		"menu_music":
			if menu_music_set_to_off:
				return
			menu_music.play()

		"game_music":
			if game_music_set_to_off:
				return
			# set track
			var current_track = game_music.get_child(currently_playing_track_index - 1)
			current_track.play()
			

func stop_music(music_to_stop: String):

	match music_to_stop:
		
		"menu_music":
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(menu_music, "volume_db", -80, 0.5)
			fade_out.tween_callback(menu_music, "stop")
			# volume nazaj
			fade_out.tween_property(menu_music, "volume_db", menu_music_volume_on_node, 0.5)
			
		"game_music":
			for music in game_music.get_children():
				if music.is_playing():
					var current_music_volume = music.volume_db
					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
					fade_out.tween_property(music, "volume_db", -80, 1)
					fade_out.tween_callback(music, "stop")
					fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti

		"game_on_game-over": 
		
			for music in game_music.get_children():
				if music.is_playing():
					var current_music_volume = music.volume_db
					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
					fade_out.tween_property(music, "volume_db", -80, 1)
					fade_out.tween_callback(music, "stop")
					fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti
		

func set_game_music_volume(value_on_slider: float): # kliče se iz settingsov
	
	# slajder je omejen med -30 in 10
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)
		
		
func skip_track():
	
	currently_playing_track_index += 1
	
	if currently_playing_track_index > game_music.get_child_count():
		currently_playing_track_index = 1
	
	for music in game_music.get_children():
		if music.is_playing():
			var current_music_volume = music.volume_db
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(music, "volume_db", -80, 0.5)
			fade_out.tween_callback(music, "stop")
			fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti
			fade_out.tween_callback(self, "play_music", ["game_music"])
			return
