extends Control


signal deathmode_active # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

var current_second: int # trenutna sekunda znotraj minutnega kroga ... ia izpis na uri
var game_time: int # čas v tajmerju v sekundah
var game_time_limit: int # podatki glede časovnih omejitev se pošljejo iz GM-ja

onready var deathmode_limit: int = Profiles.game_rules["death_mode_duration"]
onready var level_time_limit: int = Profiles.default_level_stats["game_time_limit"]
onready var countdown_mode: bool = Profiles.game_rules["timer_countdown_mode"]
onready var gameover_countdown_duration: int = Profiles.game_rules["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip


func _ready() -> void:
	modulate = Global.color_white
	
	# display pred štartom
	if countdown_mode:
		$Mins.text = "%02d" % (level_time_limit / 60)
		$Secs.text = "%02d" % (level_time_limit % 60)


func _process(delta: float) -> void:
	
	# če ne štopam se tukaj ustavim
	if $Timer.is_stopped():
		return
	
	# display ko štopa
	current_second = int(game_time) % 60
	$Mins.text = "%02d" % (game_time / 60)
	$Secs.text = "%02d" % current_second
		
	if countdown_mode:
		
		# time is up	
		if game_time <= 0:
			stop_timer()
			current_second = 0
			modulate = Global.color_red
			emit_signal("gametime_is_up") # pošlje se v hud, ki javi game managerju		
	
		# activate deathmode
		if Profiles.game_rules["deathmode_on"]:
			if game_time > deathmode_limit:
				modulate = Global.color_white
			elif game_time == deathmode_limit:
				emit_signal("deathmode_active") # pošlje se v hud, ki javi game managerju		
			elif game_time < deathmode_limit:
				modulate = Global.color_red
		
	else:
		if game_time >= game_time_limit: # ker uravnavam s časom, ki je PRETEKEL
			stop_timer()
			emit_signal("gametime_is_up")		
		
		# activate deathmode
		if Profiles.game_rules["deathmode_on"]:
			if game_time < game_time_limit - deathmode_limit:
				modulate = Global.color_white
			elif game_time == game_time_limit - deathmode_limit:
				emit_signal("deathmode_active") # pošlje se v hud, ki javi game managerju		
			elif game_time > game_time_limit - deathmode_limit:
				modulate = Global.color_red
		
	
	
func start_timer():
	
	modulate = Global.color_white
	
	game_time_limit = level_time_limit
	
	if countdown_mode:
		# če odštevam je začetna številka enaka time limitu v
		game_time = game_time_limit
		# sekunde v obsegu minute
		current_second = game_time % 60
		
		$Mins.text = "%02d" % (game_time / 60)
		$Secs.text = "%02d" % current_second
	else:
		# če prišteam je začetna številka 0
		game_time = 0
		$Mins.text = "00"
		$Secs.text = "00"	
	
	$Timer.start()
	
	
func stop_timer():
	
	$Timer.stop()
	modulate = Global.color_red
		

func _on_Timer_timeout() -> void:

	if countdown_mode:
		game_time -= 1.0
		# game over countdown
		if game_time < 1:
			Global.sound_manager.play_sfx("countdown_b")
		elif game_time <= gameover_countdown_duration and game_time > 0:
			Global.sound_manager.play_sfx("countdown_a")
	else:
		game_time += 1.0
		# game over countdown
		if game_time > game_time_limit - 1:
			Global.sound_manager.play_sfx("countdown_b")
		elif game_time >= game_time_limit - gameover_countdown_duration:
			Global.sound_manager.play_sfx("countdown_a")

	
	
