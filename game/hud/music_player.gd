extends HBoxContainer


onready var game_music_bus_index: int = AudioServer.get_bus_index("GameMusic")
onready var on_icon: TextureRect = $SpeakerIcon/OnIcon
onready var off_icon: TextureRect = $SpeakerIcon/OffIcon
onready var track_label: Label = $TrackLabel
onready var speaker_icon: Control = $SpeakerIcon


func _unhandled_input(event: InputEvent) -> void:
	
	if Global.game_manager.game_on and visible == true: # visible je, da deluje samo na enem plejerju
		if Input.is_action_just_pressed("next") and visible == true: 
			if not AudioServer.is_bus_mute(game_music_bus_index):
				Global.sound_manager.skip_track()
		
		if Input.is_action_just_pressed("mute") and visible == true:
			AudioServer.set_bus_mute(game_music_bus_index, not AudioServer.is_bus_mute(game_music_bus_index))
			if AudioServer.is_bus_mute(game_music_bus_index) or Global.sound_manager.game_music_set_to_off:
				modulate.a = 0.6
				#on_icon.visible = false
				#off_icon.visible = true
			else:
				modulate.a = 1
				#on_icon.visible = true
				#off_icon.visible = false
				
				
#func _ready() -> void:
#	printt("AS", AudioServer.device, AudioServer.bus_count)
#	if AudioServer.is_bus_mute(game_music_bus_index) or Global.sound_manager.game_music_set_to_off:
#		modulate.a = 0.6
#	else:
#		modulate.a = 1	
		
		
#func _process(delta: float) -> void:
#
#	if AudioServer.is_bus_mute(game_music_bus_index) or Global.sound_manager.game_music_set_to_off:
#		modulate.a = 0.6
#	#		on_icon.visible = false
#	#		off_icon.visible = true
#	else:
#		modulate.a = 1
#	#		on_icon.visible = true
#	#		off_icon.visible = false
