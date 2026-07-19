extends Control

@export var phone_node_path: NodePath = NodePath("Phone")
@export var background_node_path: NodePath = NodePath("Background")
@export var map_manager_node_path: NodePath = NodePath("MapManager")

@export var phone_float_amplitude: float = 10.0
@export var background_float_amplitude: float = 8.0
@export var phone_float_speed: float = 4
@export var background_float_speed: float = 0.5
@export var background_phase_offset: float = 0.25
@export_range(0.0, 1.0, 0.01) var background_scale_padding: float = 0.06

@onready var sky = $Sky
@onready var cloud = $Cloud
@onready var sea = $Sea
@onready var city = $City
@onready var map = get_node_or_null("MapManager")
@onready var phone = get_node_or_null("CanvasLayer/Phone")

#@export var phone_float_amplitude := 6.0
#@export var phone_float_speed := 1.2

@export var sky_float_amplitude := 3.0
@export var cloud_float_amplitude := 5.0
@export var sea_float_amplitude := 4.0
@export var city_float_amplitude := 2.0

@export var sky_float_speed := 0.4
@export var cloud_float_speed := 0.6
@export var sea_float_speed := 0.8
@export var city_float_speed := 0.5

@export var sky_parallax := 4.0
@export var cloud_parallax := 8.0
@export var sea_parallax := 10.0
@export var city_parallax := 14.0
@export var map_parallax := 16.0
@export var phone_parallax := 20.0

@export var parallax_smoothing := 6.0

var _phone_node: Control
var _background_node: Node2D
var _map_manager_node: Control
var _phone_base_position: Vector2
var _background_base_position: Vector2
var _map_manager_base_position: Vector2
var _background_base_scale: Vector2

var sky_base_position: Vector2
var cloud_base_position: Vector2
var sea_base_position: Vector2
var city_base_position: Vector2

func _ready():
	
	if (AudioManager.is_bgm_playing() == false or (AudioManager.get_current_bgm_path() != "res://music/bgm/menu/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 03 Kind Girl, Honest Girl.mp3" and AudioManager.get_current_bgm_path() != "res://assets/music/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 03 Kind Girl, Honest Girl.mp3" and AudioManager.get_current_bgm_path() != "res://music/bgm/hitoribocchi/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 10 Going Home - Monologue (Finale).wav")) :
		AudioManager.play_bgm("res://music/bgm/level/Cecily Renns - Blast Damage Days Soundtrack - 12 Kill the Band (Clean).ogg", 1, false, false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_phone_node = get_node_or_null(phone_node_path) as Control
	_background_node = get_node_or_null(background_node_path) as Node2D
	_map_manager_node = get_node_or_null(map_manager_node_path) as Control

	if _phone_node != null:
		_phone_base_position = _phone_node.position
	if _background_node != null:
		_background_base_position = _background_node.position
		_background_base_scale = _background_node.scale
		var scale_mul := 1.0 + maxf(background_scale_padding, 0.0)
		_background_node.scale = _background_base_scale * scale_mul
	if _map_manager_node != null:
		_map_manager_base_position = _map_manager_node.position
		
	sky_base_position = sky.position
	cloud_base_position = cloud.position
	sea_base_position = sea.position
	city_base_position = city.position

func _process(_delta: float):
	var viewport_size = get_viewport_rect().size
	var mouse = get_viewport().get_mouse_position()
	var mouse_offset = (mouse - viewport_size * 0.5) / (viewport_size * 0.5)
	
	var t = Time.get_ticks_msec() * 0.001
	
	var sky_float = sin(t * sky_float_speed) * sky_float_amplitude

	var sky_target = sky_base_position
	sky_target += mouse_offset * sky_parallax
	sky_target.y += sky_float

	sky.position = sky.position.lerp(
		sky_target,
		_delta * parallax_smoothing
	)
	
	var cloud_float = sin(t * cloud_float_speed + 0.6) * cloud_float_amplitude

	var cloud_target = cloud_base_position
	cloud_target += -mouse_offset * cloud_parallax
	cloud_target.y += cloud_float

	cloud.position = cloud.position.lerp(
		cloud_target,
		_delta * parallax_smoothing
	)
	
	var sea_float = sin(t * sea_float_speed + 1.2) * sea_float_amplitude

	var sea_target = sea_base_position
	sea_target += mouse_offset * sea_parallax
	sea_target.y += sea_float

	sea.position = sea.position.lerp(
		sea_target,
		_delta * parallax_smoothing
	)
	
	var city_float = sin(t * city_float_speed + 1.8) * city_float_amplitude

	var city_target = city_base_position
	city_target += mouse_offset * city_parallax
	city_target.y += city_float

	city.position = city.position.lerp(
		city_target,
		_delta * parallax_smoothing
	)
	
	if _map_manager_node != null:
		var map_float = sin(t * 1.0 + 0.9) * 3.0
		var map_target = _map_manager_base_position
		map_target += mouse_offset * map_parallax
		map_target.y += map_float
		_map_manager_node.position = _map_manager_node.position.lerp(
			map_target,
			_delta * parallax_smoothing
		)
	
	if _phone_node != null:
		var phone_float = sin(t * phone_float_speed) * phone_float_amplitude
		var phone_target = _phone_base_position
		phone_target += -mouse_offset * phone_parallax
		phone_target.y += phone_float
		_phone_node.position = _phone_node.position.lerp(
			phone_target,
			_delta * parallax_smoothing
		)
	
	#if _phone_node != null:
		#_phone_node.position = _phone_base_position + Vector2(0.0, sin(t * phone_float_speed) * phone_float_amplitude)
	#if _background_node != null:
		#var bg_float_y := sin(t * background_float_speed + background_phase_offset) * background_float_amplitude
		#_background_node.position = _background_base_position + Vector2(0.0, bg_float_y)
		#if _map_manager_node != null:
			#_map_manager_node.position = _map_manager_base_position + Vector2(0.0, bg_float_y)
