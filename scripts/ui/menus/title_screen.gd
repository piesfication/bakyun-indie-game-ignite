extends Node2D

@export_range(0.0, 100.0, 0.1) var ba_float_amplitude: float = 12.0
@export_range(0.0, 100.0, 0.1) var kyun_float_amplitude: float = 12.0
@export_range(0.1, 10.0, 0.01) var float_speed: float = 1.6
@export_range(0.0, TAU, 0.01) var phase_offset: float = PI * 0.65

var char_float_amplitude: float = 6

@onready var ba: AnimatedSprite2D = $CanvasLayer2/Title/Ba
@onready var kyun: AnimatedSprite2D = $CanvasLayer2/Title/Kyun
@onready var charAnim: AnimatedSprite2D = $CanvasLayer2/CharAnim
@onready var baku_click_area: Area2D = $CanvasLayer2/CharAnim/BakuClick
@onready var yuna_click_area: Area2D = $CanvasLayer2/CharAnim/YunaClick
@onready var exit_click_area: Area2D = $CanvasLayer3/ExitClick

@export var ba_parallax_strength := 8.0
@export var kyun_parallax_strength := 10.0
@export var char_parallax_strength := 16.0

@export var parallax_smoothing := 6.0

var _time_accum: float = 0.0
var _ba_base_position: Vector2
var _kyun_base_position: Vector2
var _char_base_position: Vector2

@onready var white := $CanvasLayer3/titlecard/white
@onready var dark := $CanvasLayer3/titlecard/dark
@onready var bluered := $CanvasLayer3/titlecard/bakyun
@onready var intro := $CanvasLayer3/IntroOverlay

@onready var titleCard := $CanvasLayer3/titlecard

var _clicked := false

func _ready() -> void:
	_ba_base_position = ba.position
	_kyun_base_position = kyun.position
	_char_base_position = charAnim.position
	set_process_input(true)

	if LoadingManager.gettitleOpened() == false:
		AudioManager.play_bgm_sequence("res://assets/music/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 03 Kind Girl, Honest Girl.mp3","res://music/bgm/level/Cecily Renns - Blast Damage Days Soundtrack - 12 Kill the Band (Clean).ogg", 1)
		LoadingManager.setOpenedTrue()
		titleCard.visible = true
		intro.visible = true
		intro.modulate = Color.BLACK
		white.visible = true
		white.scale = Vector2(1,1) * 0.7
		dark.visible = false
		bluered.visible = false
		
		await get_tree().create_timer(0.3).timeout

		intro.modulate = Color.WHITE
		white.visible = false
		dark.scale = Vector2(1,1) * 0.8
		dark.visible = true
		
		await get_tree().create_timer(0.3).timeout
		
		intro.modulate = Color.BLACK
		white.visible = true
		white.scale = Vector2(1,1) * 0.9
		dark.visible = false
		
		await get_tree().create_timer(0.3).timeout
		
		intro.modulate = Color.WHITE
		white.visible = false
		dark.visible = false
		bluered.scale = Vector2(1,1) * 1
		bluered.visible = true
		
		await get_tree().create_timer(0.3).timeout
		
		intro.visible = false
		white.visible = false
		dark.visible = false
		bluered.visible = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		get_tree().change_scene_to_file("res://scenes/debug/enhancement_debug.tscn")
		return

	if _clicked:
		return
	if event is InputEventMouseButton and event.pressed:
		if _is_click_blocked_for_start(event.position):
			return
		_clicked = true
		LoadingManager.set_target_scene("res://scenes/menus/level_menu.tscn")
		await get_tree().create_timer(3.0).timeout
		await Transition.fade_out()
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in()

func _is_click_on_character_area(click_pos: Vector2) -> bool:
	return _area_contains_click_point(baku_click_area, click_pos) or _area_contains_click_point(yuna_click_area, click_pos)

func _is_click_blocked_for_start(click_pos: Vector2) -> bool:
	return _is_click_on_character_area(click_pos) or _area_contains_click_point(exit_click_area, click_pos)

func _area_contains_click_point(area: Area2D, click_pos: Vector2) -> bool:
	if area == null:
		return false

	for node: Node in area.get_children():
		if node is CollisionPolygon2D:
			var poly: CollisionPolygon2D = node as CollisionPolygon2D
			if poly.disabled or poly.polygon.size() < 3:
				continue
			var local_point: Vector2 = poly.to_local(click_pos)
			if Geometry2D.is_point_in_polygon(local_point, poly.polygon):
				return true
		elif node is CollisionShape2D:
			var shape_node: CollisionShape2D = node as CollisionShape2D
			if shape_node.disabled or shape_node.shape == null:
				continue
			var shape_local_point: Vector2 = shape_node.to_local(click_pos)
			if _shape_contains_point(shape_node.shape, shape_local_point):
				return true

	return false

func _shape_contains_point(shape: Shape2D, local_point: Vector2) -> bool:
	if shape is CircleShape2D:
		var circle: CircleShape2D = shape as CircleShape2D
		return local_point.length() <= circle.radius

	if shape is RectangleShape2D:
		var rect: RectangleShape2D = shape as RectangleShape2D
		var half_size: Vector2 = rect.size * 0.5
		return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y

	if shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape as CapsuleShape2D
		var radius: float = capsule.radius
		var half_height: float = capsule.height * 0.5
		if absf(local_point.x) <= radius and absf(local_point.y) <= half_height:
			return true
		var top_center := Vector2(0.0, -half_height)
		var bottom_center := Vector2(0.0, half_height)
		return local_point.distance_to(top_center) <= radius or local_point.distance_to(bottom_center) <= radius

	return false

func _process(delta: float) -> void:
	_time_accum += delta

	var viewport_size = get_viewport_rect().size
	var mouse = get_viewport().get_mouse_position()
	var mouse_offset = (mouse - viewport_size * 0.5) / (viewport_size * 0.5)

	# =========================
	# BA
	# =========================
	var ba_target = _ba_base_position
	ba_target += -mouse_offset * ba_parallax_strength
	ba_target.y += sin(_time_accum * float_speed) * ba_float_amplitude

	ba.position = ba.position.lerp(
		ba_target,
		delta * parallax_smoothing
	)

	# =========================
	# KYUN
	# =========================
	var kyun_target = _kyun_base_position
	kyun_target += -mouse_offset * kyun_parallax_strength
	kyun_target.y += sin(
		_time_accum * float_speed + phase_offset
	) * kyun_float_amplitude

	kyun.position = kyun.position.lerp(
		kyun_target,
		delta * parallax_smoothing
	)

	# =========================
	# CHARACTER
	# =========================
	var char_target = _char_base_position
	char_target += -mouse_offset * char_parallax_strength
	char_target.y += sin(
		_time_accum * float_speed + phase_offset
	) * char_float_amplitude

	charAnim.position = charAnim.position.lerp(
		char_target,
		delta * parallax_smoothing
	)
	
	charAnim.rotation_degrees = lerp(
		charAnim.rotation_degrees,
		-mouse_offset.x * 2.0,
		delta * 4.0
	)
