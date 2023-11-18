extends Control


var fade_time: float = 1
var default_hud_color: Color = Color.white
var popup_time: float = 2
var highscore_broken: bool = false

var picked_indicator_alpha: float = 1
var unpicked_indicator_alpha: float = 0.2
var neighbor_indicator_alpha: float = 0.4
var active_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov

# popups 
onready var popups: Control = $Popups # skoz vidno, skrije se na gameover
onready var highscore_broken_popup: Control = $Popups/HSBroken
onready var energy_warning_popup: Control = $Popups/EnergyWarning
onready var steps_remaining: Label = $Popups/EnergyWarning/StepsRemaining

# header
onready var header: Control = $Header # kontrole iz kamere
onready var p1_statsline: HBoxContainer = $Header/PlayerLineL # neuporabljeno
onready var p1_label: Label = $Header/PlayerLineL/PlayerLabel
onready var p1_life_counter: HBoxContainer = $Header/PlayerLineL/LifeIcons
onready var p1_energy_counter: HBoxContainer = $Header/PlayerLineL/EnergyBar
onready var p1_points_holder: HBoxContainer = $Header/PlayerLineL/PointsHolder
onready var p1_points_counter: Label = $Header/PlayerLineL/PointsHolder/Points
onready var p1_color_holder: HBoxContainer = $Header/PlayerLineL/ColorHolder
onready var p1_color_counter: Label = $Header/PlayerLineL/ColorHolder/Label
onready var p1_skill_holder: HBoxContainer = $Header/PlayerLineL/SkillHolder # neuporabljeno
onready var p1_skill_counter: Label = $Header/PlayerLineL/SkillHolder/Label
onready var p1_burst_holder: HBoxContainer = $Header/PlayerLineL/BurstHolder # neuporabljeno
onready var p1_burst_counter: Label = $Header/PlayerLineL/BurstHolder/Label
onready var p2_statsline: HBoxContainer = $Header/PlayerLineR
onready var p2_label: Label = $Header/PlayerLineR/PlayerLabel # neuporabljeno
onready var p2_life_counter: HBoxContainer = $Header/PlayerLineR/LifeIcons
onready var p2_energy_counter: HBoxContainer = $Header/PlayerLineR/EnergyBar
onready var p2_points_holder: HBoxContainer = $Header/PlayerLineR/PointsHolder # neuporabljeno
onready var p2_points_counter: Label = $Header/PlayerLineR/PointsHolder/Points # neuporabljeno
onready var p2_color_holder: HBoxContainer = $Header/PlayerLineR/ColorHolder # neuporabljeno
onready var p2_color_counter: Label = $Header/PlayerLineR/ColorHolder/Label
onready var game_timer: HBoxContainer = $Header/GameTimer
onready var highscore_label: Label = $Header/HighscoreLabel

# futer
onready var footer: Control = $Footer # kontrole iz kamere
onready var game_label: Label = $Footer/FooterLine/GameLine/Game
onready var level_label: Label = $Footer/FooterLine/GameLine/Level
onready var spectrum: HBoxContainer = $Footer/FooterLine/SpectrumHolder/ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var astray_counter: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Label
onready var picked_counter: Label = $Footer/FooterLine/StraysLine/PickedHolder/Label

# debug
onready var player_life: Label = $Life
onready var player_energy: Label = $Energy
onready var picked_color_rect: ColorRect = $Footer/PickedColor/ColorRect
onready var picked_color_label: Label = $Footer/PickedColor/Value


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko in popupe
	visible = false
	highscore_broken_popup.visible = false
	energy_warning_popup.visible = false
	
	# on load setup
	var header_off_position = - 56
	var footer_off_position = 720
	# set hud poze ... zamaknjene za višino hederja
	header.rect_position.y = header_off_position
	footer.rect_position.y = footer_off_position	
	
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		set_two_players_hud()
	else:
		set_one_player_hud()


func set_two_players_hud():	
	
	# hide
	highscore_label.visible = false
	level_label.visible = false
	p1_points_holder.visible = false
	# show
	p1_label.visible = true
	p1_color_holder.visible = true
	p2_statsline.visible = true
	
	# skrij life, če je samo en lajf
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
	else:
		p1_life_counter.visible = true
		p2_life_counter.visible = true		


func set_one_player_hud():
	
	# hide
	p1_label.visible = false
	p2_statsline.visible = false
	# show
	highscore_label.visible = true
	level_label.visible = true
	
	# skrij life, če je samo en lajf
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
	else:
		p1_life_counter.visible = true
		
	
func _process(delta: float) -> void:
	
	update_stats()
	
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL: # zaenkrat samo za 1 player game
		manage_popups()
	
		
