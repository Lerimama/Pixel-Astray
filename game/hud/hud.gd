extends Control


# ta node more bit na vrhu zaradi zaporedja nalaganja
var player_stats_on_hud: Dictionary
var game_stats_on_hud: Dictionary

var fade_time: float = 1
var default_hud_color: Color = Color.white

# spectrum indicators
var active_color_indicators: Array = []
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var indicator_holder: HBoxContainer = $Footer/ColorSpectrumLite/IndicatorHolder

#header
onready var header: Control = $Header
onready var player_life: Label = $Life # _temp, pravi je na samih ikonah
onready var player_energy: Label = $Energy # temp
onready var player_points: Label = $Header/HudLine_TL/PointsCounter/Points
onready var cells_travelled: Label = $Header/HudLine_TL/CellCounter/CellsTravelled
onready var skills_used: Label = $Header/HudLine_TL/SkillCounter/SkillsUsed
onready var game_timer: HBoxContainer = $Header/GameTimer
onready var level: Label = $Header/Level
onready var highscore_label: Label = $Header/Highscore
onready var music_label: Label = $Header/MusicLabel
onready var on_icon: TextureRect = $Header/MusicLabel/OnIcon
onready var off_icon: TextureRect = $Header/MusicLabel/OffIcon

#futer
onready var footer: Control = $Footer
onready var picked_color_rect: ColorRect = $Footer/PickedColor/ColorRect
onready var picked_color_label: Label = $Footer/PickedColor/Value
onready var pixels_off_counter = $Footer/HudLine_TR/OffedCounter
onready var pixels_off: Label = $Footer/HudLine_TR/OffedCounter/PixelsOff
onready var stray_pixels_counter = $Footer/HudLine_TR/StrayCounter
onready var stray_pixels: Label = $Footer/HudLine_TR/StrayCounter/PixelsStray

# popups 
var close_to_highscore_part = 0.85 # procent HS vrednosti
var highscore_broken: bool =  false
var highscore_broken_popup_time: float = 2
onready var highscore_close_popup: Label = $Popups/HSClose
onready var highscore_broken_popup: Control = $Popups/HSBroken


func _ready() -> void:
	
	Global.hud = self
	
#	color_spectrum = Global.color_indicator_parent

	# skrij statistiko in popupe
	visible = false
	highscore_close_popup.visible = false
	highscore_broken_popup.visible = false
	

func _process(delta: float) -> void:
	
	
	player_stats_on_hud = Global.game_manager.player_stats
	game_stats_on_hud = Global.game_manager.game_stats
	
	writing_stats()
	
	
	if not highscore_broken and Global.game_manager.game_on:
		checking_highscore()
	elif not Global.game_manager.game_on:
		highscore_close_popup.visible = false
	
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
		
		
func checking_highscore():
	
	var current_highscore = game_stats_on_hud["highscore"]
	var current_points = player_stats_on_hud["player_points"]
	var close_to_highscore_limit: float = abs(current_highscore * close_to_highscore_part)
	
	
	# rekord!!! ... zaporedje ifov je pomembno zaradi načina setanja pogojev
	if current_points > current_highscore:
		Global.sound_manager.play_sfx("record_cheers")
		highscore_broken = true
		highscore_label.modulate = Global.color_green
		
		highscore_close_popup.visible = false
		highscore_broken_popup.visible = true
		yield(get_tree().create_timer(highscore_broken_popup_time), "timeout")
		highscore_broken_popup.visible = false
	
	# blizu rekorda
	elif current_points >= close_to_highscore_limit or current_points == current_highscore:
		highscore_label.modulate = Global.color_blue
		highscore_close_popup.visible = true
	
	# blah ... še ni uspeha
	elif current_points < close_to_highscore_limit:
		highscore_close_popup.visible = false
		highscore_broken_popup.visible = false
		highscore_label.modulate = default_hud_color
		

func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)


# COLORS ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(colors): 
# ukaz pride iz GM

	for color in colors:
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		indicator_holder.add_child(new_color_indicator)
		# zapis indexa ... invisible ... za debug
		var indicator_index = active_color_indicators.find(new_color_indicator)
		new_color_indicator.get_node("Label").text = str(indicator_index)
		active_color_indicators.append(new_color_indicator)
	
	
func color_picked(picked_pixel_color):
	
	erase_color_indicator(picked_pixel_color)
	
	# picked color stats
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	# color effects
	picked_color_rect.color = picked_pixel_color
	
	picked_color_label.modulate = picked_pixel_color
	pixels_off_counter.modulate = picked_pixel_color
	stray_pixels_counter.modulate = picked_pixel_color
	yield(get_tree().create_timer(0.5), "timeout")
	picked_color_label.modulate = default_hud_color
	pixels_off_counter.modulate = default_hud_color
	stray_pixels_counter.modulate = default_hud_color
	
	
func erase_color_indicator(erase_color):
	
	# index indikatorja pobrane barve (prepoznan po enaki barvi)
	var current_indicator_index: int
	for indicator in active_color_indicators:
		if indicator.color == erase_color:
			current_indicator_index = active_color_indicators.find(indicator)
			if Profiles.game_rules["pick_neighbour_mode"]:
				indicator.modulate.a = 0
			else:
				indicator.modulate.a = 0.3
				break
		else:
			if Profiles.game_rules["pick_neighbour_mode"]:
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





