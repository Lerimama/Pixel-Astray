extends Control


signal players_ready # za splitscreen popup

onready var title: Label = $Title
onready var description: Label = $Description
onready var record_label_holder: Panel = $Outline/Record
onready var record_title: Label = $Outline/Record/VBoxContainer/RecordTitle
onready var record_label: Label = $Outline/Record/VBoxContainer/RecordLabel
onready var record_owner: Label = $Outline/Record/VBoxContainer/RecordOwner
onready var outline: = $Outline
onready var shortcuts: Panel = $Outline/Shortcuts
onready var controls: Control = $Outline/Controls
onready var controls_duel_p1: Control = $Outline/ControlsDuelP1
onready var controls_duel_p2: Control = $Outline/ControlsDuelP2
onready var big_btn: Button = $BigButton


func _input(event: InputEvent) -> void:

	if not get_parent().name == "PauseMenu":
		if visible and modulate.a == 1 and Input.is_action_just_pressed("ui_accept"):
			_on_EnterButton_pressed()
	
	
func _ready() -> void:
	
	big_btn.add_to_group(Global.group_menu_confirm_btns)
	big_btn.hide()
	if get_parent().name == "Popups":
		yield(get_tree().create_timer(1), "timeout") # če je klik prehiter se ne nalouda
		big_btn.show()

func open():
	
	Global.allow_focus_sfx = false # urgenca za nek "cancel" sound bug
	
	get_instructions_content()
	show() # fade-in je zaradi fejdina cele scene
	get_tree().set_pause(true)	
			
	yield(get_tree().create_timer(0.1), "timeout")
	Global.allow_focus_sfx = true	
			
				
func get_instructions_content(current_highscore: int = 0, current_highscore_owner: String = "Nobody"):
	
	var current_game_data: Dictionary = Global.game_manager.game_data
	
	# game title
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER: # samo enigam ima številko levela
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]
	
	# description		
	description.text = current_game_data["description"]
	
	# highscore
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:# or current_highscore == 0:
		record_label_holder.hide()
	else:	
		record_label_holder.show()
		record_title.text = "Current record"
		# no record
		if current_highscore == 0:
			record_owner.text = "No record yet ..."
			record_label.hide()
		# time
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			var clock_record: String = Global.get_clock_time(current_highscore)
			record_label.text = clock_record
			record_owner.text = "by " + str(current_highscore_owner)
		# points
		else:
			record_label.text = str(current_highscore) + " points"
			record_owner.text = "by " + str(current_highscore_owner)

	# player controls 			
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		controls.hide()
		controls_duel_p1.show()
		controls_duel_p2.show()
	else:
		controls.show()
		controls_duel_p1.hide()
		controls_duel_p2.hide()
		
	# game props
	for prop in outline.get_children():
		if prop.get_child(0).name == "PropLabel":
			var prop_label: Label = prop.get_node("PropLabel")
			if current_game_data.has(str(prop.name)): # če ima slovar igre to postavko ...
				prop.show()
				prop_label.text = current_game_data["%s" % prop.name] # ... jo napolni z njeno vsebino
			else:
				prop.hide()


func confirm_players_ready():
	
	get_tree().set_pause(false)
	Global.sound_manager.play_gui_sfx("btn_confirm")
	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira (na restart)
	
	var out_time: float = 0.5
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(self, "modulate:a", 0, out_time)#.set_ease(Tween.EASE_IN)
	yield(hide_instructions_popup, "finished")
	
	emit_signal("players_ready")
	hide()
	
	
func _on_EnterButton_pressed() -> void:
	
	big_btn.hide()
	big_btn.rect_size = Vector2.ZERO # da zgine rokca miške
	confirm_players_ready()
	
