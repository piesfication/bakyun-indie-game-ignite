extends Node2D

@export var speed := 2
var time := 0.0
var first_speak

@onready var chapter2background = $Chap2Sky
@onready var flyingtogether = $CanvasLayer3/SpriteChar
@onready var bakuTalking = $CanvasLayer3/SpriteChar/BakuTalking
@onready var yunaTalking = $CanvasLayer3/SpriteChar/YunaTalking

@onready var overlay = $CanvasLayer3/Overlay
@onready var bg = $Background

@onready var grass = $GrassField
@onready var charGrassField = $GrassField/Char

@onready var rooftopChar = $ParallaxBackground2/Char
@onready var bakuChar = $ParallaxBackground2/Char/BakuChar
@onready var yunaChar = $ParallaxBackground2/Char/YunaChar
@onready var bothChar = $ParallaxBackground2/Char/Both
@onready var noneChar = $ParallaxBackground2/Char/None
@onready var roofTopBackground = $RoofTop

@onready var together = $ParallaxBackground/Together

@onready var nightSky = $NightSky
@onready var nightTogether = $ParallaxBackground2/NightChar
@onready var bakuEpilogue = $ParallaxBackground/BakuFrontNight
@onready var yunaEpilogue = $ParallaxBackground/YunaFrontNight

@onready var endOverlay = $EndScreen/ColorRect
@onready var endTitle = $EndScreen/Title
@onready var endLabel = $EndScreen/End

var base_pos := {}

func _process(delta):
	
	
	time += delta * speed
	chapter2background.position.y = base_pos[chapter2background].y + sin(time * 1) * 10
	nightSky.position.y = nightSky_pos.y + sin(time * 1) * 10
	
	roofTopBackground.position.y = rooftopBackground_pos.y + sin(time * 1) * 10
	rooftopChar.position.y = char_pos.y + sin(time * 1) * 7
	
	roofTopBackground.position.x = rooftopBackground_pos.x + sin(time * 1) * 10
	rooftopChar.position.x = char_pos.x + sin(time * 1) * -7
	
	if (is_moving == false):
		flyingtogether.position.y = base_pos[flyingtogether].y + sin(time * 2) * 20

var nightSky_pos
var rooftopBackground_pos
var char_pos
# Called when the node enters the scene tree for the first time.
func _ready():
	
	AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 11 Ending.wav", 0, false, false)
	char_pos = rooftopChar.position
	rooftopBackground_pos = roofTopBackground.position
	endOverlay.visible = true
	endLabel.visible = true
	endTitle.visible = true
	
	endOverlay.modulate.a = 0
	endLabel.modulate.a = 0
	endTitle.modulate.a = 0
	
	nightSky_pos = nightSky.position
	
	nightSky.modulate.a = 0
	nightTogether.modulate.a = 0
	bakuEpilogue.modulate.a = 0 
	yunaEpilogue.modulate.a = 0
	
	together.modulate.a = 0
	
	nightSky.visible = true
	nightTogether.visible = true
	bakuEpilogue.visible = true
	yunaEpilogue.visible = true
	
	together.visible = true
	
	rooftopChar.modulate.a = 0
	roofTopBackground.modulate.a = 0
	
	grass.modulate.a = 0
	
	chapter2background.modulate.a = 0
	if has_node("/root/StoryProgress"):
		StoryProgress.apply_saved_dialogic_variables()
	
	Dialogic.signal_event.connect(on_dialogic_signal);
	Dialogic.start("res://dialogue/story/timeline_5.dtl")
	base_pos[chapter2background] = chapter2background.position
	base_pos[flyingtogether] = flyingtogether.position

