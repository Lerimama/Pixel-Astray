extends Node
#
#
#var color_count: int = 20
#var color_indicator_width: float = 8 # ročno setaj pravilno
#
#onready var SpectrumColorIndicator: PackedScene = preload("res://scenes/SpectrumColorIndicator.tscn")
#onready var spectrum_rect: TextureRect = $Spectrum
#
#
#var rectangles = []
#
#
#func _ready():
#
#	var spectrum_texture: Texture = spectrum_rect.texture
#	var spectrum_image: Image = spectrum_texture.get_data()
#	var selected_colors: Array = []
#
#	var spectrum_texture_width = spectrum_rect.rect_size.x
#
#	color_count = clamp(color_count, 1, color_count) # za vsak slučaj klempam			
#	var color_skip_size = spectrum_texture_width / (color_count - 1) # razmak barv po spektru
#
#	spectrum_image.lock()
#
#
##	var section_size = spectrum_texture_width / sections_count
##	var pixel_skip_size = texture_width / clamp(sections_count - 1, 1, 5)
#
#
#
#	var loop_count = 0
#	for color in color_count:
#
#
##		var selected_color_position_x = round(loop_count * color_skip_size)
#		var selected_color_position_x = loop_count * color_skip_size
#
#		var selected_color_position_y = 0
#		# enakomerna distribucija pixlov po spektru 
#		if loop_count == 0: # lokacija prvega
#			selected_color_position_x = 0 
#		elif loop_count >= color_count - 1: # lokacija zadnjega
#			selected_color_position_x = spectrum_texture_width - 17
##			selected_color_position_y = 16
#		else:	
#			selected_color_position_x = selected_color_position_x - loop_count 
#		# na koncu poskrbim, da ni čisto enaka uni na začetku			
#
#		# zajem barve na lokaciji pixla
#		var selected_color = spectrum_image.get_pixel(selected_color_position_x, 0)
#		selected_colors.append(selected_color)
#
#		spawn_color_indicator(selected_color_position_x,selected_color_position_y, selected_color)
#
#
#
##		var rect_to_change = rectangles[section_loop_count]
#
#
##		rect_to_change.color = new_color
##		rect_to_change.rect_position = Vector2(pixel_location,-32)
##		rect_to_change.rect_size.x = section_size
#
#		loop_count += 1
##		print(round(pixel_location))
##		print(texture_width)
##		print(new_colors)
#
#
##	print ("texture_width ", texture_width)
##	img.crop(20, 30)
#onready var color_spectrum: VBoxContainer = $"../UI/HUD/HudControl/ColorSpectrum"
#onready var indicator_holder: Control = $"../UI/HUD/HudControl/ColorSpectrum/IndicatorHolder"
#
#func spawn_color_indicator(position_x,selected_color_position_y, selected_color):
#
#	var new_color_indicator = SpectrumColorIndicator.instance()
##	new_color_indicator.rect_size.x = size_x
##	new_color_indicator.rect_size.y = 16
#	new_color_indicator.rect_position.x = position_x
#	new_color_indicator.rect_position.y = selected_color_position_y
#	new_color_indicator.color = selected_color
##	if new_color_indicator.get_parent():
##	    new_color_indicator.get_parent().remove_child(new_color_indicator)
#	indicator_holder.add_child(new_color_indicator)
#	rectangles.append(new_color_indicator)
##
##	printt("spawn ", location, size_x, selected_color, new_color_indicator, new_color_indicator.rect_position)
##	printt("spawn ", position_x, size_x, selected_color,get_parent())
#
#
#	# trail ghosts
##	var new_pixel_ghost = ghost.instance()
##	new_pixel_ghost.global_position = Vector2(0,0)
##	add_child(new_pixel_ghost)
