extends Control

@export_range(0.0, 100.0, 0.1) var ba_float_amplitude: float = 15.0
@export_range(0.0, 100.0, 0.1) var kyun_float_amplitude: float = 5.0
@export_range(0.1, 10.0, 0.01) var float_speed: float = 1.6
@export_range(0.0, TAU, 0.01) var phase_offset: float = PI * 0.65

var char_float_amplitude: float = 5.0

@onready var sky = $Sky
@onready var subway = $Subway
@onready var char =$Char

var _time_accum: float = 0.0
var _sky_position: Vector2
var _subway_position: Vector2
var _char_position: Vector2

func _ready() -> void:
	_sky_position = sky.position
	_subway_position = subway.position
	_char_position = char.position
	
func _process(delta: float) -> void:
	_time_accum += delta
	sky.position.y = _sky_position.y + sin(_time_accum * float_speed + phase_offset) * ba_float_amplitude
	sky.position.x = _sky_position.x + sin(_time_accum * float_speed + phase_offset) * ba_float_amplitude
	subway.position.y = _subway_position.y + sin(_time_accum * float_speed + phase_offset) * kyun_float_amplitude
	char.position.y = _char_position.y + sin(_time_accum * float_speed + phase_offset) * char_float_amplitude
