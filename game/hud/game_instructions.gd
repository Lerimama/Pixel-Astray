extends Control


signal players_ready # za splitscreen popup

onready var title: Label = $Title
onready var description: Label = $Description
onready var outline: = $GameOutline
onready var action_hint_press: Node2D = $ActionHintPress
onready var hint_btn: Button = $ActionHintPress/HintBtn



func _ready() -> void:

	action_hint_press.hide() # zaradi pavze


func open(): # kliče GM set game

#	ready_btn.show() # zaradi pavze

	var current_game_data: Dictionary = Global.game_manager.game_data

	# game title
	if Profiles.tilemap_paths[current_game_data["game"]].size() > 1:
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]

	# description
	description.text = current_game_data["description"]

	outline.get_instructions_content()
	action_hint_press.show()
	hint_btn.grab_focus()
	show() # fade-in se zgodi zaradi game scene

	get_tree().set_pause(true)


func confirm_players_ready():

	get_tree().set_pause(false)

	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira

	var out_time: float = 0.5
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(self, "modulate:a", 0, out_time)#.set_ease(Tween.EASE_IN)
	yield(hide_instructions_popup, "finished")

	emit_signal("players_ready")
	hide()


func _on_HintBtn_pressed() -> void:

	hint_btn.disabled = true
	confirm_players_ready()
	#	Analytics.save_ui_click("ReadyBtn")
