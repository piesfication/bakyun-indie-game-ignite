extends Control

signal thumbnail_pressed(thumbnail)

@export var selected_texture: Texture2D
@export var deselected_texture: Texture2D
@export var preview_texture: Texture2D
@export var timeline: String

@export var unlocked: bool = false
@export var locked_texture: Texture2D

@export_multiline var description: String
@export_multiline var char: String

@onready var thumbnail = $Content/Thumbnail
@onready var button = $TextureButton

@onready var content = $Content

var _base_position: Vector2
var _shake_tween: Tween
var _hover_tween: Tween

var _content_base_pos: Vector2

    
func _ready():
    _content_base_pos = content.position
    _base_position = content.position
    button.pressed.connect(_on_button_pressed)
   
    button.mouse_entered.connect(_on_mouse_entered)
    button.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
    if _hover_tween:
        _hover_tween.kill()

    _hover_tween = create_tween()
    _hover_tween.set_parallel(true)

    _hover_tween.tween_property(content, "scale", Vector2.ONE * 1.05, 0.08)
    _hover_tween.tween_property(content, "position:y", _content_base_pos.y - 6, 0.08)


func _on_mouse_exited():
    if _hover_tween:
        _hover_tween.kill()

    _hover_tween = create_tween()
    _hover_tween.set_parallel(true)

    _hover_tween.tween_property(content, "scale", Vector2.ONE, 0.08)
    _hover_tween.tween_property(content, "position:y", _content_base_pos.y, 0.08)
    
func play_locked_feedback():
    if _shake_tween:
        _shake_tween.kill()

    content.position = _base_position

    _shake_tween = create_tween()

    _shake_tween.tween_property(content, "position:x", _base_position.x - 10, 0.03)
    _shake_tween.tween_property(content, "position:x", _base_position.x + 10, 0.03)
    _shake_tween.tween_property(content, "position:x", _base_position.x - 8, 0.025)
    _shake_tween.tween_property(content, "position:x", _base_position.x + 8, 0.025)
    _shake_tween.tween_property(content, "position:x", _base_position.x, 0.02)

func select():
    if !unlocked:
        return
        
    thumbnail.texture = selected_texture

func deselect():
    
    if (unlocked == false) :
        thumbnail.texture = locked_texture
        return
        
    thumbnail.texture = deselected_texture

func _on_button_pressed():
    print("Thumbnail clicked!")
    thumbnail_pressed.emit(self)
