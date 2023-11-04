extends Control


# ta node more bit na vrhu zaradi zaporedja nalaganja
var player_stats_on_hud: Dictionary
var game_data_on_hud: Dictionary

var fade_time: float = 1
var default_hud_color: Color = Color.white

# spectrum indicators
var active_color_indicators: Array = [] # indikatorji so generirani ob spawnanju pixlov (so skriti, ali pa ne)
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var indicator_holder: HBoxContainer = $Footer/ColorSpectrum	

# header
onready var header: Control = $Header
onready var player_life: Label = $Life # _temp, pravi je na samih ikonah
onready var player_energy: Label = $Energy # temp
onready var life_counter: HBoxContainer = $Header/HudLine_TL/LifeIcons
onready var player_points: Label = $Header/HudLine_TL/PointsCounter/Points
onready var burst_count: Label = $Header/HudLine_TL/BurstCounter/Label
onready var skill_count: Label = $Header/HudLine_TL/SkillCounter/Label
onready var game_timer: HBoxContainer = $Header/GameTimer # uporabljeno v drugih filetih
onready var level: Label = $Header/HudLine_TR/Level
onready var highscore_label: Label = $Header/HudLine_TR/Highscore
onready var music_label: Label = $Header/HudLine_TR/MusicLabel
onready var on_icon: TextureRect = $Header/HudLine_TR/MusicLabel/OnIcon
onready var off_icon: TextureRect = $Header/HudLine_TR/MusicLabel/OffIcon

# futer
onready var footer: Control = $Footer
onready var picked_color_rect: ColorRect = $Footer/PickedColor/ColorRect
onready var picked_color_label: Label = $Footer/PickedColor/Value
onready var pixels_off: Label = $Footer/HudLine_BR/OffedCounter/PixelsOff
onready var stray_pixels_counter: HBoxContainer = $Footer/HudLine_BR/StrayCounter
onready var stray_pixels: Label = $Footer/HudLine_BR/StrayCounter/PixelsStray
onready var pixels_off_counter: HBoxContainer = $Footer/HudLine_BR/OffedCounter

# popups 
var popup_time: float = 2
var highscore_broken: bool =  false
onready var popups: Control = $Popups # skoz vidno, skrije se na gameover
onready var highscore_broken_popup: Control = $Popups/HSBroken
onready var energy_warning_popup: Control = $Popups/EnergyWarning
onready var steps_remaining: Label = $Popups/EnergyWarning/StepsRemaining


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko in popupe
	visible = false
	highscore_broken_popup.visible = false
	energy_warning_popup.visible = false
	
	# disable life icons if
	if Profiles.default_player_stats["player_life"] == 1:
		life_counter.visible = false
	
	
	
func _process(delta: float) -> void:
	
	player_stats_on_hud = Global.game_manager.player_stats
	game_data_on_hud = Global.game_manager.game_data
	
	writing_stats()
	
	# ček HS and show popup
	if Global.game_manager.game_data["level"] > 1: # 0 = tutorial, 1 = practice
#	if Global.game_manager.game_data["level"] != Profiles.Levels.PRACTICE and Global.game_manager.game_data["level"] != Profiles.Levels.TUTORIAL:
		check_for_hs()
	
	# show popup energy warning
	if player_stats_on_hud["player_energy"] > Profiles.game_rules["tired_energy"]:
		energy_warning_popup.visible = false	
	elif player_stats_on_hud["player_energy"] <= Profiles.game_rules["tired_energy"] and player_stats_on_hud["player_energy"] > 2:
		energy_warning_popup.visible = true
		var energy_warning_string: String = "Low energy! Only %s steps remaining." % str(player_stats_on_hud["player_energy"] - 1)
		steps_remaining.text = energy_warning_string
	elif player_stats_on_hud["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
		steps_remaining.text = "Low energy! Only 1 step remaining."
	elif player_stats_on_hud["player_energy"] < 2:
		# steps_remaining.text = "No more steps!"
		energy_warning_popup.visible = false
		
	# music plejer display
	music_label.text = "%02d" % Global.sound_manager.currently_playing_track_index
	if Global.sound_manager.game_music_set_to_off:
		on_icon.visible = false
		off_icon.visible = true
	else:
		on_icon.visible = true
		off_icon.visible = false
	
		
func check_for_hs():
	print("LEKIRMA", Global.game_manager.game_data["level"])
	
	var current_points = player_stats_on_hud["player_points"]
	var current_highscore = game_data_on_hud["highscore"]
	if current_points > current_highscore: # zaporedje ifov je pomembno zaradi načina setanja pogojev
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
			
		
func writing_stats():	
	
	# level setup
	var level_key = game_data_on_hud["level"]
	
	if level_key == Profiles.Levels.PRACTICE:
		game_timer.visible = false
		highscore_label.visible = false
		level.text = str(Profiles.Levels.keys()[level_key])
	elif level_key == Profiles.Levels.TUTORIAL:
		level.text = str(Profiles.Levels.keys()[level_key])
	else:
		highscore_label.visible = true
		level.text = "LEVEL " + str(Profiles.Levels.keys()[level_key])
		# hs label
		if not highscore_broken:
			highscore_label.text = "HS %04d" % game_data_on_hud["highscore"]
		else:
			highscore_label.text = "HS %04d" % player_stats_on_hud["player_points"]
		
	# pixel stats
	player_points.text = "%04d" % player_stats_on_hud["player_points"]
	burst_count.text = "%02d" % player_stats_on_hud["burst_count"]
	skill_count.text = "%02d" % player_stats_on_hud["skill_count"]
	stray_pixels.text = "%03d" % game_data_on_hud["stray_pixels_count"]
	pixels_off.text = "%03d" % game_data_on_hud["off_pixels_count"]
	
	# _temp
	player_life.text = "LIFE: %01d" % player_stats_on_hud["player_life"]
	player_energy.text = "E: %04d" % player_stats_on_hud["player_energy"]
		
		
func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)


# COLORS ---------------------------------------------------------------------------------------------------------------------------

var picked_indicator_alpha: float = 1
var unpicked_indicator_alpha: float = 0.2
var neighbour_indicator_alpha: float = 0.4

func spawn_color_indicators(available_colors): # ukaz pride iz GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	for color in available_colors:
		indicator_index += 1 
		
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		new_color_indicator.modulate.a = unpicked_indicator_alpha
		indicator_holder.add_child(new_color_indicator)
		
		active_color_indicators.append(new_color_indicator)
			
		# zapis indexa ... debugging
		# new_color_indicator.get_node("IndicatorCount").text = str(indicator_index) 
	
	
func color_picked(picked_pixel_color):
	
	# picked color stats
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	# color effects
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
		elif Profiles.game_rules["pick_neighbour_mode"]: # efekt na preostalih barvah 
			indicator.modulate.a = unpicked_indicator_alpha
			
	if Profiles.game_rules["pick_neighbour_mode"]:	# opredelitev sosedov glede na položaj pobrane barve
		
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
		# na začetku holderja indikatorjev 
		if current_indicator_index == 0:		
			active_color_indicators[next_indicator_index].modulate.a = neighbour_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		# na koncu holderja indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
			active_color_indicators[prev_indicator_index].modulate.a = neighbour_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color] # pošljem sosednje barve v GM
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
			active_color_indicators[next_indicator_index].modulate.a = neighbour_indicator_alpha
			active_color_indicators[prev_indicator_index].modulate.a = neighbour_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		
	# izbris iz aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_deathmode_active() -> void:
	Global.game_manager.deathmode_active = true


func _on_GameTimer_gametime_is_up() -> void:
	Global.game_manager.game_over(Global.reason_time)
