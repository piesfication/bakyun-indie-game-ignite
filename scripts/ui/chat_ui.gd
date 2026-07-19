extends Control

@onready var message = $ChatContainer/Control/Message
@onready var baku_portrait =$ChatContainer/BakuPortrait
@onready var yuna_portrait = $ChatContainer/YunaPortrait
@onready var bubble = $ChatContainer/Control/Bubble
@onready var bubble_container = $ChatContainer/Control
@onready var click_area = $ChatContainer/Control/Button
@onready var chat_container = $ChatContainer

var chat_base_scale : Vector2
var is_animating := false
var chat_base_position : Vector2

var chats = [
	{
		"speaker": "baku",
		"text": "What adventure are we going on today?"
	},
	{
		"speaker": "yuna",
		"text": "Hopefully nothing explodes today....."
	}
]

var bubble_left_position : Vector2
var msg_left_position : Vector2

var bubble_right_position = Vector2(58, 29)


var current_chat := 0

func _ready():
	chat_base_scale = chat_container.scale
	chat_base_position = chat_container.position
	click_area.pressed.connect(_on_click_area_pressed)
	bubble_left_position = bubble_container.position
	msg_left_position = message.position
	await get_tree().create_timer(1).timeout
	show_chat(current_chat)
	await appear()
	idle_pop()
	
func idle_pop():

	while true:

		await get_tree().create_timer(randf_range(2.5, 2.5)).timeout

		if is_animating:
			continue

		var tween = create_tween()

		tween.tween_property(
			chat_container,
			"scale",
			chat_base_scale * 1.1,
			0.12
		)

		tween.tween_property(
			chat_container,
			"scale",
			chat_base_scale,
			0.12
		)	

func show_chat(index:int):
	
	chat_container.visible = true
	var data = chats[index]

	message.text = data.text

	if data.speaker == "baku":

		bubble_container.position = bubble_left_position
		message.position = msg_left_position

		baku_portrait.visible = true
		yuna_portrait.visible = false

	else:

		bubble_container.position = bubble_right_position
		message.position = msg_left_position + Vector2(18, 0)

		baku_portrait.visible = false
		yuna_portrait.visible = true


func _on_click_area_pressed():

	if is_animating:
		return

	change_chat()
	
	
func disappear():

	is_animating = true

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		chat_container,
		"position",
		chat_base_position + Vector2(0, -20),
		0.2
	)

	tween.tween_property(
		chat_container,
		"modulate:a",
		0.0,
		0.2
	)

	await tween.finished

func appear():

	chat_container.position = chat_base_position + Vector2(0, 20)
	chat_container.modulate.a = 0

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		chat_container,
		"position",
		chat_base_position,
		0.2
	)

	tween.tween_property(
		chat_container,
		"modulate:a",
		1.0,
		0.2
	)

	await tween.finished

	is_animating = false
	
	var tween2 = create_tween()

	tween2.tween_property(
		chat_container,
		"scale",
		chat_base_scale * 1.1,
		0.12
	)

	tween2.tween_property(
		chat_container,
		"scale",
		chat_base_scale,
		0.12
	)	
	
func change_chat():

	is_animating = true

	await disappear()

	current_chat = (current_chat + 1) % chats.size()

	show_chat(current_chat)

	await appear()

	is_animating = false
