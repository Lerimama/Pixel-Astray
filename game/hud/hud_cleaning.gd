extends GameHud

	
func fade_in_instructions_popup(in_time: float):
	# namen: za to igro prilagojena navodila

	if Global.game_manager.game_data["game"] == Profiles.Games.CLASSIC:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "NNNNNNNNNN"
		label.text = "Game is over when you are out of energy or time runs out"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is limited"
		label_5.text = "Highscore is the highest points total"
		label_6.text = ""
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Collect colors and beat the highscore"
		label.text = "Game is over when you are out of energy or time runs out"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is limited"
		label_5.text = "Highscore is the highest points total"
		label_6.text = ""
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER_DUEL:
		$Popups/Instructions/Controls.hide()
		$Popups/Instructions/ControlsDuel.show()
		title.text = Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
		win_label.text = "Surviving player or player with higher points total wins"
		label.text = "Game is over when a player loses all lives or time runs out"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is limited"
		label_5.text = "No highscores"
		label_6.text = ""
	else: # ERASERji
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
		win_label.text = "Collect all available colors"
		label.text = "Game is over when you are out of energy"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is unlimited"
		label_5.text = "Highscore is the fastest time"
		label_6.text = ""

	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)

# samo za classic
#neu
onready var level_up_popup: Control = $Popups/LevelUp

func _process(delta: float) -> void:
	# namen: čekiranje levela
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count
	level_label.text = "%02d" % Global.game_manager.current_level 
	
	
func level_up_popup_in(level_reached: int):
	
	level_up_popup.get_node("Label").text = "LEVEL %s" % str(level_reached)
	level_up_popup.show()
	level_up_popup.modulate.a = 0
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 1, 0.3)


func level_up_popup_out():
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 0, 0.3)
	popup_in.tween_callback(level_up_popup, "hide")


func empty_color_indicators():
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	active_color_indicators.clear()
