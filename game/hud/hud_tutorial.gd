extends GameHud

	

func set_hud(): # kliče main na game-in
	# namen: hs se pokaže, čeprav ga ne beleži, totalna redukcija
	
	# players
	p1_label.visible = false
	p2_statsline.visible = false
	# popups
	p1_energy_warning_popup = $Popups/EnergyWarning/Solo
		
	# lajf counter
	p1_life_counter.visible = true
	p2_life_counter.visible = true
		
	# level label
	level_label.visible = true
	highscore_label.visible = true
			
