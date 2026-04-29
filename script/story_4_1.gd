extends Node2D

@export_range(0.0, TAU, 0.01) var phase_offset: float = PI * 0.65

@onready var sky = $Node2D/Sky
@onready var tower = $Node2D/Tower

@onready var backSea = $ParallaxBackground/Node2D/SeaBack

@onready var allChar = $ParallaxBackground/Node2D/All
@onready var yt = $ParallaxBackground/Node2D/All/YunaChar
@onready var bt = $ParallaxBackground/Node2D/All/BakuChar
@onready var noneChar = $ParallaxBackground/Node2D/All/Out
@onready var bothChar = $ParallaxBackground/Node2D/All/Both

@onready var overlay = $ParallaxBackground/Overlay

@onready var frontSea = $ParallaxBackground/Node2D/Sprite2D

@onready var confessBack = $Node2D
@onready var confessFront = $ParallaxBackground/Node2D

var confessFront_pos : Vector2
var confessBack_pos : Vector2
var all_pos : Vector2
# Called when the node enters the scene tree for the first time.

var _time_accum = 0
func _ready():
	confessFront_pos = confessFront.position
	confessBack_pos = confessBack.position
	all_pos = allChar.position
	if has_node("/root/StoryProgress"):
		StoryProgress.apply_saved_dialogic_variables()
	
	Dialogic.signal_event.connect(on_dialogic_signal);
	Dialogic.start("res://timeline/timeline_411_yuokai_confession.dtl")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	_time_accum += delta
	confessFront.position.y = confessFront_pos.y + sin(_time_accum * 1.6 + phase_offset ) * 12
	confessBack.position.y = confessBack_pos.y + sin(_time_accum * 1.6 + phase_offset ) * 12
	confessBack.position.x = confessBack_pos.x + sin(_time_accum * 1.6 + phase_offset ) * 24
	allChar.position.y = all_pos.y + sin(_time_accum * 4 + phase_offset ) * -12



func on_dialogic_signal(arg: String):

	if (arg == "level menu") :
		if has_node("/root/StoryProgress"):
			StoryProgress.mark_chapter_completed(4)
		LoadingManager.set_target_scene("res://scenes/level_menu.tscn")
		await Transition.fade_out()
		AudioManager.stop_bgm(8)
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
		await Transition.fade_in() # fade out
		
	if (arg == "yt") :
		yt.visible = true
		bt.visible = false
		bothChar.visible = false
		noneChar.visible = false
		
	if (arg == "bt") :
		yt.visible = false
		bt.visible = true
		bothChar.visible = false
		noneChar.visible = false
		
	if (arg == "both") :
		yt.visible = false
		bt.visible = false
		bothChar.visible = true
		noneChar.visible = false
		
	if (arg == "none") :
		yt.visible = false
		bt.visible = false
		bothChar.visible = false
		noneChar.visible = true
		
	if (arg == "leave") :
		fade_out(allChar, 1)
		fade_out(frontSea,1)
		
	if (arg == "join") :
		fade_in(allChar, 1)
		fade_in(frontSea,1)
		
	if (arg == "city") :
		fade_out(confessBack,2)
		fade_out(confessFront, 2)
		
	if (arg == "remove overlay") :
		fade_out(overlay, 2)
		AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 10 Confess to You.wav", 0, false, false)
		

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
