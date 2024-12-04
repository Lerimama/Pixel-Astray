extends HBoxContainer


var energy: int setget _on_amount_change # energija je konveratana v razmerju velikosti bara
var previous_energy: int # preverjam smer spremembe lajfa

onready var texture_progress: TextureProgress = $TextureProgress


func _ready() -> void:

	modulate = Global.color_hud_text
	set_icons_state() # preveri energijo na začetku in seta pravilno stanje ikon


func _on_amount_change(new_value: int):

	# setam prev energy ... prava energija se še ni spremenila
	previous_energy = energy
	# setam current energy
	energy = new_value

	if energy <= Global.hud.tired_energy_limit:
		modulate = Global.color_red
	else:
		if energy < previous_energy:
			#var blink_tween = get_tree().create_tween()
			#blink_tween.tween_property(self, "modulate", Global.color_red, 0.2)
			#blink_tween.tween_property(self, "modulate", Global.color_hud_text, 0.2)
			pass # ne barvam, ker je pol skos rdeča
		elif energy > previous_energy:
			modulate = Global.color_green
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate", Global.color_green, 0.2)
			blink_tween.tween_property(self, "modulate", Global.color_hud_text, 0.2)

	set_icons_state()


func set_icons_state():

	texture_progress.value = energy
