extends CanvasLayer
# tukaj prebavimo vse morebitne inpute in prikazuje korake procesa

signal connect_cover_closed


var cover_label_text: String = "Connecting to server" setget _update_label_text


func _input(event: InputEvent) -> void:
	
	if visible: # v nodetu nastavim propagate "stop" 
		get_tree().set_input_as_handled() # kakršen koli input setamo kot da smo ga procesiral 
	
	
func _ready() -> void:
	
	hide()

	
func open_cover():

	$Label.text = cover_label_text
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	

func close_cover():
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(self, "modulate:a", 0, 0.5)
	fade_out.tween_callback(self, "hide")
	emit_signal("connect_cover_closed")
	

func _update_label_text(new_text: String):
	
	cover_label_text = new_text
	$Label.text = cover_label_text

