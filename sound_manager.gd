extends Node2D


var game_sfx_set_to_off: bool = false
var menu_music_set_to_off: bool = false
var game_music_set_to_off: bool = false

var current_music_track_index: int = 0 # ga ne resetiraš, da ostane v spominu skozi celo igro

onready var game_music_node: Node2D = $Music/GameMusic
onready var menu_music: AudioStreamPlayer = $Music/MenuMusic/WarmUpShort
onready var menu_music_volume_on_node = menu_music.volume_db # za reset po fejdoutu (game over)


func _ready() -> void:
	
	Global.sound_manager = self
	randomize()
	
	# setam prvi komad glede na level

	
# SFX --------------------------------------------------------------------------------------------------------

	
func play_stepping_sfx(current_player_energy_part: float): # za intro in defenderje

	if not game_sfx_set_to_off:
		var selected_tap = select_random_sfx($GameSfx/Stepping)
		selected_tap.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
		selected_tap.play()
	
	
func play_sfx(effect_for: String):
	
	if not game_sfx_set_to_off:
		match effect_for:
			"stray_step":
				$GameSfx/StraySlide.play()
			"blinking": # GM na strays spawn, ker se bolje sliši
				select_random_sfx($GameSfx/Blinking).play() # nekateri so na mute, ker so drugače prepogosti soundi
				select_random_sfx($GameSfx/BlinkingStatic).play()
			"thunder_strike": # intro in GM na strays spawn
				$GameSfx/Burst.play()
	
			
func play_gui_sfx(effect_for: String):
	
	match effect_for:
		# game
		"start_countdown_a":
			$GuiSfx/StartCoundownA.play()
		"start_countdown_b":
			$GuiSfx/StartCoundownB.play()
		"game_countdown_a":
			$GuiSfx/GameCoundownA.play()
		"game_countdown_b":
			$GuiSfx/GameCoundownB.play()
		"win_jingle":
			$GuiSfx/Win.play()
		"lose_jingle":
			$GuiSfx/Loose.play()
		"tutorial_stage_done":
			$GuiSfx/TutorialStageDone.play()
		# input
		"typing":
			select_random_sfx($GuiSfx/Inputs/Typing).play()
		"btn_confirm":
			$GuiSfx/Inputs/BtnConfirm.play()
		"btn_cancel":
			$GuiSfx/Inputs/BtnCancel.play()
		"btn_focus_change":
			if Global.allow_focus_sfx:
				$GuiSfx/Inputs/BtnFocus.play()
		# menu
		"menu_fade":
			$GuiSfx/MenuFade.play()
		"screen_slide":
			$GuiSfx/ScreenSlide.play()
		

func select_random_sfx(sound_group: Node2D):
	
	var random_index = randi() % sound_group.get_child_count()
	var selected_sound = sound_group.get_child(random_index)
	
	return selected_sound
	
		
# MUSKA --------------------------------------------------------------------------------------------------------
		

func play_music(music_for: String):
	
	match music_for:
		"menu_music":
			if not menu_music_set_to_off:
				menu_music.play()

		"game_music":
			
			if not game_music_set_to_off:
				# set track
				var current_track_playing: Node = game_music_node.get_child(current_music_track_index)
				current_track_playing.play()
				Global.hud.music_track_label.text = current_track_playing.name
			

func stop_music(music_to_stop: String):
	
	match music_to_stop:
		
		"menu_music":
			menu_music.stop()
		"game_music":
			for track in game_music_node.get_children():
				if track.is_playing():
					track.stop()
		"game_music_on_gameover":
			for track in game_music_node.get_children():
				if track.is_playing():
					var current_music_volume = track.volume_db
					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
					fade_out.tween_property(track, "volume_db", -80, 2)
					fade_out.tween_callback(track, "stop")
					# volume reset
					fade_out.tween_callback(track, "set_volume_db", [current_music_volume]) # reset glasnosti
					

func set_game_music_volume(value_on_slider: float): # kliče se iz settingsov
	
	# slajder je omejen med -30 in 10
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)
		
		
func skip_track():
	
	current_music_track_index += 1
	
	if current_music_track_index >= game_music_node.get_child_count():
		current_music_track_index = 0
	
	for track in game_music_node.get_children():
		if track.is_playing():
			var current_track_volume = track.volume_db
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(track, "volume_db", -80, 0.5)
			fade_out.tween_callback(track, "stop")
			fade_out.tween_callback(track, "set_volume_db", [current_track_volume]) # reset glasnosti
			fade_out.tween_callback(self, "play_music", ["game_music"])
		
		
func change_menu_music():
	
	var menu_music_tracks: Array = $Music/MenuMusic.get_children()
	
	# trenuten komad
	var current_track_index: int = 0 
	var current_music_volume: int = -80
	for music in menu_music_tracks:
		if music.is_playing():
			current_track_index = menu_music_tracks.find(music)
			current_music_volume = music.volume_db
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(music, "volume_db", -80, 0.5)
			fade_out.tween_callback(music, "stop")
			yield(fade_out, "finished")
			break
	
	# izberem naslednji komad
	current_music_volume = -25 # debug
	var new_track_index = current_track_index + 1
	if new_track_index >= menu_music_tracks.size():
		new_track_index = 0
	var new_menu_track = menu_music_tracks[new_track_index]
	new_menu_track.volume_db = current_music_volume
	new_menu_track.play()
