extends HBoxContainer


onready var game_music_bus_index: int = AudioServer.get_bus_index("GameMusic")
onready var on_icon: TextureRect = $SpeakerIcon/OnIcon
onready var off_icon: TextureRect = $SpeakerIcon/OffIcon
onready var speaker_icon: Control = $SpeakerIcon
#onready var track_label: Label = $TrackLabel
#onready var track_btn: Button = $TrackBtn


func _input(event: InputEvent) -> void: # ta varianta, da dela tipkovnica

	#func _unhandled_input(event: InputEvent) -> void:
	#	if Global.game_manager.game_on:

	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("next") and not Global.tutorial_gui.visible: # rabim kasneje kot not tutorial_on
			#			print("next press recieved")
			skip_track()

		if Input.is_action_just_pressed("mute"):
			_on_MuteBtn_pressed()


func toggle_mute(mute_it: bool):

	# če podam stanje reagiram glede na podano
	if not mute_it == null:
		Global.sound_manager.game_music_set_to_off = mute_it

	if mute_it:
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_music("game_music")
		Analytics.save_ui_click("UnMute")
	else:
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.stop_music("game_music")
		Analytics.save_ui_click("Mute")


func skip_track():

	if not Global.sound_manager.game_music_set_to_off:
		Global.sound_manager.skip_track()
		Analytics.save_ui_click("SkipTrack %d" % (Global.sound_manager.current_music_track_index + 1))


func _on_TrackBtn_pressed() -> void:

	skip_track()


func _on_MuteBtn_pressed() -> void:

	Global.sound_manager.music_toggle()

	if Global.sound_manager.game_music_set_to_off:
		modulate.a = 0.6
	else:
		modulate.a = 1

