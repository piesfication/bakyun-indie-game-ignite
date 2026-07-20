extends Node2D

@onready var charNode = $ParallaxBackground2/Char
@onready var bakuChar = $ParallaxBackground2/Char/BakuChar
@onready var yunaChar = $ParallaxBackground2/Char/YunaChar
@onready var bothChar = $ParallaxBackground2/Char/Both
@onready var noneChar = $ParallaxBackground2/Char/None

@onready var overlay = $ParallaxBackground/Overlay

@onready var darkBackground = $Background2
@onready var lightBackground = $Background
@onready var roofTopBackground = $RoofTop
@onready var darkRoofTopBackground = $RoofTop/DarkSky
var rooftopBackground_pos
var char_pos
# Called when the node enters the scene tree for the first time.
func _ready():
	AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 02 Main Menu.ogg", 1, false, false)
	charNode.modulate.a = 0
	darkBackground.modulate.a = 0
	roofTopBackground.modulate.a = 0
	darkRoofTopBackground.modulate.a = 0
	
	rooftopBackground_pos = roofTopBackground.position
	char_pos = charNode.position
	if has_node("/root/StoryProgress"):
		StoryProgress.apply_saved_dialogic_variables()
	Dialogic.signal_event.connect(on_dialogic_signal);
	Dialogic.start("res://dialogue/story/timeline_3.dtl")

var speed = 3
var time = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * speed
	roofTopBackground.position.y = rooftopBackground_pos.y + sin(time * 1) * 10
	charNode.position.y = char_pos.y + sin(time * 1) * 7
	
	roofTopBackground.position.x = rooftopBackground_pos.x + sin(time * 1) * 10
	charNode.position.x = char_pos.x + sin(time * 1) * -7

	pass

func on_dialogic_signal(arg: String):
	
	if (arg == "pause"):
		AudioManager.pause_bgm(1)
		
	if (arg == "resume"):
		AudioManager.resume_bgm(5)

	if (arg == "level menu") :
		if has_node("/root/StoryProgress"):
			StoryProgress.mark_chapter_completed(3)
		LoadingManager.set_target_scene("res://scenes/menus/story_menu.tscn")
		await Transition.fade_out()
		AudioManager.stop_bgm(6)
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in() # fade out
		
	if (arg == "bt") :
		bakuChar.visible = true
		yunaChar.visible = false
		bothChar.visible = false
		noneChar.visible = false
		
	if (arg == "yt") :
		bakuChar.visible = false
		yunaChar.visible = true
		bothChar.visible = false
		noneChar.visible = false
	
	if (arg == "none") :
		bakuChar.visible = false
		yunaChar.visible = false
		bothChar.visible = false
		noneChar.visible = true
		
	if (arg == "both") :
		bakuChar.visible = false
		yunaChar.visible = false
		bothChar.visible = true
		noneChar.visible = false
		
	if (arg == "dark") :
		fade_in(darkBackground, 2)
		fade_out(roofTopBackground, 2)
		fade_out(lightBackground, 2)
		fade_in(darkRoofTopBackground, 2)
		fade_out(charNode, 2)
		
	if (arg == "light") :
		fade_out(darkBackground, 2)
		fade_out(roofTopBackground, 2)
		fade_in(lightBackground, 2)
		fade_out(charNode, 2)
		
	if (arg == "rooftop") :
		fade_out(darkBackground, 2)
		fade_in(roofTopBackground, 2)
		fade_out(lightBackground, 2)
		fade_in(charNode, 2)
		
	if (arg == "leave") :
		fade_out(yunaChar, 1)
		fade_out(bakuChar, 1)
		fade_out(noneChar, 1)
		fade_out(bothChar, 1)
		
	if (arg == "join") :
		fade_in(yunaChar, 1)
		fade_in(bakuChar, 1)
		fade_in(noneChar, 1)
		fade_in(bothChar, 1)
		
	if(arg == "overlay") :
		overlay.modulate.a = 0.0
		overlay.visible = true
		
		fade_in(overlay,1.0) # fade in
		await get_tree().create_timer(1).timeout
		fade_out(darkBackground, 2)
		fade_in(roofTopBackground, 2)
		fade_out(lightBackground, 2)
		fade_in(charNode, 2)
		await get_tree().create_timer(2).timeout
		fade_out(overlay, 1)

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
		
		
	
