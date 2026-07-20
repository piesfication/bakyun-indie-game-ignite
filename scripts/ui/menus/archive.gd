extends Control

@onready var sky = $Node2D/Background
@onready var  sea = $Node2D/Sea
@onready var base = $Node2D/Base
@onready var char = $Node2D/Char
@onready var tv = $CanvasLayer/TV
@onready var visual = $Node2D

@export var sky_float_amplitude: float = 4.0
@export var sky_float_speed: float = 0.4
@export var sea_float_amplitude: float = 3.0
@export var sea_float_speed: float = 3
@export var tv_float_amplitude: float = 11.0
@export var tv_float_speed: float = 1.5
@export var visual_float_amplitude: float = 3.0
@export var visual_float_speed: float = 3

@export var sky_phase_offset: float = 0.25

@export_range(0.0, 1.0, 0.01) var background_scale_padding: float = 0.06

var sky_base_position: Vector2
var sea_base_position: Vector2
var tv_base_position: Vector2
var visual_base_position: Vector2

@onready var album_layer = $AlbumLayer

@onready var album_button = $CanvasLayer/TV/Visual/AlbumButton
@onready var close_album_button = $AlbumLayer/AlbumMenu/DescriptionBox/CloseButton

@export var sky_parallax_strength := 6.0
@export var sea_parallax_strength := 8.0
@export var tv_parallax_strength := 10.0
@export var visual_parallax_strength := 0.0

@export var base_parallax_strength := 2.0
@export var char_parallax_strength := 12.0

@export var base_float_amplitude := 2.0
@export var base_float_speed := 0.8

@export var char_float_amplitude := 5.0
@export var char_float_speed := 1.2

var base_base_position: Vector2
var char_base_position: Vector2

@export var parallax_smoothing := 6.0

func _ready():

	album_layer.visible = false
	sky_base_position = sky.position
	sea_base_position = sea.position
	tv_base_position = tv.position
	visual_base_position = visual.position
	base_base_position = base.position
	char_base_position = char.position
	
	#if (AudioManager.is_bgm_playing() == false or (AudioManager.get_current_bgm_path() != "res://music/bgm/menu/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 03 Kind Girl, Honest Girl.mp3" and AudioManager.get_current_bgm_path() != "res://assets/music/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 03 Kind Girl, Honest Girl.mp3" and AudioManager.get_current_bgm_path() != "res://music/bgm/hitoribocchi/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 10 Going Home - Monologue (Finale).wav")) :
		#AudioManager.play_bgm("res://music/bgm/level/Cecily Renns - Blast Damage Days Soundtrack - 12 Kill the Band (Clean).ogg", 1, false, false)
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta: float) -> void:
	
	var viewport_size = get_viewport_rect().size
	var mouse = get_viewport().get_mouse_position()

	# Nilai antara -1 sampai 1
	var mouse_offset = (mouse - viewport_size * 0.5) / (viewport_size * 0.5)


	var t := Time.get_ticks_msec() * 0.001

	if sky != null:
		var sky_float_y := sin(t * sky_float_speed + sky_phase_offset) * sky_float_amplitude
		
		var sky_target = sky_base_position
		
		sky_target += Vector2(
			   -mouse_offset.x * sky_parallax_strength,
			   -mouse_offset.y * sky_parallax_strength
		)
		
		sky_target.y += sky_float_y

		sky.position = sky.position.lerp(
			   sky_target,
			   _delta * parallax_smoothing
		)

	if sea != null:
		var sea_float_y := sin(t * sea_float_speed) * sea_float_amplitude
		
		var sea_target = sea_base_position
		
		sea_target += Vector2(
			   -mouse_offset.x * sea_parallax_strength,
			   -mouse_offset.y * sea_parallax_strength
		)
		
		sea_target.y += sea_float_y

		sea.position = sea.position.lerp(
			   sea_target,
			   _delta * parallax_smoothing
		)

	if tv != null:
		var tv_float_y := sin(t * tv_float_speed) * tv_float_amplitude
		
		var tv_target = tv_base_position
		
		tv_target += Vector2(
			   mouse_offset.x * tv_parallax_strength,
			   mouse_offset.y * tv_parallax_strength
		)
		
		tv_target.y += tv_float_y

		tv.position = tv.position.lerp(
			   tv_target,
			   _delta * parallax_smoothing
		)
		
	var visual_float_y := sin(t * visual_float_speed) * visual_float_amplitude
	var visual_target = visual_base_position
	
	visual_target += Vector2(
		   mouse_offset.x * visual_parallax_strength,
		   mouse_offset.y * visual_parallax_strength
	)
	
	visual_target.y += visual_float_y

	visual.position = visual.position.lerp(
		visual_target,
		_delta * parallax_smoothing
	)
	
	var base_float_y := sin(t * base_float_speed + 0.8) * base_float_amplitude
	var char_float_y := sin(t * char_float_speed + 1.5) * char_float_amplitude
	
	var base_target = base_base_position
	
	base_target += Vector2(
		   mouse_offset.x * base_parallax_strength,
		   mouse_offset.y * base_parallax_strength
	)
	base_target.y += base_float_y

	base.position = base.position.lerp(
		   base_target,
		   _delta * parallax_smoothing
	)
	
	var char_target = char_base_position
	
	char_target += Vector2(
		   mouse_offset.x * char_parallax_strength,
		   mouse_offset.y * char_parallax_strength
	)
	char_target.y += char_float_y

	char.position = char.position.lerp(
		   char_target,
		   _delta * parallax_smoothing
	)
		
