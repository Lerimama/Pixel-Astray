extends HBoxContainer


var life_count: int setget _on_value_change
var previous_life: int # preverjam smer spremembe lajfa

onready var life_icon: Control = $LifeIcon
onready var life_icons: Array = get_children()


func _ready() -> void:
	
	set_icons_state() # preveri lajf na začetku in seta pravilno stanje ikon 


func _process(delta: float) -> void:
	
	self.life_count = Global.game_manager.player_stats["player_life"]
	
	
func _on_value_change(new_value): # ne rabim parametra
	
	# setam prev life ... pravi_life count se še ni spremenil
	previous_life = life_count
	
	# setam current life
	life_count = new_value # v bistvu Global.game_manager.player_stats["player_life"]
	
	if previous_life > life_count:
		
		modulate = Global.color_red
		yield(get_tree().create_timer(0.5), "timeout")
		modulate = Color.white
	
	elif previous_life < life_count:
		
		modulate = Global.color_green
		yield(get_tree().create_timer(0.5), "timeout")
		modulate = Color.white
	else: # če ni spremembe
		return
	
	set_icons_state()
 

func set_icons_state():
	
	var loop_index: int		
	for icon in life_icons:
		loop_index += 1
		if loop_index >= life_count + 1: # če je ena preveč
			icon.get_node("OnIcon").modulate.a = 0
		else:
			icon.get_node("OnIcon").modulate.a = 1
