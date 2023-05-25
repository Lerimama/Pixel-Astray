extends Control

# ta node more bit na vrhu zaradi zaporedja nalaganja

var player_stats: Dictionary
var game_stats: Dictionary

# player hud
onready var player_life: Label = $Life
onready var player_points: Label = $Points
onready var skill_change_count: Label = $SkilChangeCount
onready var cells_travelled: Label = $CellsTravelled
onready var color_sum: Label = $ColorSum/Value

# pixli
onready var stray_pixels: Label = $PixelsStray
onready var black_pixels: Label = $PixelsHome

# pobrana barva pixla
var new_picked_color: Color = Color.black setget _new_color_picked
onready var picked_color_rect: ColorRect = $PickedColor/ColorBox/ColorRect
onready var picked_color_label: Label = $PickedColor/Value

# spektrum
onready var color_spectrum: VBoxContainer = $ColorSpectrum
var color_indicator_width: float = 12 # ročno setaj pravilno
var color_indicators: Array = []
onready var ColorIndicator: PackedScene = preload("res://scenes/ColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $ColorSpectrumLite/IndicatorHolder

# štopanje
onready var start_game_time setget _start_timing
onready var game_time: Control = $GameTime



func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko
#	visible = false
	color_spectrum = Global.color_indicator_parent


func _process(delta: float) -> void:
	
	if Global.game_manager.game_is_on:
		
		if not visible:
			visible = true
		
		player_stats = Global.game_manager.new_player_stats
		game_stats = Global.game_manager.new_game_stats
		
		# pixel stats
		skill_change_count.text = "SKILL CHANGES: %04d" % player_stats["skill_change_count"]
		cells_travelled.text = "CELLS TRAVELLED: %04d" % player_stats["cells_travelled"]
		
		# game stats
		player_life.text = "LIFE: %s" % game_stats["player_life"]
		player_points.text = "POINTS: %04d" % game_stats["player_points"]
		
#		color_sum.text = str(Global.game_manager.player_color_sum_r) + " " + str(Global.game_manager.player_color_sum_g3) + " " + str(Global.game_manager.player_color_sum_b)
		
		stray_pixels.text = "PIXELS ASTRAY: %02d" % game_stats["stray_pixels"]
		black_pixels.text = "BLACK PIXELS: %02d" % game_stats["black_pixels"]

	else:
		if visible:
#			hud_control.visible = false
			pass
		

func spawn_color_indicator(position_x,selected_color_position_y, selected_color): 

# ukaz ob spawnanju iz GM
	var new_color_indicator = ColorIndicator.instance()
	new_color_indicator.rect_position.x = position_x
	new_color_indicator.rect_position.y = selected_color_position_y
	new_color_indicator.color = selected_color
	indicator_holder.add_child(new_color_indicator)
	color_indicators.append(new_color_indicator)


func _start_timing(start_time):
	game_time.restart_timer(start_time)


func _new_color_picked(picked_pixel_color):
	erase_color_indicator(picked_pixel_color)
	picked_color_rect.color = picked_pixel_color
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	
func erase_color_indicator(erase_color):
	
	var black_indicator_index: int

	
	for indicator in color_indicators:
		if indicator.color == erase_color:
#			indicator.queue_free()
			indicator.modulate = Color.black
			black_indicator_index = color_indicators.find(indicator)
#			indicator.modulate.a = 0

			# setamo available colors 
			break

	black_indicator_index = color_indicators.find(erase_color)
	color_indicators[black_indicator_index].modulate = Color.black

	var next_indicator_index: int = black_indicator_index - 1
	var prev_indicator_index: int = black_indicator_index + 1
	
	printt("indicator_available:", prev_indicator_index, black_indicator_index, next_indicator_index)
	printt("size:", color_indicators.size())
	
	if black_indicator_index == 0:		
		color_indicators[next_indicator_index].modulate.a = 0.2
	elif black_indicator_index == color_indicators.size():		
		color_indicators[prev_indicator_index].modulate.a = 0.2
#		color_indicators.erase(indicator)
	elif black_indicator_index > 0 and black_indicator_index < (color_indicators.size() - 1):
		color_indicators[next_indicator_index].modulate.a = 0.2
		color_indicators[prev_indicator_index].modulate.a = 0.2
	
	color_indicators.erase(color_indicators[black_indicator_index])

func erase_all_indicators():
	if not color_indicators.empty():
		for indicator in color_indicators:
			indicator.queue_free()
		color_indicators = []
	

func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true


func _on_GameTime_gametime_is_up() -> void:
	Global.game_manager.end_game()
