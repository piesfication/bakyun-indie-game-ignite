extends Node2D

# ============================================================================
# TUTORIAL LEVEL CONTROLLER
# ----------------------------------------------------------------------------
# Asumsi-asumsi yang dipakai script ini — tolong dicek & disesuaikan:
#
# 1. Struktur node scene ini SAMA dengan level.gd: ada node bernama
#    EnemyContainer, Player, Crosshair, UIKoisuruMeter/KoisuruMeter,
#    UIMahouMeter, LevelEndOverlay (CanvasLayer) > ColorRect, MissionClear,
#    UltimateAnim, dan (opsional) CardUI.
#
# 2. Dialogic di-autoload dengan nama "Dialogic" (default Dialogic 2.x untuk
#    Godot 4), dipakai lewat Dialogic.start(timeline_name) dan ditunggu
#    sampai sinyal Dialogic.timeline_ended menyala. Kalau versi/setup
#    Dialogic kamu beda, cukup ubah isi fungsi _play_dialog() di bawah —
#    sisa script tidak perlu diubah.
#
# 3. Semua nama timeline Dialogic di-export sebagai String dan defaultnya
#    KOSONG ("") supaya script ini aman dijalankan sebelum timeline-nya
#    dibuat (dialog kosong = dilewati, tapi syarat aksi+enemy mati tetap
#    berlaku). Isi nama timeline-nya lewat Inspector begitu sudah dibuat
#    di Dialogic.
#
# 4. Player dibuat invulnerable selama tutorial (tutorial_player_invulnerable
#    = true) supaya fokus ke belajar mekanik, bukan survival. Kalau mau ada
#    resiko mati pas free practice, set ke false lewat Inspector.
#
# 5. Tiap step (sesuai pilihanmu) baru lanjut kalau DUA syarat terpenuhi:
#    aksi yang diminta dilakukan, DAN seluruh enemy di step itu sudah mati.
#
# 6. Step skill menunggu sinyal skill_casted(skill_name) dari UIMahouMeter
#    dengan nama yang COCOK (OVERDRIVE/PIERCE/CHAIN/NOVA). Kalau combo yang
#    ke-trigger salah, step belum dianggap selesai — player otomatis bisa
#    coba lagi karena slot di UIMahouMeter reset sendiri tiap selesai cast.
# ============================================================================

signal tutorial_finished


@export var enemy_scene: PackedScene

var spawn_timer := 0.0
var bird_strike_timer := 0.0
var bird_strike_lock_timer := 0.0
var bird_strike_active := false
var bird_strike_effect_started := false
var level_end_sequence_running: bool = false
var spawn_allowed: bool = true  # Track if spawn should continue (stops at timer end)
var level_time_left: float = 0.0


@onready var enemy_container: Node = $EnemyContainer
@onready var player_node: Node = $Player
@onready var crosshair_node: Node = $Crosshair
@onready var mahou_meter_node: Node = $UIMahouMeter
@onready var koisuru_meter_node: Node = $UIKoisuruMeter/KoisuruMeter
@onready var ultimate_anim_node: AnimatedSprite2D = $UltimateAnim
@onready var mission_clear_node: AnimatedSprite2D = $MissionClear
@onready var mission_failed_node: AnimatedSprite2D = get_node_or_null("MissionFailed") as AnimatedSprite2D
@onready var level_end_overlay_layer: CanvasLayer = $LevelEndOverlay
@onready var level_end_overlay: ColorRect = $LevelEndOverlay/ColorRect
@onready var bird_strike_node: AnimatedSprite2D = $BirdStrike

@export var enemy_2_scene: PackedScene = preload("res://scenes/gameplay/enemies/enemy_2.tscn")
@export var enemy_3_scene: PackedScene = preload("res://scenes/gameplay/enemies/enemy_3.tscn")
@onready var bird_strike_alert_node: AnimatedSprite2D = $BirdStrikeAlert
@onready var combo_counter_node: Node = $LevelEndOverlay/ComboCounter

@export_group("Pengaturan Umum")
@export var tutorial_player_invulnerable: bool = true
@export var max_enemies: int = 6
@export var base_z_index: int = 100
@export var z_front_min: int = 40

@export_group("Dialog Timelines (nama resource Dialogic, isi setelah dibuat)")
@export var dialog_intro_controls: String = "res://dialogue/tutorials/introduction.dtl"
@export var dialog_skill_overdrive: String = "res://dialogue/tutorials/tut_overdrive.dtl"
@export var dialog_skill_pierce: String = "res://dialogue/tutorials/tut_pierce.dtl"
@export var dialog_skill_chain: String = "res://dialogue/tutorials/tut_chain.dtl"
@export var dialog_skill_nova: String = "res://dialogue/tutorials/tut_nova.dtl"
@export var dialog_ultimate: String = "res://dialogue/tutorials/tut_ultimate.dtl"
@export var dialog_free_practice: String = "res://dialogue/tutorials/tut_practice.dtl"
@export var dialog_outro: String = "res://dialogue/tutorials/outro.dtl"

@export_group("Audio Tembakan")
@export var shot_hit_sfx_path: String = "res://music/sfx/shooting/u_qoe8xdq7hm-beam-fire-282361.wav"
@export var shot_miss_sfx_path: String = "res://music/sfx/shooting/zehendrew-infinity-castle-gate-opening-sound-muzan-463491.wav"
@export_range(0.5, 3.0, 0.01, "suffix:x") var shot_hit_pitch_start: float = 0.85
@export_range(0.01, 1.0, 0.01, "suffix:x") var shot_hit_pitch_step: float = 0.2
@export_range(0.5, 3.0, 0.01, "suffix:x") var shot_hit_pitch_max: float = 2.0
	 
