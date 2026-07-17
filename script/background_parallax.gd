extends Node2D

@export var speed := 2
var time := 0.0

@onready var back2 := $Back2
@onready var front := $Front
@onready var sea := $Sea

@export var back_parallax := 4.0
@export var sea_parallax := 8.0
@export var front_parallax := 12.0

@export var parallax_smoothing := 6.0

var back_base_pos: Vector2
var sea_base_pos: Vector2
var front_base_pos: Vector2

func _ready():
	back_base_pos = back2.position
	sea_base_pos = sea.position
	front_base_pos = front.position
	
func _process(delta):
	time += delta * speed

	var viewport_size = get_viewport_rect().size
	var mouse = get_viewport().get_mouse_position()
	var mouse_offset = (mouse - viewport_size * 0.5) / (viewport_size * 0.5)

	# ======================
	# Back
	# ======================
	var back_target = back_base_pos
	back_target += mouse_offset * back_parallax
	back_target.y += sin(time * 1.0) * 5

	back2.position = back2.position.lerp(
		back_target,
		delta * parallax_smoothing
	)

	# ======================
	# Sea
	# ======================
	var sea_target = sea_base_pos
	sea_target += mouse_offset * sea_parallax
	sea_target.y += sin(time * 1.5) * 5

	sea.position = sea.position.lerp(
		sea_target,
		delta * parallax_smoothing
	)

	# ======================
	# Front
	# ======================
	var front_target = front_base_pos
	front_target += mouse_offset * front_parallax
	front_target.y += sin(time * 1.0 + 0.6) * 5

	front.position = front.position.lerp(
		front_target,
		delta * parallax_smoothing
	)
