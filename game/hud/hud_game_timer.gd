extends Control


signal sudden_death_active # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

var current_second: int # trenutna sekunda znotraj minutnega kroga ... ia izpis na uri
var game_time: int # čas v tajmerju v sekundah
var game_time_limit: float # podatki glede časovnih omejitev se pošljejo iz GM-ja
var time_since_start: float # ne glede na mode, vedno želiš vedet koliko sekund je porabljeno od začetka ... za statistiko

onready var time_limit: int = Global.game_manager.game_data["game_time_limit"]
onready var sudden_death_limit: int = Global.game_manager.game_settings["sudden_death_limit"]
onready var countdown_mode: bool = Global.game_manager.game_settings["timer_mode_countdown"]
onready var gameover_countdown_duration: int = Global.game_manager.game_settings["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip


func _ready() -> void:
	
	modulate = Global.color_white
	
	# display pred štartom
	if countdown_mode:
		$Mins.text = "%02d" % (time_limit / 60)
		$Secs.text = "%02d" % (time_limit % 60)

	time_since_start = 0


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
	
		# activate sudden_death
		if Global.game_manager.game_settings["suddent_death_mode"]:
			if game_time > sudden_death_limit:
				modulate = Global.color_white
			elif game_time == sudden_death_limit:
				emit_signal("sudden_death_active") # pošlje se v hud, ki javi game managerju		
			elif game_time < sudden_death_limit:
				modulate = Global.color_red
		
	else:
		if game_time >= game_time_limit: # ker uravnavam s časom, ki je PRETEKEL
			stop_timer()
			emit_signal("gametime_is_up")		
		
		# activate sudden_death_active
		if Global.game_manager.game_settings["suddent_death_mode"]:
			if game_time < game_time_limit - sudden_death_limit:
				modulate = Global.color_white
			elif game_time == game_time_limit - sudden_death_limit:
				emit_signal("sudden_death_active") # pošlje se v hud, ki javi game managerju		
			elif game_time > game_time_limit - sudden_death_limit:
				modulate = Global.color_red
	
	
func start_timer():
	
	modulate = Global.color_white
	
	game_time_limit = time_limit
	
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
	
	time_since_start += 1
	
	if countdown_mode:
		game_time -= 1
		# game over countdown
		if game_time < 1:
			Global.sound_manager.play_sfx("countdown_b")
			modulate = Global.color_red
		elif game_time <= gameover_countdown_duration and game_time > 0:
			Global.sound_manager.play_sfx("countdown_a")
			modulate = Global.color_red
	else:
		game_time += 1
		# game over countdown
		if game_time > game_time_limit - 1:
			Global.sound_manager.play_sfx("countdown_b")
			modulate = Global.color_red
		elif game_time >= game_time_limit - gameover_countdown_duration:
			Global.sound_manager.play_sfx("countdown_a")
			modulate = Global.color_red

	
	