@export var spawn_interval: float = 2.0  # Detik per spawn
@export var spawn_batch: int = 1         # Berapa banyak musuh spawn sekaligus
@export var bird_strike_check_interval: float = 8.0
@export var bird_strike_chance: float = 0.1
@export_range(0.0, 20.0, 0.1, "suffix:s") var bird_strike_shoot_lock_duration: float = 4.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var ultimate_hide_to_kill_delay: float = 0.6
@export_range(10.0, 1800.0, 1.0, "suffix:s") var level_duration_seconds: float = 180.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var level_intro_delay_seconds: float = 2.5
@export_range(0.1, 20.0, 0.1, "suffix:s") var level_end_lose_delay_seconds: float = 3.0
@export_range(0.0, 20.0, 0.1, "suffix:s") var level_end_ui_pull_delay_seconds: float = 3.0
@export_range(0.1, 5.0, 0.05, "suffix:s") var level_end_lose_fade_duration: float = 1.5
@export_range(0.0, 5.0, 0.05, "suffix:s") var level_end_lose_hold_seconds: float = 2.0

@export_group("Free Practice")
@export var free_practice_enemy_count: int = 5
@export var free_practice_spawn_interval: float = 1.4

@export_group("Ultimate")
@export_range(0.1, 20.0, 0.1, "suffix:s") var ultimate_boss_weaken_duration: float = 5.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var ultimate_kill_wait_timeout: float = 3.0
@export var ultimate_ui_pull_distance: float = 900.0
@export_range(0.1, 5.0, 0.05, "suffix:s") var ultimate_ui_pull_out_anim_duration: float = 1.0
@export var ultimate_ui_return_anim_duration: float = 0.45
@export var ultimate_enemy_wave_count: int = 3

@export_group("Akhir Level")
@export_range(0.1, 20.0, 0.1, "suffix:s") var level_end_win_delay_seconds: float = 3.0
@export_range(0.0, 10.0, 0.05, "suffix:s") var level_end_mission_clear_pre_delay_seconds: float = 0.3
@export_range(0.0, 10.0, 0.05, "suffix:s") var level_end_mission_clear_post_delay_seconds: float = 0.45
@export_range(0.1, 5.0, 0.05, "suffix:s") var level_end_fade_duration: float = 1.5
@export_range(0.0, 5.0, 0.05, "suffix:s") var level_end_fade_hold_seconds: float = 2.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var level_end_grayscale_duration: float = 0.7
@export_range(0, 60, 1) var mission_failed_grayscale_start_frame: int = 6

var current_enemy_count: int = 0
var next_z_index: int
var _shot_hit_pitch_scale: float = 1.0

var level_running: bool = false
var level_ended: bool = false
var ultimate_in_progress: bool = false

var _ultimate_ui_names: Array[String] = ["CardUI", "UIKoisuruMeter", "UIMahouMeter", "Player"]
var _ultimate_ui_original_pos: Dictionary = {}
var _ultimate_ui_pulled_out: bool = false

# --- step tracking ---
signal _step_requirements_met
var _current_action_type: String = ""   # "", "shoot_and_switch", "skill", "ultimate", "free_practice"
var _current_required_skill: String = ""
var _action_done: bool = false
var _shot_done: bool = false
var _switch_done: bool = false
var _enemies_target_cleared: bool = false


func _ready() -> void:
	Dialogic.signal_event.connect(on_dialogic_signal);
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioManager.play_bgm("res://music/bgm/story/Cecily Renns - Blast Damage Days Soundtrack - 04 Kristine's Theme ~ -Mornings of Nausea-.ogg", 1, true, true)
	
	if has_node("/root/Current"):
		Current.setcurrentmode("Tutorial")
	_shot_hit_pitch_scale = maxf(shot_hit_pitch_start, 0.01)
	next_z_index = base_z_index
	_setup_runtime_systems()
	_run_tutorial()

func on_dialogic_signal(arg: String):
	if (arg == "end_tutorial") :
		LoadingManager.set_target_scene("res://scenes/menus/story_menu.tscn")
		await Transition.fade_out()
		get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
		await Transition.fade_in() # fade out
		
	var fade_duration: float = 1

	if (arg == "highlight_koisuru"):
		await _remove_parallax_story_focus()
		await _set_ultimate_ui_pulled_out(false)
		
		# Pastikan node aktif dan mulai dari transparan penuh
		koisuruhighlight.modulate.a = 0.0
		koisuruhighlight.visible = true
		
		# Jalankan animasi Fade In
		var tween = create_tween()
		tween.tween_property(koisuruhighlight, "modulate:a", 1.0, fade_duration)
		await tween.finished # Tunggu sampai animasi fade selesai jika diperlukan


	if (arg == "highlight_koisuru_false"):
		# Jalankan animasi Fade Out terlebih dahulu
		var tween = create_tween()
		tween.tween_property(koisuruhighlight, "modulate:a", 0.0, fade_duration)
		await tween.finished # Tunggu animasi selesai baru sembunyikan nodenya
		
		koisuruhighlight.visible = false
		await _set_ultimate_ui_pulled_out(true)
		await _move_parallax_story_focus()


	if (arg == "highlight_mahou"):
		await _remove_parallax_story_focus()
		await _set_ultimate_ui_pulled_out(false)
		
		# Pastikan node aktif dan mulai dari transparan penuh
		mahouhighlight.modulate.a = 0.0
		mahouhighlight.visible = true
		
		# Jalankan animasi Fade In
		var tween = create_tween()
		tween.tween_property(mahouhighlight, "modulate:a", 1.0, fade_duration)
		await tween.finished


	if (arg == "highlight_mahou_false"):
		# Jalankan animasi Fade Out terlebih dahulu
		var tween = create_tween()
		tween.tween_property(mahouhighlight, "modulate:a", 0.0, fade_duration)
		await tween.finished
		
		mahouhighlight.visible = false
		await _set_ultimate_ui_pulled_out(true)
		await _move_parallax_story_focus()
		
		
