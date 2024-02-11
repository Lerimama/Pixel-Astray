extends GameHud

	
func fade_in_instructions_popup(in_time: float):
	# namen: prilagojena navodila
	
	title.text %= Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
	if Global.game_manager.game_data["game"] == Profiles.Games.CLEANER:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		label.text %= "power vs kill"
		label_2.text %= "kontrole"
		label_3.text %= "energija"
		label_4.text %= "lajf"
		label_5.text %= "kaj šteje"
		label_6.text %= "GO pogoji"
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER_DUEL:
		$Popups/Instructions/Controls.hide()
		$Popups/Instructions/ControlsDuel.show()
		label.text %= "power vs kill"
		label_2.text %= "kontrole"
		label_3.text %= "energija"
		label_4.text %= "lajf"
		label_5.text %= "kaj šteje"
		label_6.text %= "GO pogoji"
	else: # ERASERji
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		label.text %= "power vs kill"
		label_2.text %= "kontrole"
		label_3.text %= "energija"
		label_4.text %= "lajf"
		label_5.text %= "kaj šteje"
		label_6.text %= "GO pogoji"
					
	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)
