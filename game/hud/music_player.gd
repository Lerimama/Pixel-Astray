extends Label


onready var on_icon: TextureRect = $OnIcon
onready var off_icon: TextureRect = $OffIcon


func _input(event: InputEvent) -> void:
	
	if Global.game_manager.game_on and visible == true: # visible je, da deluje samo na enem plejerju
		if Input.is_action_just_pressed("n") and visible == true: 
			if Global.sound_manager.game_music_set_to_off: # ne skipa med mute
				return
			Global.sound_manager.skip_track()
		
		if Input.is_action_just_pressed("m") and visible == true:
			if Global.sound_manager.game_music_set_to_off:
				Global.sound_manager.game_music_set_to_off = false
				Global.sound_manager.play_music("game")
			else:
				Global.sound_manager.stop_music("game")
				Global.sound_manager.game_music_set_to_off = true
	
	# get_viewport().set_input_as_handled() # preventam dvojni klik, ker je en music pleyer vedno skrit
	

func _process(delta: float) -> void:
	
	text = "%02d" % Global.sound_manager.currently_playing_track_index
	
	if Global.sound_manager.game_music_set_to_off:
		on_icon.visible = false
		off_icon.visible = true
	else:
		on_icon.visible = true
		off_icon.visible = false