func _setup_runtime_systems() -> void:
	
	if bird_strike_node != null:
		bird_strike_node.visible = false
		if not bird_strike_node.animation_finished.is_connected(_on_bird_strike_animation_finished):
			bird_strike_node.animation_finished.connect(_on_bird_strike_animation_finished)
		if not bird_strike_node.frame_changed.is_connected(_on_bird_strike_frame_changed):
			bird_strike_node.frame_changed.connect(_on_bird_strike_frame_changed)
	
	if bird_strike_alert_node != null:
		bird_strike_alert_node.visible = false
		if not bird_strike_alert_node.animation_finished.is_connected(_on_bird_strike_alert_animation_finished):
			bird_strike_alert_node.animation_finished.connect(_on_bird_strike_alert_animation_finished)
			
	if ultimate_anim_node != null:
		ultimate_anim_node.visible = false
		if not ultimate_anim_node.animation_finished.is_connected(_on_ultimate_anim_finished):
			ultimate_anim_node.animation_finished.connect(_on_ultimate_anim_finished)

	if mission_clear_node != null:
		mission_clear_node.stop()
		mission_clear_node.visible = false

	if mission_failed_node != null:
		mission_failed_node.stop()
		mission_failed_node.visible = false

	if level_end_overlay != null:
		level_end_overlay.visible = false
		level_end_overlay.color = Color(0, 0, 0, 0)

	if koisuru_meter_node != null and koisuru_meter_node.has_signal("ultimate_casted"):
		if not koisuru_meter_node.is_connected("ultimate_casted", Callable(self, "_on_ultimate_casted")):
			koisuru_meter_node.connect("ultimate_casted", Callable(self, "_on_ultimate_casted"))

	if mahou_meter_node != null and mahou_meter_node.has_signal("skill_casted"):
		if not mahou_meter_node.is_connected("skill_casted", Callable(self, "_on_skill_casted")):
			mahou_meter_node.connect("skill_casted", Callable(self, "_on_skill_casted"))

	if player_node != null and is_instance_valid(player_node):
		if player_node.has_signal("died") and not player_node.is_connected("died", Callable(self, "_on_player_died")):
			player_node.connect("died", Callable(self, "_on_player_died"))
		if player_node.has_signal("character_switched") and not player_node.is_connected("character_switched", Callable(self, "_on_character_switched")):
			player_node.connect("character_switched", Callable(self, "_on_character_switched"))
		if player_node.has_method("set_invulnerable"):
			player_node.set_invulnerable(tutorial_player_invulnerable)

	if combo_counter_node != null and is_instance_valid(combo_counter_node):
		# Assign script if not already assigned
		if combo_counter_node.get_script() == null:
			var combo_script = load("res://scripts/gameplay/combo_counter.gd")
			if combo_script != null:
				combo_counter_node.set_script(combo_script)
		# Initialize combo counter
		if combo_counter_node.has_method("reset"):
			combo_counter_node.reset()

# ============================================================================
# FLOW UTAMA TUTORIAL
# ============================================================================

func _run_tutorial() -> void:
	level_running = false
	level_ended = false
	level_end_sequence_running = false
	spawn_allowed = true  # Reset spawn allowance for new level
	level_time_left = maxf(level_duration_seconds, 1.0)

	# Keep combat inactive until intro finishes.
	_set_crosshair_visible(false)
	_set_crosshair_shoot_enabled(false)
	_set_combat_cast_locked(true)
	_set_player_input_locked(true)
	_set_switch_locked(true)

	await _set_ultimate_ui_pulled_out(true, false, true)
	if level_intro_delay_seconds > 0.0:
		await get_tree().create_timer(level_intro_delay_seconds).timeout
	
	await _run_controls_step()
	await _run_skill_step(dialog_skill_overdrive, "OVERDRIVE")
	await _run_skill_step(dialog_skill_pierce, "PIERCE")
	await _run_skill_step(dialog_skill_chain, "CHAIN")
	await _run_skill_step(dialog_skill_nova, "NOVA")
	await _run_ultimate_step()
	await _run_free_practice_step()

	await _play_dialog(dialog_outro)
	_finish_tutorial()

@onready var mahouhighlight = $BlackOverlay/MahouHighlight
@onready var koisuruhighlight = $BlackOverlay/KoisuruHighlight

func _run_controls_step() -> void:

	await _play_dialog(dialog_intro_controls)

	_current_action_type = "shoot_and_switch"

	while true:
		_shot_done = false
		_switch_done = false
		_action_done = false

		await _set_combat_unlocked()

		_spawn_wave(1,1)
		await get_tree().create_timer(1.0).timeout

		_spawn_wave(1,1)
		await get_tree().create_timer(1.0).timeout

		_spawn_wave(1,1)

		await _wait_until_all_enemies_dead()

		if _shot_done and _switch_done:
			break

	_current_action_type = ""


