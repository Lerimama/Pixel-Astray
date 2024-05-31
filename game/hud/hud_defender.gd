extends GameHud


func check_for_warning(player_stats: Dictionary, warning_popup: Control):
	# namen: out ... drugače prikaže in čekira
	return
	
	if warning_popup:
		var steps_remaining_label: Label
		steps_remaining_label = warning_popup.get_node("StepsRemaining")
		if player_stats["player_energy"] < tired_energy_limit and not player_stats["player_energy"] <= 0:
			steps_remaining_label.text = "LOW ENERGY WARNING!"
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] > tired_energy_limit:
			if warning_popup.visible == true:
				warning_out(warning_popup)
		elif player_stats["player_energy"] <= 0:
			if warning_popup.visible == true:
				warning_out(warning_popup)		
