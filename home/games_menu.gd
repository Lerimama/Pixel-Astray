extends Control


func check_btns_on_focus(focused_btn: Control, btn_colors):

	var unfocused_background_color = Global.color_almost_black
	var focused_background: Control
	var unfocused_backgrounds: Array

	# klasika
	if focused_btn.name == "CleanerBtn":# or focused_btn.name == "TutorialModeBtn":
		focused_background = $Cleaner/Background
	else:
		$Cleaner/CleanerBtn.modulate = btn_colors[0]
		unfocused_backgrounds.append($Cleaner/Background)

	# erasers

	$Eraser/SBtn.modulate = btn_colors[5]
	$Eraser/MBtn.modulate = btn_colors[6]
	$Eraser/LBtn.modulate = btn_colors[7]
	$Eraser/XLBtn.modulate = btn_colors[8]
	$Eraser/XXLBtn.modulate = btn_colors[9]
	if focused_btn.name == "SBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "MBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "LBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "XLBtn":
		focused_background = $Eraser/Background
	elif focused_btn.name == "XXLBtn":
		focused_background = $Eraser/Background
	else:
		unfocused_backgrounds.append($Eraser/Background)

	# eternals

	$Unbeatables/HunterBtn.modulate = btn_colors[13]
	$Unbeatables/DefenderBtn.modulate = btn_colors[14]
	if focused_btn.name == "HunterBtn":
		focused_background = $Unbeatables/Background
	elif focused_btn.name == "DefenderBtn":
		focused_background = $Unbeatables/Background
	else:
		unfocused_backgrounds.append($Unbeatables/Background)

	# druge
	if focused_btn.name == "SweeperBtn":
		focused_background = $Sweeper/Background
	else:
		$Sweeper/SweeperBtn.modulate = btn_colors[3]
		unfocused_backgrounds.append($Sweeper/Background)

	if focused_btn.name == "TheDuelBtn":
		focused_background = $TheDuel/Background
	else:
		$TheDuel/TheDuelBtn.modulate = btn_colors[11]
		unfocused_backgrounds.append($TheDuel/Background)


	focused_btn.modulate = Color.white

	var focus_time: float = 0.3
	var focus_tween = get_tree().create_tween()
	if focused_background:
		focus_tween.parallel().tween_property(focused_background, "color", Global.color_thumb_hover, focus_time)
	for undi in unfocused_backgrounds:
		focus_tween.parallel().tween_property(undi, "color", unfocused_background_color, focus_time)
