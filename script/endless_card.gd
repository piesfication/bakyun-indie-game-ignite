extends Control

@onready var front = $Front
@onready var back = $Back
@export var card_data : CardData

func _ready():
    if card_data:
        setup(card_data)
        show_front()

func setup(data):
    card_data = data
    front.texture = data.front_texture
    back.texture = data.back_texture

func show_back():
    front.visible = false
    back.visible = true

func show_front():
    front.visible = true
    back.visible = false

func reveal() -> Signal:
    pivot_offset = size / 2.0
    scale = Vector2(0.25, 0.25)
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(self, "scale:x", 0.0, 0.5)
    tween.tween_callback(show_front)
    tween.tween_property(self, "scale:x", 0.25, 0.5)
    
    return tween.finished
