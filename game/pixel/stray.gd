extends Stray


func _ready() -> void:
	# namen: xtra pucanje na prehodu v level
	
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	
	if Global.game_manager.level_upgrade_in_progress: # puca tiste ekstra, ki ne vem zakaj ostanejo
		Global.game_manager.strays_in_game_count = - 1
		queue_free()
	
	color_poly.modulate = stray_color
	modulate.a = 0
	position_indicator.get_node("PositionPoly").color = stray_color
	count_label.text = name
	position_indicator.visible = false
