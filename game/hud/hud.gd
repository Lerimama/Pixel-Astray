extends GameHud


onready var level_up_popup: Control = $Popups/LevelUp
onready var level_limit_holder: HBoxContainer = $Footer/FooterLine/LevelLimitHolder
onready var level_limit_label_1: Label = $Footer/FooterLine/LevelLimitHolder/Label
onready var level_limit_label_2: Label = $Footer/FooterLine/LevelLimitHolder/Label2
onready var pixel_picked_holder: HBoxContainer = $Footer/FooterLine/StraysLine/PickedHolder
onready var pixel_astray_holder: HBoxContainer = $Footer/FooterLine/StraysLine/AstrayHolder


func _process(delta: float) -> void:
	# namen: dodam čekiranje levela in limite level točk
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count

	# level label show on fill
	if Global.game_manager.game_data.has("level") and not level_label.visible:
		level_label.visible = true	
			
	# zapis mankajočega do level up
	if Global.game_manager.game_data.has("level"): # multilevel
		level_label.text = "%02d" % Global.game_manager.game_data["level"]
		if Global.game_manager.game_data.has("level_goal_count"): # število točk ali barv
			# kateri ima višji score
			var current_biggest_score: int = 0
			for player in get_tree().get_nodes_in_group(Global.group_players):
				if player.player_stats["player_points"] > current_biggest_score:
					current_biggest_score = player.player_stats["player_points"]
			# razlika med limito in višjim skorom
			var to_limit_count: int = Global.game_manager.game_data["level_goal_count"] - current_biggest_score
			to_limit_count = clamp(to_limit_count, 0, to_limit_count)
			level_limit_label_1.text = "%d" % to_limit_count 
			level_limit_label_2.text = "POINTS TO LEVEL UP"
		else:
			level_limit_label_1.text = "%d" % Global.game_manager.strays_in_game_count
			level_limit_label_2.text = "COLORS TO PICK"


func set_hud(players_count: int): # kliče main na game-in
	# namen: dodam level points limit counter za eternal in setam hud za enigmo 
	
	if players_count == 1:
		# players
		p1_label.visible = false
		p2_statsline.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/Solo
	elif players_count == 2:
		# players
		p1_label.visible = true
		p1_color_holder.visible = false
		p2_statsline.visible = true
		p2_color_holder.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/DuelP1
		p2_energy_warning_popup = $Popups/EnergyWarning/DuelP2
		# hs		
		highscore_label.visible = false
	
	# lajf counter
	if Global.game_manager.game_settings["lose_life_on_hit"] and Global.game_manager.game_settings["player_start_life"] > 1:
		p1_life_counter.visible = true
		p2_life_counter.visible = true
	else:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
		
	# level label
	if not Global.game_manager.game_data.has("level"):
		level_label.visible = false
	
	# eternal	
	if Global.game_manager.game_data.has("level"): # multilevel game
		p1_energy_counter.visible = false
		p2_energy_counter.visible = false	
		level_limit_holder.visible = true
		strays_counters_holder.visible = false
	
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		p1_energy_counter.visible = false
		p1_points_counter.visible = false
		highscore_label.visible = true
		strays_counters_holder.visible = false
		level_limit_holder.visible = true
	
	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		highscore_label.visible = false
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		p1_points_holder.visible = false
		p2_points_holder.visible = false
		highscore_label.visible = true
		set_current_highscore()
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		p1_points_holder.visible = true
		p2_points_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()


#func fade_in_instructions_popup(in_time: float):
#
#	instructions_popup.get_instructions_content(current_highscore, current_highscore_owner)
#
#	var show_instructions_popup = get_tree().create_tween()
#	show_instructions_popup.tween_callback(instructions_popup, "show")
#	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)

	
func level_up_popup_in(level_reached: int): 
	
	level_up_popup.modulate.a = 0
	level_up_popup.get_node("Label").text = "LEVEL UP" # "LEVEL %s" % str(level_reached)
	level_up_popup.show()
	
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


func update_stats(stat_owner: Node, player_stats: Dictionary):
	# namen: preverjanje števila točk in klic next level v GM (na koncu)	
	
	# player stats
	match stat_owner.name:
		"p1":
			p1_life_counter.life_count = player_stats["player_life"]
			p1_energy_counter.energy = player_stats["player_energy"]
			p1_points_counter.text = "%d" % player_stats["player_points"]
			p1_color_counter.text = "%d" % player_stats["colors_collected"]
			p1_burst_counter.text = "%d" % player_stats["burst_count"]
			p1_skill_counter.text = "%d" % player_stats["skill_count"]
			p1_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p1_energy_warning_popup)
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			p2_skill_counter.text = "%d" % player_stats["skill_count"]
			p2_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p2_energy_warning_popup)

	# debug
	player_life.text = "LIFE: %d" % player_stats["player_life"]
	player_energy.text = "E: %d" % player_stats["player_energy"]

	if not Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
		check_for_hs(player_stats)
	
	if Global.game_manager.game_data.has("level_goal_count") and player_stats["player_points"] >= Global.game_manager.game_data["level_goal_count"]:
		Global.game_manager.upgrade_level("regular")