func _run_skill_step(dialog_timeline:String, skill_name:String) -> void:

	await _play_dialog(dialog_timeline)

	_current_action_type = "skill"
	_current_required_skill = skill_name

	while true:

		_action_done = false

		await _set_combat_unlocked()

		await _spawn_skill_wave(skill_name)

		await _wait_until_all_enemies_dead()

		if _action_done:
			break
	
	await get_tree().create_timer(1.5).timeout
	_current_action_type = ""
	_current_required_skill = ""
	
func _wait_until_all_enemies_dead() -> void:
	while is_inside_tree() and current_enemy_count > 0:
		await get_tree().process_frame
	
func _spawn_skill_wave(skill_name:String) -> void:

	match skill_name:

		"OVERDRIVE":
			_spawn_wave(1,1)
			await get_tree().create_timer(1.5).timeout
			_spawn_wave(1,3)

		"PIERCE":
			_spawn_wave(1,1)
			await get_tree().create_timer(2.0).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.12).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.12).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.12).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.12).timeout
			_spawn_wave(1,2)

		"CHAIN":
			_spawn_wave(1,1)
			await get_tree().create_timer(2.0).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.2).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.2).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.2).timeout
			_spawn_wave(1,2)
			await get_tree().create_timer(0.2).timeout
			_spawn_wave(1,2)

		"NOVA":
			_spawn_wave(5,1)


func _run_ultimate_step() -> void:

	await _play_dialog(dialog_ultimate)

	_current_action_type = "ultimate"

	while true:

		_action_done = false

		await _set_combat_unlocked()
		
		_spawn_wave(1,1)
		await get_tree().create_timer(1.5).timeout
		_spawn_wave(1,3)
		
		_spawn_wave(5,1)
		_spawn_wave(5,1)
		_spawn_wave(5,2)
		_spawn_wave(5,1)
		_spawn_wave(5,3)
		
		_spawn_wave(1,1)
		await get_tree().create_timer(2.0).timeout
		_spawn_wave(1,2)
		await get_tree().create_timer(0.12).timeout
		_spawn_wave(1,2)
		_spawn_wave(5,1)
		await get_tree().create_timer(0.12).timeout
		_spawn_wave(1,2)
		_spawn_wave(5,1)
		await get_tree().create_timer(0.12).timeout
		_spawn_wave(1,2)
		await get_tree().create_timer(0.12).timeout
		_spawn_wave(1,2)
		
		await _wait_until_all_enemies_dead()

		if _action_done:
			break
	
	await get_tree().create_timer(2).timeout
	await _set_ultimate_ui_pulled_out(true)
	await _move_parallax_story_focus()
	
	_current_action_type = ""


func _run_free_practice_step() -> void:
	await _play_dialog(dialog_free_practice)

	_current_action_type = "free_practice"
	_action_done = true
	await _set_combat_unlocked()

	for i in range(free_practice_enemy_count):
		_spawn_wave(3, 1)
		if free_practice_spawn_interval > 0.0:
			await get_tree().create_timer(free_practice_spawn_interval).timeout

	_check_step_requirements()

	if not _enemies_target_cleared:
		await _step_requirements_met

	_current_action_type = ""


func _finish_tutorial() -> void:
	level_ended = true
	level_running = false
	_set_crosshair_visible(false)
	_set_crosshair_shoot_enabled(false)
	_set_combat_cast_locked(true)
	_set_player_input_locked(true)
	_set_switch_locked(true)

	#await get_tree().create_timer(maxf(level_end_win_delay_seconds, 0.0)).timeout
#
	#if has_node("/root/StoryProgress"):
		#StoryProgress.record_mission_win()

	await _play_mission_clear_sequence()
	await _play_level_end_screen_fade(Color(1, 1, 1, 1))

	emit_signal("tutorial_finished")

	if not is_inside_tree():
		return

	if has_node("/root/LoadingManager"):
		LoadingManager.set_target_scene("res://scenes/menus/level_menu.tscn")
	if has_node("/root/AudioManager"):
		await AudioManager.stop_bgm(5)
	get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")


func _on_player_died() -> void:
	if level_ended:
		return
	level_ended = true
	level_running = false
	spawn_allowed = false
	_set_crosshair_visible(false)
	_set_crosshair_shoot_enabled(false)
	_set_combat_cast_locked(true)
	_set_player_input_locked(true)
	_set_player_weapon_motion_locked(true)
	_set_switch_locked(true)
	_stop_bird_strike_preserve_crt()
	await _play_loss_grayscale_then_mission_failed()

	var delay := maxf(level_end_lose_delay_seconds, 0.0)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	await _play_level_end_screen_fade(Color(0, 0, 0, 1))
	_set_transition_crt_discolor(false)
	get_tree().reload_current_scene()


# ============================================================================
# CEK SYARAT STEP (aksi + enemy mati)
# ============================================================================

func _check_step_requirements() -> void:
	match _current_action_type:
		"shoot_and_switch":
			_action_done = _shot_done and _switch_done
		"skill", "ultimate":
			pass # _action_done diset langsung oleh handler terkait
		"free_practice", "":
			_action_done = true

	_enemies_target_cleared = current_enemy_count <= 0

	if _action_done and _enemies_target_cleared:
		emit_signal("_step_requirements_met")


func on_player_hit(character: String = "baku", force_max_pitch: bool = false) -> void:
	_play_shot_hit_sfx(force_max_pitch)
	if _current_action_type == "shoot_and_switch":
		_shot_done = true
		_check_step_requirements()


func on_player_miss() -> void:
	_play_shot_miss_sfx()
	_shot_hit_pitch_scale = maxf(shot_hit_pitch_start, 0.01)
	if _current_action_type == "shoot_and_switch":
		_shot_done = true
		_check_step_requirements()


