extends Node2D

@onready var alph = $Alpha

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 02 Main Menu.ogg", 1, false, false)
	if has_node("/root/StoryProgress"):
		StoryProgress.apply_saved_dialogic_variables()
	Dialogic.signal_event.connect(on_dialogic_signal);
	Dialogic.start("res://dialogue/story/timeline_4.dtl")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_dialogic_signal(arg: String):
	
	if (arg == "boss fight"):
		LoadingManager.set_target_scene("res://scenes/gameplay/levels/main_boss.tscn")
		await Transition.fade_out()
		
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in()
	
	if (arg == "understand") :
		AudioManager.stop_bgm(3.0)
		
	if (arg == "banzai") :
		AudioManager.play_bgm_sequence("res://music/bgm/story/Blast Damage Days - Blast Damage Days Soundtrack - 01 Look Back.mp3", "res://music/bgm/level/Cecily Renns - Blast Damage Days Soundtrack - 08 Date Out!.ogg", 1)
		
	if (arg == "boss music"):
		AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 11 Ending.wav", 1, false, false)
	
	
	
	
