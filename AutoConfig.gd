## KAJ JE ...
## - v tem filetu so vsi prednastavljeni profili igre ... Lastnosti, ki se tekom igre ne spreminjajo
## - vse štartne nastavitve za igro ... props: barve, pravila igre, orožja, funkcije opek ...
## - štart vrednosti vseh elementov v levelih
## - štart pogoji za igro ... game rules
## - defolt vsebine menijev
## - defolt lastnosti rakete (motion, ...)
##
## KAJ NI ...
## - tukaj ni profilov igralcev
## - tukaj ni variabl, ki se se lahko spreminjajo

extends Node


# game groups
var group_players = "Players"
var group_strays = "Strays"
var group_darkers = "Darkers"
var group_tilemap = "Tilemap"

# game colors
var color_white = Color("#ffffff") # najsvetlejša
var color_black = Color("#000000") # najsvetlejša
var color_blue = Color("#4b9fff")
var color_green = Color("#5effa9")
var color_red = Color("#f35b7f")
var color_yellow = Color("#fef98b")


# enums
enum GameStats {PLAYER_POINTS, PLAYER_COLOR, COLORS_PICKED, COLOR_CHANGE_COUNT, SKILL_USE_COUNT, PIXELS_STRAY, PIXELS_HOME, ARENA_COLORS}

#enum GameStats {PLAYER_POINTS, PLAYER_COLOR, ARENA_COLORS, PIXELS_STRAY, PIXELS_HOME}


var bolt_explosion_shake
var bullet_hit_shake
var misile_hit_shake


var color_gray0 = Color("#535b68") # najsvetlejša
var color_gray1 = Color("#404954")
var color_gray2 = Color("#2f3649")
var color_gray3 = Color("#272d3d")
var color_gray4 = Color("#1d212d")
var color_gray5 = Color("#171a23") # najtemnejša

# -------------------------------------------------------------------------------------------------------------
#	GAME VALUES
# -------------------------------------------------------------------------------------------------------------

var default_game_theme : Dictionary = {

	"disabled_player_color" : Color.gray,

	# menus
	"menu_text_color" : Color.white,
	"menu_accent_color" : Color.orange,
	"menu_edit_color" : Color.red, # v rabi v controller meniju
	"menu_colorsq_size" : Vector2(40, 40),
	"menu_colorsq_select_size" : Vector2(24, 24),

	#hud
	"icon_color" : Color.palegoldenrod,
	"label_color" : Color.pink,
	"minus_color" : Color.red,
	"plus_color" : Color.green, # drugačna ker se to zgodi na bonus efekt
	}

var game_rules : Dictionary = {

	# player_default_values diki?

	"score for win" : Color.red,
	"wins for turnament win" : Color.red,
	}

var level_values : Dictionary = { # tale bo na koncu obsoleten, al bo za drzgam?

	# e bonus
	"energy_bonus" : 10,
	"bonus_e_color" : Color.yellow,
	# m bonus
	"misile_bonus" : 1,
	"bonus_m_color" : Color.pink,

	# pointer
	"pointer_points" : 100,
	"pointer_color" : Color.aquamarine,
	"pointer_brake" : 3,
	# exploder
	"exploder_color_1" : Color.purple,
	"exploder_color_2" : Color.pink,
	"exploder_color_3" : Color.white,
	# bonucer
	"bouncer_color" : Color.violet,
	"bouncer_strenght" : 2,
	# magnet
	"magnet_color" : Color.aquamarine, # !!!! float
	"gravity_velocity" : 3.0, 	# hitrost glede na distanco od magneta ...gravitacijski pospešek	!!!! float
	"gravity_force" : 50000.0, 	# sila gravitacije 		!!!!!!!const

	}

