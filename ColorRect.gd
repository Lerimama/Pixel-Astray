extends TextureRect

#
#onready var color_rect_1: ColorRect = $"../ColorRect"
#onready var color_rect_2: ColorRect = $"../ColorRect2"
#onready var color_rect_3: ColorRect = $"../ColorRect3"
#onready var color_rect_4: ColorRect = $"../ColorRect4"
#onready var color_rect_5: ColorRect = $"../ColorRect5"
#
#onready var SpectrumColorIndicator: PackedScene = preload("res://scenes/SpectrumColorIndicator.tscn")
#onready var ghost: PackedScene = preload("res://scenes/PixelGhost.tscn")
#
#var sections_count = 32
#
#onready var tekstura = texture
#
#onready var color_spectrum: VBoxContainer = $"../UI/HUD/HudControl/ColorSpectrum"
#onready var indicator_holder: Control = $"../UI/HUD/HudControl/ColorSpectrum/IndicatorHolder"
#
#
#var rectangles = []
#func _ready():
#	var img = texture.get_data()
#	img.lock()
#
#
#	sections_count = clamp(sections_count, 1, sections_count)			
#
#
#	var texture_width = rect_size.x
#	var section_size = texture_width / sections_count
#	var pixel_skip_size = texture_width / (sections_count - 1)
##	var pixel_skip_size = texture_width / clamp(sections_count - 1, 1, 5)
#
#	var new_colors = []
#
#
#	var section_loop_count = 0
#	for section in sections_count:
#
##		var pixel_location = section_loop_count * section_size	
#		var pixel_location = section_loop_count * pixel_skip_size
#		pixel_location = clamp(pixel_location, 1, texture_width - 16)			
#		var new_color = img.get_pixel(pixel_location,0)
#		new_colors.append(new_color)
#
#		spawn_color_indicator(round(pixel_location), section_size, new_color)
#
#
#
#		var rect_to_change = rectangles[section_loop_count]
#
#
#		rect_to_change.color = new_color
#		rect_to_change.rect_position = Vector2(pixel_location,-32)
##		rect_to_change.rect_size.x = section_size
#
#		section_loop_count += 1
#		print(round(pixel_location))
#		print(texture_width)
##		print(new_colors)
#
#
##	print ("texture_width ", texture_width)
##	img.crop(20, 30)
#
#
#func spawn_color_indicator(position_x, size_x, selected_color):
#
#	var new_color_indicator = SpectrumColorIndicator.instance()
##	new_color_indicator.rect_size.x = size_x
##	new_color_indicator.rect_size.y = 16
#	new_color_indicator.rect_position.x = position_x
#	new_color_indicator.color = selected_color
##	if new_color_indicator.get_parent():
##	    new_color_indicator.get_parent().remove_child(new_color_indicator)
#	indicator_holder.add_child(new_color_indicator)
#	rectangles.append(new_color_indicator)
##
##	printt("spawn ", location, size_x, selected_color, new_color_indicator, new_color_indicator.rect_position)
#	printt("spawn ", position_x, size_x, selected_color,get_parent())