func _on_character_switched(_character_name: String) -> void:
	if _current_action_type == "shoot_and_switch":
		_switch_done = true
		_check_step_requirements()


func _on_skill_casted(skill_name: String) -> void:
	if _current_action_type == "skill" and skill_name == _current_required_skill:
		_action_done = true
		_check_step_requirements()


func _on_enemy_removed() -> void:
	current_enemy_count = max(current_enemy_count - 1, 0)

	_check_step_requirements()


# ============================================================================
# DIALOGIC
# ============================================================================

func _play_dialog(timeline_name: String) -> void:
	await _set_ultimate_ui_pulled_out(true)
	await _move_parallax_story_focus()
	
	if timeline_name.is_empty():
		return

	_set_crosshair_shoot_enabled(false)
	_set_combat_cast_locked(true)
	_set_player_input_locked(true)
	_set_switch_locked(true)
	_set_crosshair_visible(false)

	Dialogic.start(timeline_name)
	await Dialogic.timeline_ended

@export var post_boss_parallax_move_duration: float = 0.8
@export var post_boss_parallax_bg_target: Vector2 = Vector2(640, 368)
@export var post_boss_parallax_bg2_target: Vector2 = Vector2(640, 360)

@export var remove_parallax_bg_target: Vector2 = Vector2(640, 506)
@export var remove_parallax_bg2_target: Vector2 = Vector2(640, 206)

func _move_parallax_story_focus() -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	var bg_sprite := root.get_node_or_null("ParallaxBackground/ParallaxLayer/Sprite2D") as Node2D
	var bg2_sprite := root.get_node_or_null("ParallaxBackground2/ParallaxLayer/Sprite2D3") as Node2D
	if bg_sprite == null and bg2_sprite == null:
		return

	var move_duration := maxf(post_boss_parallax_move_duration, 0.01)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	if bg_sprite != null:
		tween.tween_property(bg_sprite, "position", post_boss_parallax_bg_target, move_duration)
	if bg2_sprite != null:
		tween.tween_property(bg2_sprite, "position", post_boss_parallax_bg2_target, move_duration)

	await tween.finished
	
func _remove_parallax_story_focus() -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	var bg_sprite := root.get_node_or_null("ParallaxBackground/ParallaxLayer/Sprite2D") as Node2D
	var bg2_sprite := root.get_node_or_null("ParallaxBackground2/ParallaxLayer/Sprite2D3") as Node2D
	if bg_sprite == null and bg2_sprite == null:
		return

	var move_duration := maxf(post_boss_parallax_move_duration, 0.01)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	if bg_sprite != null:
		tween.tween_property(bg_sprite, "position", remove_parallax_bg_target, move_duration)
	if bg2_sprite != null:
		tween.tween_property(bg2_sprite, "position", remove_parallax_bg2_target, move_duration)

	await tween.finished
	
	
# ============================================================================
# SPAWN ENEMY
# ============================================================================

		
func _spawn_wave(count: int, type: int) -> void:
	for i in range(count):
		if type == 1:
			_spawn_enemy_instance(enemy_scene)
		elif type == 2:
			_spawn_enemy_instance(enemy_2_scene)
		elif type == 3:
			_spawn_enemy_instance(enemy_3_scene)


func _spawn_enemy_instance(scene_to_spawn: PackedScene) -> bool:
	if scene_to_spawn == null:
		return false
	if current_enemy_count >= max_enemies:
		return false

	var enemy := scene_to_spawn.instantiate()
	if enemy == null:
		return false

	enemy.position = Vector2(800, 512)
	enemy.z_front = max(next_z_index, z_front_min)
	next_z_index -= 1
	enemy_container.add_child(enemy)

	current_enemy_count += 1
	enemy.connect("tree_exited", Callable(self, "_on_enemy_removed"))
	return true


# ============================================================================
# KONTROL UI / INPUT LOCK
# ============================================================================

func _set_combat_unlocked() -> void:
	level_running = true
	level_ended = false
	await _remove_parallax_story_focus()
	await _set_ultimate_ui_pulled_out(false)
	_set_crosshair_visible(true)
	_set_crosshair_shoot_enabled(true)
	_set_combat_cast_locked(false)
	_set_player_input_locked(false)
	_set_player_weapon_motion_locked(false)
	_set_switch_locked(false)


func _set_crosshair_shoot_enabled(enabled: bool) -> void:
	if crosshair_node != null \
	and is_instance_valid(crosshair_node) \
	and crosshair_node.has_method("set_shoot_enabled"):
		crosshair_node.set_shoot_enabled(enabled)
		
func _set_crosshair_visible(visible_state: bool) -> void:
	if crosshair_node == null or not is_instance_valid(crosshair_node):
		return

	if crosshair_node.has_method("set_force_hidden"):
		crosshair_node.set_force_hidden(not visible_state)

	if visible_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _set_player_input_locked(locked: bool) -> void:
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("set_input_locked"):
		player_node.set_input_locked(locked)

func _set_player_weapon_motion_locked(locked: bool) -> void:
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("set_weapon_motion_locked"):
		player_node.set_weapon_motion_locked(locked)

func _set_switch_locked(locked: bool) -> void:
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("set_switch_locked"):
		player_node.set_switch_locked(locked)
	if crosshair_node != null and is_instance_valid(crosshair_node) and crosshair_node.has_method("set_switch_locked"):
		crosshair_node.set_switch_locked(locked)


