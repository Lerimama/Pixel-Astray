extends Control


# ta node more bit na vrhu zaradi zaporedja nalaganja
var player_stats_on_hud: Dictionary
var game_stats_on_hud: Dictionary

var fade_time: float = 1
var default_hud_color: Color = Color.white

# spectrum indicators
var active_color_indicators: Array = []
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var indicator_holder: GridContainer = $Footer/ColorSpectrumLite/GridContainer

#header
onready var header: Control = $Header
onready var player_life: Label = $Life # _temp, pravi je na samih ikonah
onready var player_energy: Label = $Energy # temp
onready var player_points: Label = $Header/HudLine_TL/PointsCounter/Points
onready var cells_travelled: Label = $Header/HudLine_TL/CellCounter/CellsTravelled
onready var skills_used: Label = $Header/HudLine_TL/SkillCounter/SkillsUsed
onready var game_timer: HBoxContainer = $Header/GameTimer # uporabljeno v drugih filetih
onready var level: Label = $Header/HudLine_TR/Level
onready var highscore_label: Label = $Header/HudLine_TL/Highscore
onready var music_label: Label = $Header/HudLine_TR/MusicLabel
onready var on_icon: TextureRect = $Header/HudLine_TR/MusicLabel/OnIcon
onready var off_icon: TextureRect = $Header/HudLine_TR/MusicLabel/OffIcon
# ---
#onready var picked_color_rect: ColorRect = $Header/HudLine_TR/PickedColor/ColorRect
#onready var picked_color_label: Label = $Header/HudLine_TR/PickedColor/Value
#onready var pixels_off: Label = $Header/HudLine_TR/OffedCounter/PixelsOff
#onready var stray_pixels_counter: HBoxContainer = $Header/HudLine_TR/StrayCounter
#onready var stray_pixels: Label = $Header/HudLine_TR/StrayCounter/PixelsStray
#onready var pixels_off_counter: HBoxContainer = $Header/HudLine_TR/OffedCounter

#futer
onready var footer: Control = $Footer
onready var picked_color_rect: ColorRect = $Footer/PickedColor/ColorRect
onready var picked_color_label: Label = $Footer/PickedColor/Value
onready var pixels_off: Label = $Footer/HudLine_BR/OffedCounter/PixelsOff
onready var stray_pixels_counter: HBoxContainer = $Footer/HudLine_BR/StrayCounter
onready var stray_pixels: Label = $Footer/HudLine_BR/StrayCounter/PixelsStray
onready var pixels_off_counter: HBoxContainer = $Footer/HudLine_BR/OffedCounter

# popups 
var highscore_broken: bool =  false
var highscore_broken_popup_time: float = 2
onready var highscore_broken_popup: Control = $Popups/HSBroken
onready var energy_warning_popup: Control = $Popups/EnergyWarning
onready var steps_remaining_counter: Label = $Popups/EnergyWarning/StepsRemainingHLine/StepsRemainingCounter
onready var popups: Control = $Popups # za skrit na gameover


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko in popupe
	visible = false
	

func _process(delta: float) -> void:
	
	player_stats_on_hud = Global.game_manager.player_stats
	game_stats_on_hud = Global.game_manager.game_stats
	
	writing_stats()
	
	# ček HS and show popup
	var current_highscore = game_stats_on_hud["highscore"]
	var current_points = player_stats_on_hud["player_points"]
	if current_points > current_highscore: # zaporedje ifov je pomembno zaradi načina setanja pogojev
		if not highscore_broken:
			# Global.sound_manager.play_sfx("record_cheers")
			highscore_broken = true
			highscore_label.modulate = Global.color_green
			highscore_broken_popup.visible = true
			yield(get_tree().create_timer(highscore_broken_popup_time), "timeout")
			highscore_broken_popup.visible = false
	else:
		highscore_broken_popup.visible = false
		highscore_label.modulate = default_hud_color
		highscore_broken = false # more bit, če zgubiš rekord med igro
	
	# show popup energy warning
	if player_stats_on_hud["player_energy"] <= Profiles.game_rules["tired_energy"] and player_stats_on_hud["player_energy"] > 1:# and player_stats_on_hud["player_energy"] > 1:
		energy_warning_popup.visible = true
		steps_remaining_counter.text = str(player_stats_on_hud["player_energy"])
	else:
		energy_warning_popup.visible = false		
	
	# music plejer display
	music_label.text = "%02d" % Global.sound_manager.currently_playing_track_index
	if Global.sound_manager.game_music_set_to_off:
		on_icon.visible = false
		off_icon.visible = true
	else:
		on_icon.visible = true
		off_icon.visible = false
			
			
