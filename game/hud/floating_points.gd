extends Node2D


var tag_owner: Node
var cell_size_x: float = Global.game_tilemap.cell_size.x

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var label: Label = $Tag/Label


func _ready() -> void:

	modulate.a = 1
	animation_player.play("show_tag")
	# KVEFRI je v animaciji

func _physics_process(delta: float) -> void:
	
	global_position = tag_owner.global_position - Vector2(cell_size_x/2, cell_size_x)# + cell_size_x/2)
