extends HBoxContainer


onready var game_music_bus_index: int = AudioServer.get_bus_index("GameMusic")
onready var mute_btn: TextureButton = $MuteBtn
onready var track_btn: Button = $TrackBtn
onready var available_tracks: Array = Global.sound_manager.game_music_node.get_children()


func _input(event: InputEvent) -> void: # ta varianta, da dela tipkovnica

	if Global.game_manager.game_on:
		if Input.is_action_just_pressed("next") and not Global.tutorial_gui.visible: # rabim kasneje kot not tutorial_on
			_on_TrackBtn_pressed()
		if Input.is_action_just_pressed("mute"):
			toggle_mute()


func _ready() -> void:

	mute_btn.set_pressed_no_signal(not Global.sound_manager.game_music_set_to_off)

	# ime komada na vrsti
	var game_music_track_index: int = Global.sound_manager.current_music_track_index
	track_btn.text = available_tracks[game_music_track_index].name


func _toggle_mute(mute_it: bool):

	if mute_it:
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_music("game_music")
		Analytics.save_ui_click("UnMute")
	else:
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.stop_music("game_music")
		Analytics.save_ui_click("Mute")


func _on_TrackBtn_pressed() -> void:

	if not Global.sound_manager.game_music_set_to_off:

		var new_track_name: String = Global.sound_manager.skip_track().name
		track_btn.text = new_track_name

		Analytics.save_ui_click("SkipTrack %d" % (Global.sound_manager.current_music_track_index))


func toggle_mute():

	# play
	if Global.sound_manager.game_music_set_to_off:
		Global.sound_manager.game_music_set_to_off = false
		Global.sound_manager.play_music("game_music")
		Analytics.save_ui_click("UnMute")
	# mute
	else:
		Global.sound_manager.game_music_set_to_off = true
		Global.sound_manager.stop_music("game_music")
		Analytics.save_ui_click("Mute")

	mute_btn.set_pressed_no_signal(not Global.sound_manager.game_music_set_to_off)


func _on_MuteBtn_toggled(button_pressed: bool) -> void:

	toggle_mute()