func _set_combat_cast_locked(locked: bool) -> void:
	if mahou_meter_node != null and is_instance_valid(mahou_meter_node) and mahou_meter_node.has_method("set_cast_locked"):
		mahou_meter_node.set_cast_locked(locked)
	if koisuru_meter_node != null and is_instance_valid(koisuru_meter_node) and koisuru_meter_node.has_method("set_ultimate_locked"):
		koisuru_meter_node.set_ultimate_locked(locked)


func _set_player_invulnerable(enabled: bool) -> void:
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("set_invulnerable"):
		player_node.set_invulnerable(enabled)


# ============================================================================
# AUDIO TEMBAKAN (disalin dari level.gd)
# ============================================================================

func _play_shot_hit_sfx(force_max_pitch: bool = false) -> void:
	if shot_hit_sfx_path.is_empty():
		return
	var pitch_scale := shot_hit_pitch_max if force_max_pitch else _shot_hit_pitch_scale
	AudioManager.play_ui_sfx_with_pitch(shot_hit_sfx_path, pitch_scale)
	if not force_max_pitch:
		_shot_hit_pitch_scale = minf(_shot_hit_pitch_scale + shot_hit_pitch_step, shot_hit_pitch_max)


func _play_shot_miss_sfx() -> void:
	if shot_miss_sfx_path.is_empty():
		return
	AudioManager.start_ui_sfx(shot_miss_sfx_path, [0.8, 1.2], 6)


# ============================================================================
# ULTIMATE (disalin & disederhanakan dari level.gd, tanpa sistem bird strike)
# ============================================================================

func _on_ultimate_casted() -> void:
	if not level_running or level_ended:
		return
	if ultimate_in_progress:
		return
	ultimate_in_progress = true

	if _current_action_type == "ultimate":
		_action_done = true
		_check_step_requirements()

	_set_crosshair_visible(false)
	_set_player_invulnerable(true)

	await _set_ultimate_ui_pulled_out(true)
	_play_ultimate_anim()
	await _wait_for_ultimate_anim_frame(8)
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("trigger_screen_shake"):
		player_node.trigger_screen_shake()
	var killed_targets := _kill_non_boss_enemies_in_viewport()
	_force_boss_weakened_state()
	await _wait_until_targets_cleared(killed_targets)

	await _set_ultimate_ui_pulled_out(false)
	_stop_ultimate_anim()
	_set_crosshair_visible(true)
	_set_player_invulnerable(tutorial_player_invulnerable)
	ultimate_in_progress = false

	_check_step_requirements()


func _play_ultimate_anim() -> void:
	if ultimate_anim_node == null or not is_instance_valid(ultimate_anim_node):
		return

	ultimate_anim_node.visible = true
	ultimate_anim_node.frame = 0

	var anim_name := StringName("cast_ult")
	if ultimate_anim_node.sprite_frames != null and ultimate_anim_node.sprite_frames.has_animation(anim_name):
		ultimate_anim_node.play(anim_name)
		return

	if ultimate_anim_node.animation != StringName(""):
		ultimate_anim_node.play(ultimate_anim_node.animation)
		return

	if ultimate_anim_node.sprite_frames != null:
		var names := ultimate_anim_node.sprite_frames.get_animation_names()
		if names.size() > 0:
			ultimate_anim_node.play(names[0])


func _wait_for_ultimate_anim_frame(target_frame: int) -> void:
	if ultimate_anim_node == null or not is_instance_valid(ultimate_anim_node):
		return

	var guard := 240
	while guard > 0:
		if not is_instance_valid(ultimate_anim_node):
			return
		if ultimate_anim_node.frame >= target_frame:
			return
		await get_tree().process_frame
		guard -= 1


func _stop_ultimate_anim() -> void:
	if ultimate_anim_node == null or not is_instance_valid(ultimate_anim_node):
		return
	ultimate_anim_node.stop()
	ultimate_anim_node.visible = false


func _on_ultimate_anim_finished() -> void:
	if ultimate_anim_node == null or not is_instance_valid(ultimate_anim_node):
		return
	ultimate_anim_node.stop()
	ultimate_anim_node.visible = false


