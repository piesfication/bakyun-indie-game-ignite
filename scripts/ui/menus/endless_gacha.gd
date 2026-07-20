extends Control

@export var card_scene : PackedScene
@onready var card_container = $CardContainer

var generated_cards : Array = []
const TOTAL_CARDS = 12  # Cukup untuk menutupi viewport + buffer
const WIN_INDEX = 30    # Index kartu winner saat spin (di luar viewport awal)
const CARD_WIDTH = 180

var winning_card : CardData

enum State { IDLE, SPINNING, DECELERATING, STOPPED }
var state : State = State.IDLE

var idle_speed : float = 80.0
var spin_speed : float = 1200.0
var current_speed : float = 0.0

var target_x : float = 0.0

@onready var click_area = $ClickArea
@onready var spin_label = $Label

# ─── Ready ───────────────────────────────────────────────────────────────────
func _ready():
	generate_cards_idle()
	state = State.IDLE
	current_speed = idle_speed
	click_area.gui_input.connect(_on_click_area_input)

# ─── Process ─────────────────────────────────────────────────────────────────
func _process(delta):
	match state:
		State.IDLE:
			card_container.position.x -= current_speed * delta
			_recycle_cards()
		State.SPINNING:
			card_container.position.x -= current_speed * delta

# ─── Recycling (untuk idle endless scroll) ───────────────────────────────────
func _recycle_cards():
	var leftmost = _get_leftmost_card()
	if leftmost == null:
		return
	# Kalau kartu paling kiri sudah keluar viewport kiri
	if card_container.position.x + leftmost.position.x < -CARD_WIDTH:
		var rightmost = _get_rightmost_card()
		leftmost.position.x = rightmost.position.x + CARD_WIDTH
		leftmost.setup(CardDatabase.get_random_card())
		leftmost.show_back()

func _get_leftmost_card() -> Node:
	var result = null
	var min_x = INF
	for card in generated_cards:
		if card.position.x < min_x:
			min_x = card.position.x
			result = card
	return result

func _get_rightmost_card() -> Node:
	var result = null
	var max_x = -INF
	for card in generated_cards:
		if card.position.x > max_x:
			max_x = card.position.x
			result = card
	return result

# ─── Generate kartu idle (semua random, jumlah kecil) ────────────────────────
func generate_cards_idle():
	for child in card_container.get_children():
		child.queue_free()
	generated_cards.clear()
	for i in range(TOTAL_CARDS):
		var card = card_scene.instantiate()
		card.position = Vector2(i * CARD_WIDTH, 230)
		card_container.add_child(card)
		card.setup(CardDatabase.get_random_card())
		card.show_back()
		generated_cards.append(card)

# ─── Generate kartu spin (banyak, winner disisipkan jauh di depan) ────────────
func generate_cards_spin(winner : CardData):
	for child in card_container.get_children():
		child.queue_free()
	generated_cards.clear()
	var spin_total = WIN_INDEX + 10  # Buffer setelah winner
	for i in range(spin_total):
		var card = card_scene.instantiate()
		card.position = Vector2(i * CARD_WIDTH, 230)
		card_container.add_child(card)
		if i == WIN_INDEX:
			card.setup(winner)
		else:
			card.setup(CardDatabase.get_random_card())
		card.show_back()
		generated_cards.append(card)

# ─── Start Spin ───────────────────────────────────────────────────────────────

func start_spin():
	if state != State.IDLE:
		return
		
	spin_label.text = ""  
	winning_card = CardDatabase.get_random_card()
	card_container.position.x = 0
	generate_cards_spin(winning_card)

	current_speed = spin_speed
	state = State.SPINNING

	# Tunggu satu frame supaya layout kartu sudah settled
	await get_tree().process_frame

	# Baru hitung target_x
	var viewport_center = get_viewport_rect().size.x / 2.0
	var winner_card = generated_cards[WIN_INDEX]
	print("size setelah frame: ", winner_card.size)
	var texture_padding_left = 130.0
	var padding_scaled = texture_padding_left
	target_x = viewport_center - winner_card.position.x - (winner_card.size.x / 2.0) - padding_scaled
	print("target_x baru: ", target_x)

	var decel_start_x = target_x + 800.0
	await _wait_until_position(decel_start_x)
	_begin_decelerate()
	
func _wait_until_position(threshold_x : float):
	while card_container.position.x > threshold_x:
		await get_tree().process_frame

# ─── Decelerate & Stop ────────────────────────────────────────────────────────
func _begin_decelerate():
	print("target_x saat decelerate: ", target_x)
	state = State.DECELERATING
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card_container, "position:x", target_x, 1.4)
	tween.tween_callback(_on_spin_stopped)

func _on_spin_stopped():
	state = State.STOPPED
	#var winner_card = generated_cards[WIN_INDEX]
	
	# Di _on_spin_stopped(), sebelum _reveal_winner()
	var winner_card = generated_cards[WIN_INDEX]
	var correct_target = get_viewport_rect().size.x / 2.0 - winner_card.position.x - winner_card.size.x / 2.0
	print("correct target_x: ", correct_target)
	print("current container x: ", card_container.position.x)
	
	print("global_position saat stop: ", winner_card.global_position)
	print("size saat stop: ", winner_card.size)
	print("position lokal winner: ", winner_card.position)
	print("container position: ", card_container.position)
	print("viewport size: ", get_viewport_rect().size)
	print("custom_minimum_size: ", winner_card.custom_minimum_size)
	print("get_combined_minimum_size: ", winner_card.get_combined_minimum_size())
	print("pivot_offset: ", winner_card.pivot_offset)
	print("front size: ", winner_card.get_node("Front").texture.get_size())
	print("back size: ", winner_card.get_node("Back").texture.get_size())
	
	await _reveal_winner()
	await get_tree().create_timer(2.0).timeout
	reset_to_idle()

func _reveal_winner():
	var winner_card = generated_cards[WIN_INDEX]

	# Fade out kartu lain
	for card in generated_cards:
		if card == winner_card:
			continue
		var t = create_tween()
		t.tween_property(card, "modulate:a", 0.0, 0.4)

	await get_tree().create_timer(0.4).timeout

	# Naikan z_index supaya render di atas semua
	winner_card.z_index = 10

	# Flip di tempat, tidak perlu pindah
	await winner_card.reveal()

	# Scale up dari scale asli (0.25) ke sedikit lebih besar
	var scale_target = Vector2(0.35, 0.35)  # tweak sesuai selera
	winner_card.pivot_offset = winner_card.size / 2.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(winner_card, "scale", scale_target, 0.5)

	await tween.finished
# ─── Reset ke Idle (panggil setelah reveal selesai) ──────────────────────────

func reset_to_idle():
	generate_cards_idle()
	card_container.position.x = 0
	current_speed = idle_speed
	state = State.IDLE
	spin_label.text = "Tap to Spin"
	

# ─── Klik area untuk start spin  ──────────────────────────

func _on_click_area_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_spin()
