extends Node2D


var game_sfx_set_to_off: bool = false
var menu_music_set_to_off: bool = false
var game_music_set_to_off: bool = false

var currently_playing_track_index = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro

var game_music_tracks_volumes_on_node: Array = [] # napolneš ga na _ready
var game_music_volume_slider_value: int # trenutni poožaj na slajderju ... da je poenoteno med obemi settingsi 

onready var game_music: Node2D = $Music/GameMusic
onready var menu_music = $Music/MenuMusic/WarmUpShort
onready var menu_music_volume_on_node = menu_music.volume_db # za reset po fejdoutu (game_over)
onready var game_music_tracks: Array = game_music.get_children()


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("n"):
		if game_music_set_to_off:
			return
		skip_track()
	
	# music toggle
	if Input.is_action_just_pressed("m") and Global.game_manager != null: # tukaj damo samo na mute ... kar ni isto kot paused
		
		if game_music_set_to_off:
			game_music_set_to_off = false
			play_music("game")
		else:
			stop_music("game")
			game_music_set_to_off = true
	
	
func _ready() -> void:
	
	Global.sound_manager = self
	randomize()
	
	# pogrebam on-node volumne v array vzporeden areju komadov 
	for track in game_music.get_children():
		game_music_tracks_volumes_on_node.append(track.volume_db)
			

# SFX --------------------------------------------------------------------------------------------------------

	
func play_stepping_sfx(current_player_energy_part: float):

		if game_sfx_set_to_off:
			return		

		var selected_tap = select_random_sfx($GameSfx/Stepping)
		selected_tap.pitch_scale = current_player_energy_part
		selected_tap.pitch_scale = clamp(selected_tap.pitch_scale, 0.6, 1)
		selected_tap.play()
	
	
func play_sfx(effect_for: String):
	
	if game_sfx_set_to_off:
		return	
		
	# če zvoka ni tukaj, pomeni da ga kličem direktno
	match effect_for:
		
		"blinking":
			select_random_sfx($GameSfx/Blinking).play() # nekateri so na mute, ker so drugače prepogosti soundi
			select_random_sfx($GameSfx/BlinkingStatic).play()
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
			$GameSfx/Skills/SkilledStatic.play()
			
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
	
			
func play_gui_sfx(effect_for: String):
	
	match effect_for:
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
				$GameSfx/Skills/SkilledStatic.stop()
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
		

func play_music(music_for: String):
	
	match music_for:
		
		"menu":
			if menu_music_set_to_off:
				return
			menu_music.play()
		
		"game":
			if game_music_set_to_off:
				return
			# set track
			var current_track = game_music.get_child(currently_playing_track_index - 1)
			current_track.play()
			

func stop_music(music_to_stop: String):
	
	match music_to_stop:
		
		"menu":
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(menu_music, "volume_db", -80, 0.5)
			fade_out.tween_callback(menu_music, "stop")
			# volume nazaj
			fade_out.tween_property(menu_music, "volume_db", menu_music_volume_on_node, 0.5)
			
		"game":
			for music in game_music.get_children():
				music.stop()

		"game_fade":
			for music in game_music.get_children():
				if music.is_playing():
					var current_music_volume = music.volume_db
					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
					fade_out.tween_property(music, "volume_db", -80, 1)
					fade_out.tween_callback(music, "stop")
					# volume nazaj
					fade_out.tween_property(music, "volume_db", current_music_volume, 0.1) # reset glasnosti


func set_game_music_volume(game_music_volume_on_slider: float): # kliče se iz settingsov
	
	# slajder je omeje od -30 do 10
	# vsakič ko sporoči vrednost je to vrednost adaptacije na setan volumen
	
	game_music_volume_slider_value = game_music_volume_on_slider # da je poenoteno med obemi settingsi
	
	var track_index = 0
	for track in game_music_tracks:
		var track_volume_on_node = game_music_tracks_volumes_on_node[track_index]
		var new_track_volume = track_volume_on_node + game_music_volume_on_slider
		track.volume_db = new_track_volume
		
		track_index += 1
		
		
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
			fade_out.tween_property(music, "volume_db", current_music_volume, 0.1) # reset glasnosti
			fade_out.tween_callback(self, "play_music", ["game"])
			return