func writing_stats():	
	
	# pixel stats
	player_points.text = "%04d" % player_stats_on_hud["player_points"]
	cells_travelled.text = "%04d" % player_stats_on_hud["cells_travelled"]
	skills_used.text = "%04d" % player_stats_on_hud["skills_used"]
	
	# game stats
	level.text = "LEVEL %02d" % game_stats_on_hud["level_no"]
	stray_pixels.text = "%03d" % game_stats_on_hud["stray_pixels_count"]
	pixels_off.text = "%03d" % game_stats_on_hud["off_pixels_count"]
	
	# _temp
	player_life.text = "LIFE: %01d" % player_stats_on_hud["player_life"]
	player_energy.text = "E: %04d" % player_stats_on_hud["player_energy"]
	
	if not highscore_broken:
		highscore_label.text = "HS %04d" % game_stats_on_hud["highscore"]
	else:
		highscore_label.text = "HS %04d" % player_stats_on_hud["player_points"]
		
		
func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)


# COLORS ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors): # ukaz pride iz GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	for color in available_colors:
		indicator_index += 1 
		var new_color_indicator = ColorIndicator.instance()
		indicator_holder.add_child(new_color_indicator)
		
		if Profiles.game_rules["collect_color_mode"]:
			new_color_indicator.visible = false
			new_color_indicator.color = color
		else:
			new_color_indicator.color = color
		
		# zapis indexa ... invisible
		new_color_indicator.get_node("IndicatorCount").text = str(indicator_index)
		active_color_indicators.append(new_color_indicator)
	
	
func color_picked(picked_pixel_color):
	
	# picked color stats
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	# color effects
	picked_color_rect.color = picked_pixel_color

	if Profiles.game_rules["collect_color_mode"]:
		show_color_indicator(picked_pixel_color)
	else:
		hide_color_indicator(picked_pixel_color)
	
	
func show_color_indicator(picked_color):
	
	var current_indicator_index: int # za določanje sosedov
	for indicator in active_color_indicators:
		if indicator.color == picked_color:
			indicator.visible = true
			break
	
					
func hide_color_indicator(picked_color):
	
	var current_indicator_index: int
	for indicator in active_color_indicators:
		if indicator.color == picked_color:
			current_indicator_index = active_color_indicators.find(indicator)
			# efekt na pobrani barvi
			if Profiles.game_rules["pick_neighbour_mode"]:
				indicator.modulate.a = 0
				indicator.visible = false
			else: 
				indicator.modulate.a = 0.32
				break
		elif Profiles.game_rules["pick_neighbour_mode"]: # efekt na preostalih barvah 
			indicator.modulate.a = 0.5
			
	if Profiles.game_rules["pick_neighbour_mode"]:	
		# opredelitev sosedov glede na položaj pobrane barve
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		# indexi onbeh sosednjih indikatorjev
		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
		# na začetku živih indikatorjev 
		if current_indicator_index == 0:		
			active_color_indicators[next_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color]
		# na koncu živih indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color]
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
			active_color_indicators[next_indicator_index].modulate.a = 1
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color]
		
	# izbris iz arraya živih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_deathmode_active() -> void:
	Global.game_manager.deathmode_active = true


func _on_GameTimer_gametime_is_up() -> void:
	Global.game_manager.game_over(Global.reason_time)

