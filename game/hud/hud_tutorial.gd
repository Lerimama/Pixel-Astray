extends GameHud

	
func _process(delta: float) -> void:
	# namen: ni kode glede levelov
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count

	# level label show on fill
	if Global.game_manager.game_data.has("level"):
		if not level_label.visible:
			level_label.visible = true	
		level_label.text = "%02d" % Global.game_manager.game_data["level"]


func set_hud(players_count: int): # kliče main na game-in
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
			