func _kill_non_boss_enemies_in_viewport() -> Array[Node]:
	var targets: Array[Node] = []
	var viewport_rect := get_viewport_rect()
	for enemy in get_tree().get_nodes_in_group("enemy_nodes"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("force_weakened_state"):
			continue
		if not (enemy is Node2D):
			continue

		var enemy_node := enemy as Node2D
		if not viewport_rect.has_point(enemy_node.global_position):
			continue

		targets.append(enemy)

		if enemy.has_method("instakill"):
			enemy.instakill()
		elif enemy.has_method("die"):
			enemy.die()

	return targets


func _wait_until_targets_cleared(targets: Array[Node]) -> void:
	if targets.is_empty():
		return

	var timeout := maxf(ultimate_kill_wait_timeout, 0.1)
	while timeout > 0.0:
		var all_cleared := true
		for target in targets:
			if target == null:
				continue
			if not is_instance_valid(target):
				continue
			all_cleared = false
			break

		if all_cleared:
			return

		await get_tree().process_frame
		timeout -= get_process_delta_time()


func _force_boss_weakened_state() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_nodes"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("force_weakened_state"):
			enemy.force_weakened_state(maxf(ultimate_boss_weaken_duration, 0.1))


func _set_ultimate_ui_pulled_out(pulled: bool, skip_damage_hud: bool = false, instant: bool = false) -> void:
	if _ultimate_ui_pulled_out == pulled:
		return

	var root := get_tree().current_scene
	if root == null:
		return

	# Fade out combo counter when pulling UI
	if pulled:
		combo_counter_fade_out()

	var viewport_rect := get_viewport_rect()
	var pull_dist := maxf(ultimate_ui_pull_distance, viewport_rect.size.y + 220.0)
	var pull_tween: Tween = null
	var restore_tween: Tween = null
	if not instant and pulled and ultimate_ui_pull_out_anim_duration > 0.0:
		pull_tween = create_tween()
		pull_tween.set_trans(Tween.TRANS_CUBIC)
		pull_tween.set_ease(Tween.EASE_IN_OUT)
		pull_tween.set_parallel(true)
	elif not instant and not pulled and ultimate_ui_return_anim_duration > 0.0:
		restore_tween = create_tween()
		restore_tween.set_trans(Tween.TRANS_CUBIC)
		restore_tween.set_ease(Tween.EASE_OUT)
		restore_tween.set_parallel(true)

	for name in _ultimate_ui_names:
		if skip_damage_hud and name == "DamageHud":
			continue

		var node := root.find_child(name, true, false)
		if node == null:
			continue

		var pull_vec := Vector2(0.0, pull_dist)
		if name == "UIMahouMeter":
			pull_vec = Vector2(0.0, -pull_dist)
		elif name == "Player":
			pull_vec = Vector2(pull_dist, pull_dist)
		elif name == "UIKoisuruMeter":
			pull_vec = Vector2(0.0, pull_dist)
		elif name == "CardUI":
			pull_vec = Vector2(-pull_dist, pull_dist)

		if node is Node2D:
			var n2d := node as Node2D
			if pulled:
				if not _ultimate_ui_original_pos.has(name):
					_ultimate_ui_original_pos[name] = n2d.global_position
				var target_pos := (_ultimate_ui_original_pos[name] as Vector2) + pull_vec
				if pull_tween != null:
					pull_tween.tween_property(n2d, "global_position", target_pos, ultimate_ui_pull_out_anim_duration)
				else:
					n2d.global_position = target_pos
			elif _ultimate_ui_original_pos.has(name):
				var target_pos := _ultimate_ui_original_pos[name] as Vector2
				if restore_tween != null:
					restore_tween.tween_property(n2d, "global_position", target_pos, ultimate_ui_return_anim_duration)
				else:
					n2d.global_position = target_pos
			continue

		if node is CanvasLayer:
			var layer := node as CanvasLayer
			if pulled:
				if not _ultimate_ui_original_pos.has(name):
					_ultimate_ui_original_pos[name] = layer.offset
				var target_offset := (_ultimate_ui_original_pos[name] as Vector2) + pull_vec
				if pull_tween != null:
					pull_tween.tween_property(layer, "offset", target_offset, ultimate_ui_pull_out_anim_duration)
				else:
					layer.offset = target_offset
			elif _ultimate_ui_original_pos.has(name):
				var target_offset := _ultimate_ui_original_pos[name] as Vector2
				if restore_tween != null:
					restore_tween.tween_property(layer, "offset", target_offset, ultimate_ui_return_anim_duration)
				else:
					layer.offset = target_offset

	_ultimate_ui_pulled_out = pulled

	if pull_tween != null:
		await pull_tween.finished
	elif restore_tween != null:
		await restore_tween.finished

# ============================================================================
# MISSION CLEAR & FADE AKHIR (disalin dari level.gd)
# ============================================================================

func _play_mission_clear_sequence() -> void:
	if mission_clear_node == null or not is_instance_valid(mission_clear_node):
		return

	var pre_delay := maxf(level_end_mission_clear_pre_delay_seconds, 0.0)
	if pre_delay > 0.0:
		await get_tree().create_timer(pre_delay).timeout

	mission_clear_node.visible = true
	mission_clear_node.frame = 0
	mission_clear_node.frame_progress = 0.0

	var clear_anim := StringName("clear")
	if mission_clear_node.sprite_frames != null and mission_clear_node.sprite_frames.has_animation(clear_anim):
		mission_clear_node.play(clear_anim)
		await mission_clear_node.animation_finished
	elif mission_clear_node.animation != StringName(""):
		mission_clear_node.play(mission_clear_node.animation)
		await mission_clear_node.animation_finished

	mission_clear_node.stop()
	mission_clear_node.visible = false

	var post_delay := maxf(level_end_mission_clear_post_delay_seconds, 0.0)
	if post_delay > 0.0:
		await get_tree().create_timer(post_delay).timeout

func _play_mission_failed_sequence() -> void:
	if mission_failed_node == null or not is_instance_valid(mission_failed_node):
		return

	mission_failed_node.visible = true
	mission_failed_node.frame = 0
	mission_failed_node.frame_progress = 0.0

	var fail_anim := StringName("default")
	if mission_failed_node.sprite_frames != null and mission_failed_node.sprite_frames.has_animation(fail_anim):
		mission_failed_node.play(fail_anim)
		await _wait_for_mission_failed_grayscale_frame()
		_start_loss_grayscale_transition()
		await mission_failed_node.animation_finished
	elif mission_failed_node.animation != StringName(""):
		mission_failed_node.play(mission_failed_node.animation)
		await _wait_for_mission_failed_grayscale_frame()
		_start_loss_grayscale_transition()
		await mission_failed_node.animation_finished

	mission_failed_node.stop()
	mission_failed_node.visible = false

func _play_loss_grayscale_then_mission_failed() -> void:
	_set_transition_crt_discolor(false)
	await _play_mission_failed_sequence()

func _wait_for_mission_failed_grayscale_frame() -> void:
	if mission_failed_node == null or not is_instance_valid(mission_failed_node):
		return

	var target_frame: int = max(mission_failed_grayscale_start_frame, 0)
	if mission_failed_node.sprite_frames != null and mission_failed_node.animation != StringName(""):
		var frame_count: int = mission_failed_node.sprite_frames.get_frame_count(mission_failed_node.animation)
		if frame_count > 0:
			target_frame = mini(target_frame, frame_count - 1)
	if mission_failed_node.frame >= target_frame:
		return

	while is_instance_valid(mission_failed_node) and mission_failed_node.is_playing():
		await mission_failed_node.frame_changed
		if mission_failed_node.frame >= target_frame:
			return

func _start_loss_grayscale_transition() -> void:
	if Transition != null and Transition.has_method("play_crt_grayscale_transition"):
		Transition.play_crt_grayscale_transition(level_end_grayscale_duration)
	else:
		_set_transition_crt_discolor(true)


func _play_level_end_screen_fade(target_color: Color) -> void:
	if level_end_overlay == null or not is_instance_valid(level_end_overlay):
		return

	level_end_overlay.visible = true
	level_end_overlay.color = target_color
	level_end_overlay.modulate = Color(1, 1, 1, 0)

	var fade_tween := create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(level_end_overlay, "modulate:a", 1.0, maxf(level_end_fade_duration, 0.01))
	await fade_tween.finished

	var hold_time := maxf(level_end_fade_hold_seconds, 0.0)
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
		
#==========================

func _play_bird_strike_alert_then_strike() -> void:
	if level_ended or level_end_sequence_running:
		_stop_bird_strike_preserve_crt()
		return
	if bird_strike_alert_node != null and is_instance_valid(bird_strike_alert_node):
		bird_strike_alert_node.visible = true
		bird_strike_alert_node.play("popup")
		return

	_start_bird_strike_now()

func _on_bird_strike_alert_animation_finished() -> void:
	if bird_strike_alert_node != null and is_instance_valid(bird_strike_alert_node):
		bird_strike_alert_node.visible = false

	if level_ended or level_end_sequence_running:
		_stop_bird_strike_preserve_crt()
		return

	if not bird_strike_active:
		return

	_start_bird_strike_now()

func _start_bird_strike_now() -> void:
	if level_ended or level_end_sequence_running:
		_stop_bird_strike_preserve_crt()
		return
	if bird_strike_node != null:
		bird_strike_node.visible = true
		bird_strike_node.frame = 0
		bird_strike_node.frame_progress = 0.0
		bird_strike_node.play("strike")

func _on_bird_strike_frame_changed() -> void:
	if level_ended or level_end_sequence_running:
		_stop_bird_strike_preserve_crt()
		return
	if not bird_strike_active or bird_strike_effect_started:
		return
	if bird_strike_node == null or not is_instance_valid(bird_strike_node):
		return
	if bird_strike_node.animation != StringName("strike"):
		return
	if bird_strike_node.frame < 5:
		return

	bird_strike_effect_started = true
	bird_strike_lock_timer = maxf(bird_strike_shoot_lock_duration, 0.0)
	_set_crosshair_shoot_enabled(false)
	_set_combat_cast_locked(true)
	_set_player_damage_hud_forced(true)
	_set_transition_crt_discolor(false)
	if Transition != null and Transition.has_method("play_crt_glitch_burst"):
		Transition.play_crt_glitch_burst()
	_schedule_transition_discolor_after_impact()
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("trigger_screen_shake"):
		player_node.trigger_screen_shake()

func _on_bird_strike_animation_finished() -> void:
	if bird_strike_node != null:
		bird_strike_node.visible = false
	if level_ended or level_end_sequence_running:
		_stop_bird_strike_preserve_crt()
		return
	if bird_strike_lock_timer <= 0.0:
		bird_strike_active = false
		bird_strike_effect_started = false
		_set_transition_crt_discolor(false)

func _stop_bird_strike_preserve_crt() -> void:
	bird_strike_active = false
	bird_strike_effect_started = false
	bird_strike_lock_timer = 0.0
	if bird_strike_alert_node != null and is_instance_valid(bird_strike_alert_node):
		bird_strike_alert_node.stop()
		bird_strike_alert_node.visible = false
	if bird_strike_node != null and is_instance_valid(bird_strike_node):
		bird_strike_node.stop()
		bird_strike_node.visible = false

func _set_player_damage_hud_forced(enabled: bool) -> void:
	if player_node != null and is_instance_valid(player_node) and player_node.has_method("set_damage_hud_forced"):
		player_node.set_damage_hud_forced(enabled)
		
func _set_transition_crt_discolor(enabled: bool) -> void:
	if Transition != null and Transition.has_method("set_crt_discolor"):
		Transition.set_crt_discolor(enabled)

func _schedule_transition_discolor_after_impact() -> void:
	var delay := _get_transition_crt_burst_duration()
	if delay <= 0.0:
		_on_bird_strike_impact_window_finished()
		return

	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(Callable(self, "_on_bird_strike_impact_window_finished"), CONNECT_ONE_SHOT)

func _on_bird_strike_impact_window_finished() -> void:
	if not bird_strike_active:
		return
	if bird_strike_lock_timer <= 0.0:
		return
	_set_transition_crt_discolor(true)

func _get_transition_crt_burst_duration() -> float:
	if Transition != null and Transition.has_method("get_crt_glitch_burst_duration"):
		return float(Transition.call("get_crt_glitch_burst_duration"))
	return 0.0

func combo_counter_fade_out() -> void:
	"""Called when combo counter should fade out due to UI events (like ultimate)"""
	if combo_counter_node != null and is_instance_valid(combo_counter_node):
		if combo_counter_node.has_method("fade_out"):
			combo_counter_node.fade_out()
