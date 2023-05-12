extends Node


var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	"P1" : { # ključi bodo kasneje samo indexi
		"player_name" : "Moe",
		"player_color" : Config.color_blue, # color_yellow, color_green, color_red
		"controller_profile" : "ARROWS",
	},
	"P2" : {
		"player_name" : "Zed",
		"player_color" : Config.color_red,
		"controller_profile" : "WASD",
	},
	"P3" : {
		"player_name" : "Dot",
		"player_color" : Config.color_yellow, # color_yellow, color_green, color_red
		"controller_profile" : "JP1",
	},
	"P4" : {
		"player_name" : "Jax",
		"player_color" : Config.color_green,
		"controller_profile" : "JP2",
	},
}

var default_player_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"player_active" : true,
	"life" : 3,
	"points" : 0,
	"color_sum" : 0,
	"colors_picked" : 0,
	"color_change_count" : 0,
}

var default_game_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"game_time" : 90, # sekund
	"colors_left" : 0,
	"stray_pixels" : 0,
	"black_pixels" : 0,
}

var pixel_profiles: Dictionary = {
	"nn": 0,
}

var stray_pixel_profile: Dictionary = {
	"nn": 0,
}

enum Levels {SQUARE = 1, CIRCLE, TRIANGLE
}

var default_level_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	Levels.SQUARE: {
		"player_start_position" : Vector2(0, 0),
		"game_time" : 5,
		"level" : 2,
		"stray_pixels_count" : 0.1,
	}
}

