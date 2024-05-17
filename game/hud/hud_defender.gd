#extends Control
extends GameHud


onready var level_up_popup: Control = $Popups/LevelUp
onready var level_limit_holder: HBoxContainer = $Footer/FooterLine/LevelLimitHolder
onready var level_limit_label_1: Label = $Footer/FooterLine/LevelLimitHolder/Label
onready var level_limit_label_2: Label = $Footer/FooterLine/LevelLimitHolder/Label2


func _process(delta: float) -> void:
	# namen: update level label, limite levela
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count

	# level label show on fill
	if Global.game_manager.game_data.has("level"):
		if not level_label.visible:
			level_label.visible = true	
		level_label.text = "%02d" % Global.game_manager.game_data["level"]
	
	# to level up
	level_limit_label_1.text = "%d" % (Global.game_manager.stages_per_level - Global.game_manager.current_stage)
	level_limit_label_2.text = "COLORS TO LEVEL UP"
	
	
func set_hud(players_count: int): # kliče main na game-in
	# namen: ikone v player statline, samo 1 player, ni lajfov, ni energije, level data je vis tudi če je prazen, energy counter
	# namen: skijem elemente brez preverjanja
	
	# hide
	p1_label.visible = false
	p2_statsline.visible = false
	strays_counters_holder.visible = false
	p1_color_holder.visible = false	
	p1_life_counter.visible = false
	p1_energy_counter.visible = false
	level_limit_holder.visible = true
	strays_counters_holder.visible = false

	# popups
	p1_energy_warning_popup = $Popups/EnergyWarning/Solo	

	# level label
	if not Global.game_manager.game_data.has("level"):
		level_label.visible = false

	# highscore		
	p1_points_holder.visible = true
	highscore_label.visible = true
	set_current_highscore()
	
	
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
				
						
# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors: Array): # kliče GM
	# namen: moduliram
	
	var indicator_index = 0 # za fiksirano zaporedje
	
	for color in available_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		
		new_color_indicator.modulate.a = 0.3
		spectrum.add_child(new_color_indicator)
		active_color_indicators.append(new_color_indicator)


func empty_color_indicators():
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	active_color_indicators.clear()
	
	
func update_indicator_on_stage_up(current_stage: int): 

	# obarvam indikator
	if not active_color_indicators.empty(): # zazih
		var current_stage_indicator_index: int = current_stage - 1
		active_color_indicators[current_stage_indicator_index].modulate.a = 1

					
func show_color_indicator(picked_color: Color):
	return # stray kliče po animaciji, ampak v defenderju se nič ne zgodi


func check_for_warning(player_stats: Dictionary, warning_popup: Control):
	# namen drugače prikaže in čekira
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


func _on_StartButton_pressed() -> void:
	pass # Replace with function body.
