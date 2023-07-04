extends Node

	
	
	
	
# -------

# OLD COLLISIONS 
	
#	if body.is_in_group(Config.group_tilemap):
		
#		speed = 0
#		if body.is_in_group(Config.group_pixels):
#
#			# poberi trenutni seštevek barv
#			var current_color_sum = state_colors[current_state]
#
#			# change pixel
#			speed = 0
#			_change_state(States.WHITE)
#
#			# poberi barvo pixla
#			var picked_color = body.modulate
#			picked_color_rect.color = picked_color
#
#			# picked color
#			var rgb_red: float = picked_color.r * 255
#			var rgb_green: float = picked_color.g * 255
#			var rgb_blue: float = picked_color.b * 255
#			var display_red: String = "%03d" % rgb_red
#			var display_green: String = " %03d" % rgb_green
#			var display_blue: String = " %03d" % rgb_blue
#
#			# v hud
#			color_value.text = display_red + display_green + display_blue
#
#			# skupna barva
#			pixel_color_sum = current_color_sum + picked_color # statistika jo pobere
#
#			# za hud
#			var pixel_color_sum_values = Color(pixel_color_sum)
#			pixel_color_sum_r = round(pixel_color_sum_values.r * 255)
#			pixel_color_sum_g = round(pixel_color_sum_values.g * 255)
#			pixel_color_sum_b = round(pixel_color_sum_values.b * 255)
#			Global.game_manager.player_color_sum_r = pixel_color_sum_r
#			Global.game_manager.player_color_sum_g = pixel_color_sum_g
#			Global.game_manager.player_color_sum_b = pixel_color_sum_b
#			print("pixel_color_sum_values", pixel_color_sum_values, pixel_color_sum_r, pixel_color_sum_g, pixel_color_sum_b)
#
#			# player color
#			modulate = pixel_color_sum
#
#			# stray disabled
##			body.current_state = body.States.BLACK
##			body.turn_off() # stray javi svojo smrt v hud
#			body.queue_free()
#
#			printt("prev color sum", current_color_sum)
#			printt("picked color", body.state_colors[body.current_state])
#			printt("new color sum", pixel_color_sum)
#			# seštej in zabeleži v statistiko
#
##		else:	
##			explode_pixel()


# -------

#func turn_off():
#
#	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
#	new_tween.tween_property(self, "modulate:a", 0, 3)
#	new_tween.tween_callback(self, "die")
#
#
#func die():
#	# pošljem barvo
##	emit_signal("stat_changed", "black_pixels", 1) 
#
#	# pošljem turnoff
#	emit_signal("stat_changed", self, "black_pixels", 1) # owner je v tem primeru nepomemben ... zato ga ni
#	print("strey kvfrid")
#	queue_free()
