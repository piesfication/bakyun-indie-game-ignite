extends "res://script/main_boss_level.gd"

func _ready() -> void:
	super._ready()
	AudioManager.play_bgm("res://music/sfx/etc/freesound_community-underwater-6236.mp3", 0, false, false)
	_configure_baku_only_mode()
	Current.setcurrentmode("Story")

func _configure_baku_only_mode() -> void:
	if player_node != null and is_instance_valid(player_node):
		if player_node.has_method("set_current_character"):
			player_node.set_current_character("baku")
		if player_node.has_method("set_switch_locked"):
			player_node.set_switch_locked(true)

	if crosshair_node != null and is_instance_valid(crosshair_node):
		if crosshair_node.has_method("set_character_mode"):
			crosshair_node.set_character_mode("baku")
		if crosshair_node.has_method("set_switch_locked"):
			crosshair_node.set_switch_locked(true)

	_set_combat_cast_locked(true)

func _spawn_boss_once() -> void:
	super._spawn_boss_once()

@onready var overlay_yuokai = $CanvasLayer3/Overlay
func on_dialogic_signal(arg: String):
	super.on_dialogic_signal(arg)
	
	
	if (arg == "water"):
		AudioManager.start_ui_sfx("res://music/sfx/etc/universfield-water-splash-199583.mp3", [0.8, 1.2], 15)
	
	if (arg == "remember"):
		pass
		
	if (arg == "remove overlay") :
		
		AudioManager.play_bgm_sequence("res://music/bgm/hitoribocchi/JohnJRenns - Hitoribocchi- A Musical (Vocaloid Cast Recording) - 01 Hitoribocchi Overture.wav", "res://music/bgm/level/50838754-sad_guitar-359666.wav", 1)
		
		fade_out(overlay_yuokai, 3)
		
	if (arg == "show overlay") :
		
		fade_in(overlay_yuokai, 2)
	
	if (arg == "post yuokai"):
		LoadingManager.set_target_scene("res://scenes/story_4_1.tscn")
		await Transition.fade_out()
		AudioManager.stop_bgm(2)
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
		await Transition.fade_in() # fade out

func fade_in(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out(arg, dur):
	var tween = create_tween()
	tween.tween_property(arg, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		
	
