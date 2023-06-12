extends Control

# ta node more bit na vrhu zaradi zaporedja nalaganja

var player_stats: Dictionary
var game_stats: Dictionary

var fade_time: float = 1

# hud
onready var player_life: Label = $Life
onready var player_points: Label = $Points
onready var cells_travelled: Label = $CellsTravelled
onready var skills_used: Label = $SkillsUsed
onready var pixels_off: Label = $PixelsOff
onready var stray_pixels: Label = $PixelsStray
onready var picked_color_rect: ColorRect = $PickedColor/ColorBox/ColorRect
onready var picked_color_label: Label = $PickedColor/Value

# spectrum indicators
#var color_indicator_width: float = 12 # ročno setaj pravilno
var active_color_indicators: Array = []
onready var color_spectrum: VBoxContainer = $ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://scenes/game/HudColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $ColorSpectrumLite/IndicatorHolder

# štopanje
#onready var timer_on: bool = false setget _start_timer
onready var game_time: Control = $GameTime


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko
	visible = false
	color_spectrum = Global.color_indicator_parent


func _process(delta: float) -> void:
		
	player_stats = Global.game_manager.player_stats
	game_stats = Global.game_manager.game_stats
	
	# pixel stats
	skills_used.text = "SKILLS USED: %04d" % player_stats["skills_used"]
	cells_travelled.text = "CELLS TRAVELLED: %04d" % player_stats["cells_travelled"]
	player_life.text = "LIFE: %s" % player_stats["player_life"]
	player_points.text = "POINTS: %04d" % player_stats["player_points"]
	
	# game stats
	stray_pixels.text = "PIXELS ASTRAY: %02d" % game_stats["stray_pixels_count"]
	pixels_off.text = "%02d /" % game_stats["off_pixels_count"]


func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)
	
	
func start_timer():
	
	game_time.restart_timer(Profiles.game_rules["game_time"])


# colors

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
	picked_color_rect.color = picked_pixel_color
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	
func erase_color_indicator(erase_color):
	
	# index indikatorja pobrane barve (prepoznan po enaki barvi)
	var current_indicator_index: int
	for indicator in active_color_indicators:
		if indicator.color == erase_color:
			current_indicator_index = active_color_indicators.find(indicator)
			if Global.game_manager.pick_neighbour_mode:
				indicator.modulate.a = 0
			else:
				indicator.modulate.a = 0.3
				break
		else:
			if Global.game_manager.pick_neighbour_mode:
				indicator.modulate.a = 0.5
			
	if Global.game_manager.pick_neighbour_mode:	
		# opredelitev sosedov glede na položaj pobrane barve
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		# indexi onbeh sosednjih indikatorjev
		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
	#	for indicator in active_color_indicators:
			
		# na začetku živih indikatorjev 
		if current_indicator_index == 0:		
	#		active_color_indicators[next_indicator_index].get_node("Line").visible = true
			active_color_indicators[next_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color]
		# na koncu živih indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
	#		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color]
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
	#		active_color_indicators[next_indicator_index].get_node("Line").visible = true
	#		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
			active_color_indicators[next_indicator_index].modulate.a = 1
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color]
		
	# izbris iz arraya živih indikatorjev
	active_color_indicators.erase(active_color_indicators[current_indicator_index])
	

#func erase_all_indicators(): ... zaenkrat ne rabim nikjer
#	if not active_color_indicators.empty():
#		for indicator in active_color_indicators:
#			indicator.queue_free()
#		active_color_indicators = []
	
	
# deathmode

func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true


func _on_GameTime_gametime_is_up() -> void:
	Global.game_manager.game_over()
