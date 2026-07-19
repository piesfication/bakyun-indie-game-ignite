extends Node2D

@onready var birdstrike := $BirdStrike

@export var speed := 2
var time := 0.0

@onready var char = get_node_or_null("AnimatedSprite2D")

var _shake_time_left: float = 0.0
var _shake_prev_offset: Vector2 = Vector2.ZERO
var _shake_phase: float = 0.0
var _shake_duration_current: float = 0.24
var _shake_strength_current: float = 26.0
var _shake_frequency_current: float = 95.0
var _shake_falloff_power_current: float = 2.0
var _shake_target: Node2D

@export var bird_strike_shake_duration: float = 0.68
@export var bird_strike_shake_strength: float = 95.0
@export var bird_strike_shake_frequency: float = 155.0
@export var bird_strike_shake_falloff_power: float = 0.55

@onready var sky = $FirstEncounter/Sky
@onready var building = $FirstEncounter/Building
@onready var land = $FirstEncounter/Land
@onready var charfirstenc = $FirstEncounter/Char
@onready var grass = $FirstEncounter/Grass

@onready var overlay = $CanvasLayer3/Overlay

@onready var bakusroom = $BakusRoom

@export var sky_float_amplitude := 12.0
@export var building_float_amplitude := 6.0
@export var land_float_amplitude := 7
@export var char_float_amplitude := 8
@export var grass_float_amplitude := 12.0

@export var sky_float_speed := 2
@export var building_float_speed := 2
@export var land_float_speed := 2
@export var char_float_speed := 2
@export var grass_float_speed := 4

var base_pos := {}

var sky_base_pos: Vector2
var building_base_pos: Vector2
var land_base_pos: Vector2
var char_base_pos: Vector2
var grass_base_pos: Vector2

var bakusroom_pos 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sky_base_pos = sky.position
	building_base_pos = building.position
	land_base_pos = land.position
	char_base_pos = charfirstenc.position
	grass_base_pos = grass.position
	
	bakusroom_pos = bakusroom.position
	if has_node("/root/StoryProgress"):
		StoryProgress.apply_saved_dialogic_variables()
	Dialogic.signal_event.connect(on_dialogic_signal);
	Dialogic.start("res://dialogue/story/timeline.dtl")
	overlay.visible = false
	AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 02 Main Menu.ogg", 1, false, false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var tt := Time.get_ticks_msec() * 0.001

	sky.position = sky_base_pos + Vector2(
		0,
		sin(tt * sky_float_speed) * sky_float_amplitude
	)

	building.position = building_base_pos + Vector2(
		0,
		sin(tt * building_float_speed + 0.4) * building_float_amplitude
	)
	
	building.position = building_base_pos + Vector2(
		sin(tt * building_float_speed + 0.4) * building_float_amplitude, 0
	)

	land.position = land_base_pos + Vector2(
		0,
		sin(tt * land_float_speed + 0.8) * land_float_amplitude
	)
	
	land.position = land_base_pos + Vector2(
		sin(tt * land_float_speed + 0.8) * land_float_amplitude, 0
	)

	charfirstenc.position = char_base_pos + Vector2(
		0,
		sin(tt * char_float_speed + 1.2) * char_float_amplitude
	)

	grass.position = grass_base_pos + Vector2(
		0,
		sin(tt * grass_float_speed + 1.6) * grass_float_amplitude
	)
	
	grass.position = grass_base_pos - Vector2(
		sin(tt * grass_float_speed + 1.6) * grass_float_amplitude, 0
	)
	
	time += delta * speed
	bakusroom.position.y = bakusroom_pos.y + sin(time * 1) * 5
	
	if _shake_target == null:
		return
		
	else:
		pass

	# Reset offset sebelumnya
	_shake_target.position -= _shake_prev_offset
	_shake_prev_offset = Vector2.ZERO

	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		
		if _shake_time_left <= 0.0:
			return
		
		var t: float = clamp(_shake_time_left / _shake_duration_current, 0.0, 1.0)
		
		if is_nan(t):
			return
		
		var falloff := pow(t, _shake_falloff_power_current)

		_shake_phase += delta * _shake_frequency_current
		
		var offset := Vector2(
			cos(_shake_phase),
			sin(_shake_phase)
		) * _shake_strength_current * falloff

		_shake_target.position += offset
		_shake_prev_offset = offset

@onready var first = $FirstEncounter
@onready var charfirst = $FirstEncounter/Char
func on_dialogic_signal(arg: String):
	if (arg == "bird strike") :
		birdstrike.visible = true
		birdstrike.play("strike")
	
	if (arg == "first encounter"):
		overlay2.modulate.a = 0
		overlay2.visible = true
		
		await fade_overlay_white(1.0, 1)
		
		await get_tree().create_timer(1).timeout
		
		first.modulate.a = 0
		first.visible = true
		
		fade_in(first, 0)
		await get_tree().create_timer(1.5).timeout
		await fade_overlay_white(0.0, 1.0)
		
	if (arg == "new witch"):
		fade_out(charfirst, 1)
		
	if (arg == "yuna wake up") :
		print("wake")
		bakusroom.modulate.a = 0
		bakusroom.visible = true
		fade_in(bakusroom, 0)
		fade_overlay(0.0, 1.0) # fade out
		#AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 04 Kristine's Theme ~ -Mornings of Nausea-.ogg", 5, true, true)
	
	if (arg == "my place") :
		AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 05 New Ark City.ogg", 1, false, false)
	if (arg == "level menu") :
		if has_node("/root/StoryProgress"):
			StoryProgress.mark_chapter_completed(1)
		LoadingManager.set_target_scene("res://scenes/menus/story_menu.tscn")
		await Transition.fade_out()
		await AudioManager.stop_bgm(5)
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in() # fade out
		
	if (arg == "fade audio") :
		pass
		
	if (arg == "baku appears") :
		AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 04 Kristine's Theme ~ -Mornings of Nausea-.ogg", 1, true, true)

func fade_in(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func fade_out(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		


func _on_bird_strike_animation_finished() -> void:
	birdstrike.visible = false
	pass # Replace with function body.

func trigger_screen_shake() -> void:
	if _shake_target == null or not is_instance_valid(_shake_target):
		_shake_target = get_tree().current_scene as Node2D
	if _shake_target == null:
		return

	_shake_duration_current = maxf(bird_strike_shake_duration, 0.001)
	_shake_strength_current = maxf(bird_strike_shake_strength, 0.0)
	_shake_frequency_current = maxf(bird_strike_shake_frequency, 0.0)
	_shake_falloff_power_current = maxf(bird_strike_shake_falloff_power, 0.1)
	_shake_time_left = maxf(_shake_time_left, _shake_duration_current)
	_shake_phase = randf() * TAU
	
	

func _on_bird_strike_frame_changed() -> void:
	if birdstrike.animation == "strike" and birdstrike.frame == 5:
		trigger_screen_shake()
		Transition.play_crt_glitch_burst()
		
		overlay.modulate.a = 0.0
		overlay.visible = true
		await AudioManager.stop_bgm(1)
		await get_tree().create_timer(0.3).timeout
	
		fade_overlay(1.0, 1.0) # fade in
		
		
		#LoadingManager.set_target_scene("res://scenes/menus/level_menu.tscn")
		#await Transition.fade_out()
		#get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		#await Transition.fade_in()
		
var tween: Tween

@onready var overlay2 = $CanvasLayer3/Overlay2

func fade_overlay_white(to: float, duration: float):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(overlay2, "modulate:a", to, duration)

func fade_overlay(to: float, duration: float):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(overlay, "modulate:a", to, duration)
