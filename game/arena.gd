extends Node2D


onready var free_positions_grid: Node2D = $FreePositions
onready var arena_environment: WorldEnvironment = $ArenaEnvironment


func _ready() -> void:

	Global.game_arena = self

	if not Profiles.debug_mode:
		free_positions_grid.hide()