func manage_popups():
	
	# ček HS and show popup
	if Global.game_manager.game_data["game"] != Profiles.Games.TUTORIAL:
		check_for_hs()
	
	# energy warning
	if Global.game_manager.p1_stats["player_energy"] > Global.game_manager.game_settings["tired_energy_level"]:
		energy_warning_popup.visible = false	
	elif Global.game_manager.p1_stats["player_energy"] <= Global.game_manager.game_settings["tired_energy_level"] and Global.game_manager.p1_stats["player_energy"] > 2:
		energy_warning_popup.visible = true
		var energy_warning_string: String = "Low energy! Only %s steps remaining." % str(Global.game_manager.p1_stats["player_energy"] - 1)
		steps_remaining.text = energy_warning_string
	elif Global.game_manager.p1_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
		steps_remaining.text = "Low energy! Only 1 step remaining."
	elif Global.game_manager.p1_stats["player_energy"] < 2:
		# steps_remaining.text = "No more traveling! Collect a color get some energy."
		energy_warning_popup.visible = false

		
func check_for_hs():
	
	if Global.game_manager.p1_stats["player_points"] > Global.game_manager.game_data["highscore"]: # zaporedje ifov je pomembno zaradi načina setanja pogojev
		if not highscore_broken:
			# Global.sound_manager.play_sfx("record_cheers")
			highscore_broken = true
			highscore_label.modulate = Global.color_green
			highscore_broken_popup.visible = true
			yield(get_tree().create_timer(popup_time), "timeout")
			highscore_broken_popup.visible = false
	else:
		highscore_broken_popup.visible = false
		highscore_label.modulate = default_hud_color
		highscore_broken = false # more bit, če zgubiš rekord med igro
			
		
func update_stats():	
	
	# player 1 stats
	p1_life_counter.life_count = Global.game_manager.p1_stats["player_life"]
	p1_energy_counter.energy = Global.game_manager.p1_stats["player_energy"]
	p1_points_counter.text = "%d" % Global.game_manager.p1_stats["player_points"]
	p1_color_counter.text = "%d" % Global.game_manager.p1_stats["colors_collected"]
	p1_burst_counter.text = "%d" % Global.game_manager.p1_stats["burst_count"]
	p1_skill_counter.text = "%d" % Global.game_manager.p1_stats["skill_count"]
	
	# player 2 stats
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		p2_life_counter.life_count = Global.game_manager.p2_stats["player_life"]
		p2_energy_counter.energy = Global.game_manager.p2_stats["player_energy"]
		p2_color_counter.text = "%d" % Global.game_manager.p2_stats["colors_collected"]
	
	# game stats
	game_label.text = Global.game_manager.game_data["game_name"]
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % (Global.game_manager.p1_stats["colors_collected"] + Global.game_manager.p2_stats["colors_collected"])
	
	# debug
	player_life.text = "LIFE: %d" % Global.game_manager.p1_stats["player_life"]
	player_energy.text = "E: %d" % Global.game_manager.p1_stats["player_energy"]		

		
func fade_in(): # kliče kamera
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_callback(self, "set_visible", [true])
	fade_in.parallel().tween_property(header, "rect_position:y", 0, 2)
	fade_in.parallel().tween_property(footer, "rect_position:y", 720 - 56, 2)


func fade_out(): # kliče kamera
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0 - 56, 2)
	fade_in.parallel().tween_property(footer, "rect_position:y", 720, 2)
	fade_in.tween_callback(self, "set_visible", [false])
	
	
	
# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors): # ukaz pride iz GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	
	for color in available_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		new_color_indicator.modulate.a = unpicked_indicator_alpha
		spectrum.add_child(new_color_indicator)
		
		active_color_indicators.append(new_color_indicator)
			
		# debug ... zapis indexa
		# new_color_indicator.get_node("IndicatorCount").text = str(indicator_index) 
	
	
func show_picked_color(picked_pixel_color):
	
	# picked color statline
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	picked_color_rect.color = picked_pixel_color

	show_color_indicator(picked_pixel_color)

					
func show_color_indicator(picked_color):
	
	var current_indicator_index: int
	for indicator in active_color_indicators:
		# pobrana barva
		if indicator.color == picked_color:
			current_indicator_index = active_color_indicators.find(indicator)
			indicator.modulate.a = picked_indicator_alpha
			break
		# preostale barve	
		elif Global.game_manager.game_settings["pick_neighbor_mode"]: # efekt na preostalih barvah 
			indicator.modulate.a = unpicked_indicator_alpha
			
	if Global.game_manager.game_settings["pick_neighbor_mode"]:	# opredelitev sosedov glede na položaj pobrane barve
		
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
		# na začetku holderja indikatorjev 
		if current_indicator_index == 0:		
			active_color_indicators[next_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		# na koncu holderja indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
			active_color_indicators[prev_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color] # pošljem sosednje barve v GM
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
			active_color_indicators[next_indicator_index].modulate.a = neighbor_indicator_alpha
			active_color_indicators[prev_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		
	# izbris iz aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_sudden_death_active() -> void:
	pass


func _on_GameTimer_gametime_is_up() -> void:
	
	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