func on_dialogic_signal(arg: String):
	
	if (arg == "bt rt") :
		bakuChar.visible = true
		yunaChar.visible = false
		bothChar.visible = false
		noneChar.visible = false
		
	if (arg == "yt rt") :
		bakuChar.visible = false
		yunaChar.visible = true
		bothChar.visible = false
		noneChar.visible = false
		
	if (arg == "start chapter 5") :
		chapter2background.visible = true
		bakuTalking.play("default")
		yunaTalking.play("default")
		
	if (arg == "start convo"):
		
		overlay.modulate.a = 0.0
		overlay.visible = true
		await get_tree().create_timer(0.3).timeout
		fade_overlay(1.0, 1.0) # fade in
		await get_tree().create_timer(1).timeout
		
		fade_in(chapter2background,2)
	
		fade_out(bg, 2)
		
		await get_tree().create_timer(1).timeout
		
		await get_tree().create_timer(0.3).timeout
		fade_overlay(0, 1.0)
	
	if (arg == "flying together enter"):
		flyingtogether.visible = true
		flyingtogether.modulate.a = 0
		fade_in(flyingtogether,2)
		move_to(Vector2(843, 403), flyingtogether, 2)
		
	if (arg == "bt"):
		
		bakuTalking.visible = true
		
		yunaTalking.visible = false
		flyingtogether.visible = true
		if (first_speak) == false :
			squash_stretch(flyingtogether)
		else: first_speak = false
		
	if (arg == "yt"):
		bakuTalking.visible = false
		yunaTalking.visible = true
		flyingtogether.visible = true
		if (first_speak) == false :
			squash_stretch(flyingtogether)
		else: first_speak = false
		
	if (arg == "both") :
		bakuChar.visible = false
		yunaChar.visible = false
		bothChar.visible = true
		noneChar.visible = false
		
	if (arg == "out") :
		move_to(Vector2(843, 932), flyingtogether, 2)
		fade_out(flyingtogether,0.4)
	if (arg == "in") :
		move_to(Vector2(843, 523),flyingtogether, 0)
		move_to(Vector2(843, 403), flyingtogether, 1)
		fade_in(flyingtogether, 1)
		
	if(arg == "grassfield") :
		
		overlay.modulate.a = 0.0
		overlay.visible = true
		await get_tree().create_timer(0.3).timeout
		fade_overlay(1.0, 1.0) # fade in
		await get_tree().create_timer(1).timeout
		
		fade_in(grass, 2)
	
		fade_out(bg, 2)
		
		await get_tree().create_timer(1).timeout
		
		await get_tree().create_timer(0.3).timeout
		fade_overlay(0, 1.0)
		
		pass
		
	if(arg == "leave grassfield") :
		fade_out(charGrassField, 1)
		pass
		
	if (arg == "leave rooftop") :
		fade_out(yunaChar, 1)
		fade_out(bakuChar, 1)
		fade_out(noneChar, 1)
		fade_out(bothChar, 1)
		
	if (arg == "join rooftop") :
		fade_in(yunaChar, 1)
		fade_in(bakuChar, 1)
		fade_in(noneChar, 1)
		fade_in(bothChar, 1)
		
	if(arg == "rooftop") :
		overlay.modulate.a = 0.0
		overlay.visible = true
		
		fade_in(overlay,1.0) # fade in
		await get_tree().create_timer(1).timeout
	
		fade_in(roofTopBackground, 2)
		fade_in(rooftopChar, 2)
		fade_out(chapter2background, 1)
		fade_out(flyingtogether,1)
		fade_out(grass, 1)
		await get_tree().create_timer(2).timeout
		fade_out(overlay, 1)
	
	if (arg == "endbgm") :
		AudioManager.stop_bgm(10)
		
	if (arg == "night") :
		overlay.modulate.a = 0.0
		overlay.visible = true
		
		fade_in(overlay,1.0) # fade in
		await get_tree().create_timer(1).timeout
		
		fade_out(roofTopBackground, 1)
		fade_out(rooftopChar, 1)
		fade_in(nightSky, 2)
		
		await get_tree().create_timer(2).timeout
		fade_out(overlay, 1)
		
	if (arg == "baku epilogue"):
		fade_out(yunaEpilogue, 0.75)
		await get_tree().create_timer(0.2).timeout
		fade_in(bakuEpilogue,0.75)
		
	if (arg == "yuna epilogue"):
		fade_out(bakuEpilogue,0.75)
		await get_tree().create_timer(0.2).timeout
		fade_in(yunaEpilogue, 0.75)
		
	if (arg == "together") :
		fade_out(bakuEpilogue, 0.75)
		fade_out(yunaEpilogue, 0.75)
		await get_tree().create_timer(0.2).timeout
		fade_in(nightTogether, 0.75)
		
	if(arg == "end") :
		fade_in(endOverlay, 2)
		await get_tree().create_timer(3).timeout
		AudioManager.stop_bgm(0)
		fade_in(endTitle,1)
		fade_in(endLabel,1)
		AudioManager.play_bgm("res://music/bgm/hitoribocchi/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 10 Going Home - Monologue (Finale).wav", 0, false, false)
		
	if (arg == "post") :
		await get_tree().create_timer(7).timeout
		fade_out(endTitle, 1)
		fade_out(endLabel, 1)
		await get_tree().create_timer(4).timeout
		
	if (arg == "level menu") :
		if has_node("/root/StoryProgress"):
			StoryProgress.mark_chapter_completed(5)
		LoadingManager.set_target_scene("res://scenes/menus/story_menu.tscn")
		await Transition.fade_out()
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in() # fade out

	if (arg == "kill") :
		AudioManager.stop_bgm(3)
		
	if (arg == "kidding") :
		await get_tree().create_timer(1).timeout
		AudioManager.play_bgm_sequence("res://music/bgm/hitoribocchi/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 10 Going Home - Monologue (Finale).wav", "res://music/bgm/level/Cecily Renns - Blast Damage Days Soundtrack - 12 Kill the Band (Clean).ogg", 0)
		
		
var tween: Tween
func fade_overlay(to: float, duration: float):
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(overlay, "modulate:a", to, duration)
	
func fade_in(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func squash_stretch(arg):
	var tween = create_tween()

	# Stretch (lonjong ke atas)
	tween.tween_property(arg, "scale", Vector2(0.63, 0.63), 0.1)

	# Balik ke normal
	tween.tween_property(arg, "scale", Vector2(0.6, 0.6), 0.1)

var is_moving = false
func move_to(target_pos: Vector2, arg, dur):
	is_moving = true
	
	var tween = create_tween()
	tween.tween_property(arg, "global_position", target_pos, dur)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(func():
		base_pos[arg] = arg.position
		is_moving = false
	)
