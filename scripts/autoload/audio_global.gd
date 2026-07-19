extends Node

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var _current_bgm_path: String = ""
var _pending_bgm_path: String = ""
var _is_transitioning := false
var _fade_tween: Tween

var _pause_position: float = 0.0

func pause_bgm(fade_time: float = 0.5):
	if not background_music.playing:
		return
	
	# kill tween lama kalau ada
	if _fade_tween:
		_fade_tween.kill()
	
	_is_transitioning = true
	
	# simpan posisi
	_pause_position = background_music.get_playback_position()
	
	# fade out
	_fade_tween = create_tween()
	_fade_tween.tween_property(background_music, "volume_db", -80, fade_time)
	await _fade_tween.finished
	
	background_music.stop()
	_is_transitioning = false

func is_bgm_playing() -> bool:
	return background_music.playing

func get_current_bgm_path() -> String:
	return _current_bgm_path
	
func resume_bgm(fade_time: float = 0.5):
	if _current_bgm_path == "":
		return
	
	# kill tween lama kalau ada
	if _fade_tween:
		_fade_tween.kill()
	
	_is_transitioning = true
	
	background_music.stream = load(_current_bgm_path)
	background_music.volume_db = -80
	background_music.play(_pause_position)
	
	# fade in
	_fade_tween = create_tween()
	_fade_tween.tween_property(background_music, "volume_db", 0, fade_time)
	await _fade_tween.finished
	
	_is_transitioning = false
# ========================
# 🎧 BGM SYSTEM
# ========================

func play_bgm(
	path: String,
	fade_time: float = 1.5,
	use_fade_out: bool = true,
	use_fade_in: bool = true
) -> void:
	
	# ❌ jangan restart lagu yang sama kalau memang masih sedang main
	if _current_bgm_path == path and background_music.playing:
		return
	
	# Kalau ada transisi yang masih berjalan, simpan request terakhir dan mainkan
	# setelah transisi selesai.
	if _is_transitioning:
		_pending_bgm_path = path
		return
	
	_is_transitioning = true
	
	var new_stream = load(path)
	background_music.bus = "Music"
	
	# ========================
	# 🎧 FIRST PLAY
	# ========================
	if not background_music.playing:
		background_music.stream = new_stream
		
		if use_fade_in:
			background_music.volume_db = -80
			background_music.play()
			
			_fade_tween = create_tween()
			_fade_tween.tween_property(background_music, "volume_db", 0, fade_time)
			await _fade_tween.finished
		else:
			background_music.volume_db = 0
			background_music.play()
	
	# ========================
	# 🔁 SWITCH BGM
	# ========================
	else:
		# kill tween lama kalau ada
		if _fade_tween:
			_fade_tween.kill()
		
		# fade out
		if use_fade_out:
			_fade_tween = create_tween()
			_fade_tween.tween_property(background_music, "volume_db", -80, fade_time)
			await _fade_tween.finished
		else:
			background_music.stop()
		
		# ganti lagu
		background_music.stream = new_stream
		
		# fade in atau langsung
		if use_fade_in:
			background_music.volume_db = -80
			background_music.play()
			
			_fade_tween = create_tween()
			_fade_tween.tween_property(background_music, "volume_db", 0, fade_time)
			await _fade_tween.finished
		else:
			background_music.volume_db = 0
			background_music.play()
	
	_current_bgm_path = path
	_is_transitioning = false

	if _pending_bgm_path != "" and _pending_bgm_path != _current_bgm_path:
		var next_bgm_path := _pending_bgm_path
		_pending_bgm_path = ""
		await play_bgm(next_bgm_path, fade_time, use_fade_out, use_fade_in)
	else:
		_pending_bgm_path = ""


func stop_bgm(fade_time: float = 1.0):
	if _fade_tween:
		_fade_tween.kill()

	_is_transitioning = true
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(background_music, "volume_db", -80, fade_time)
	
	await _fade_tween.finished
	
	background_music.stop()
	background_music.volume_db = 0
	_current_bgm_path = ""
	_is_transitioning = false

	if _pending_bgm_path != "":
		var next_bgm_path := _pending_bgm_path
		_pending_bgm_path = ""
		await play_bgm(next_bgm_path, 0.01, false, false)


func set_bgm_volume(volume: float):
	var tw = create_tween()
	tw.tween_property(background_music, "volume_db", linear_to_db(volume), 1.0)


# ========================
# 🔊 SFX SYSTEM
# ========================

func start_sfx(
	sfx_position: Node,
	sfx_path: String,
	pitch_randomizer: Array = [1,1],
	volume: float = 0
) -> void:
	var speaker = AudioStreamPlayer2D.new()
	sfx_position.add_child(speaker)
	
	speaker.stream = load(sfx_path)
	speaker.bus = "SFX"
	speaker.pitch_scale = randf_range(pitch_randomizer[0], pitch_randomizer[1])
	speaker.volume_db = volume
	speaker.play()
	
	await speaker.finished
	speaker.queue_free()


func start_ui_sfx(
	sfx_path: String,
	pitch_randomizer: Array = [1,1],
	volume: float = 0
) -> void:
	var speaker = AudioStreamPlayer.new()
	add_child(speaker)
	
	speaker.stream = load(sfx_path)
	speaker.bus = "SFX"
	speaker.pitch_scale = randf_range(pitch_randomizer[0], pitch_randomizer[1])
	speaker.volume_db = volume
	speaker.play()
	
	await speaker.finished
	speaker.queue_free()


func play_ui_sfx_with_pitch(
	sfx_path: String,
	pitch_scale: float = 1.0,
	volume_db: float = 0.0
) -> void:
	if sfx_path.is_empty():
		return

	var speaker := AudioStreamPlayer.new()
	add_child(speaker)

	var stream := load(sfx_path)
	if stream == null:
		speaker.queue_free()
		return

	speaker.stream = stream
	speaker.bus = "SFX"
	speaker.pitch_scale = maxf(pitch_scale, 0.01)
	speaker.volume_db = volume_db
	speaker.play()
	speaker.finished.connect(func():
		if is_instance_valid(speaker):
			speaker.queue_free()
	)

func play_bgm_sequence(
	bgm1_path: String,
	bgm2_path: String,
	delay: float
) -> void:
	
	# hentikan apapun yang sedang jalan
	if _fade_tween:
		_fade_tween.kill()
	
	_is_transitioning = true
	
	# ========================
	# ▶️ PLAY BGM 1
	# ========================
	background_music.stream = load(bgm1_path)
	background_music.volume_db = 0
	background_music.bus = "Music"
	background_music.play()
	
	_current_bgm_path = bgm1_path
	
	# tunggu sampai selesai
	await background_music.finished
	
	# ========================
	# ⏱️ DELAY
	# ========================
	await get_tree().create_timer(delay).timeout
	
	# ========================
	# ▶️ PLAY BGM 2
	# ========================
	background_music.stream = load(bgm2_path)
	background_music.play()
	
	_current_bgm_path = bgm2_path
	_is_transitioning = false
