extends CanvasLayer

@onready var thumbnail_container = $AlbumMenu/ScrollContainer/Content/VBoxContainer
@onready var preview_image = $AlbumMenu/Image
@onready var description = $AlbumMenu/DescriptionBox/Description
@onready var char = $AlbumMenu/DescriptionBox/Description2
@onready var start_button = $StartButton
@onready var scroll_container = $AlbumMenu/ScrollContainer
var current_thumbnail = null

@onready var album_layer = "."

@onready var album_button = $"../CanvasLayer/TV/Visual/AlbumButton"
@onready var close_album_button = $AlbumMenu/DescriptionBox/CloseButton

@onready var overlay = $Overlay
@onready var album_menu = $AlbumMenu

var float_time := 0.0

var desc_scale
var start_scale

var image_base_pos: Vector2
var desc_base_pos: Vector2
var button_base_pos: Vector2
var scroll_base_pos: Vector2

func _ready():
    
    image_base_pos = preview_image.position
    desc_base_pos = description_box.position
    button_base_pos = start_button.position
    scroll_base_pos = scroll_container.position
    
    desc_scale = description_box.scale
    start_scale = start_button.scale
    
    album_button.pressed.connect(_on_album_button_pressed)
    close_album_button.pressed.connect(_on_close_album_button_pressed)
    start_button.pressed.connect(_on_start_button_pressed)
    
    for thumbnail in thumbnail_container.get_children():
        thumbnail.thumbnail_pressed.connect(_on_thumbnail_pressed)
        thumbnail.deselect()
    
    var thumbnails = thumbnail_container.get_children()

    if thumbnails.size() > 0:
        _on_thumbnail_pressed(thumbnails[0])

func _on_start_button_pressed():
    if current_thumbnail == null:
        return

    LoadingManager.set_target_scene(current_thumbnail.timeline)
    
    await Transition.fade_out()
    await AudioManager.stop_bgm(5)
    get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
    await Transition.fade_in()
    
func _on_thumbnail_pressed(thumbnail):
    
    if is_transitioning:
       return
    
    if !thumbnail.unlocked:
        Transition.play_crt_glitch_burst()
        thumbnail.play_locked_feedback()
        #show_locked_message()
        return
    if current_thumbnail != null:
        current_thumbnail.deselect()

    current_thumbnail = thumbnail
    current_thumbnail.select()

    change_album_content(
           current_thumbnail.preview_texture,
           current_thumbnail.description
    )
    #animate_info_panel()
    description.text = current_thumbnail.description
    char.text = current_thumbnail.char

func _show_locked_message():
    print("Memory Locked")
    
var is_transitioning := false

func _on_album_button_pressed():
    open_album()
    
func _on_close_album_button_pressed():
    close_album()
    
func open_album():
    visible = true

    overlay.modulate.a = 0.0
    album_menu.modulate.a = 0.0

    var tween = create_tween()

    tween.tween_property(overlay, "modulate:a", 0.75, 0.05)
    tween.parallel().tween_property(album_menu, "modulate:a", 1.0, 0.1)
    
func close_album():
    var tween = create_tween()

    tween.tween_property(overlay, "modulate:a", 0.0, 0.05)
    tween.parallel().tween_property(album_menu, "modulate:a", 0.0, 0.1)

    await tween.finished

    visible = false
    
var _preview_tween: Tween
var _transition_tween: Tween

func change_album_content(texture: Texture2D, desc: String):
    
    if is_transitioning:
       return

    is_transitioning = true
    
    if _transition_tween:
        _transition_tween.kill()

    var image_pos = preview_image.position
    var desc_pos = description_box.position
    var button_pos = start_button.position

    _transition_tween = create_tween()
    _transition_tween.set_parallel(true)

    # ===== Keluar =====
    _transition_tween.tween_property(preview_image, "position:y", image_pos.y - 30, 0.2)
    _transition_tween.tween_property(preview_image, "modulate:a", 0.0, 0.2)

    _transition_tween.tween_property(description_box, "position:y", desc_pos.y - 30, 0.4)
    _transition_tween.tween_property(description_box, "modulate:a", 0.0, 0.4)

    _transition_tween.tween_property(start_button, "position:y", button_pos.y - 30, 0.5)
    _transition_tween.tween_property(start_button, "modulate:a", 0.0, 0.5)

    await _transition_tween.finished

    # ===== Ganti konten =====
    preview_image.texture = texture
    description.text = desc

    preview_image.position.y = image_pos.y + 30
    description_box.position.y = desc_pos.y + 30
    start_button.position.y = button_pos.y + 30

    preview_image.modulate.a = 0.0
    description_box.modulate.a = 0.0
    start_button.modulate.a = 0.0

    _transition_tween = create_tween()
    _transition_tween.set_parallel(true)

    # ===== Masuk =====
    _transition_tween.tween_property(preview_image, "position:y", image_pos.y, 0.2)
    _transition_tween.tween_property(preview_image, "modulate:a", 1.0, 0.2)

    _transition_tween.tween_property(description_box, "position:y", desc_pos.y, 0.4)
    _transition_tween.tween_property(description_box, "modulate:a", 1.0, 0.4)

    _transition_tween.tween_property(start_button, "position:y", button_pos.y, 0.5)
    _transition_tween.tween_property(start_button, "modulate:a", 1.0, 0.5)
    
    await _transition_tween.finished
    is_transitioning = false
    
var _ui_tween: Tween

@onready var description_box = $AlbumMenu/DescriptionBox

func animate_info_panel():
    if _ui_tween:
        _ui_tween.kill()

    description_box.scale = desc_scale
    start_button.scale = start_scale

    _ui_tween = create_tween()
    _ui_tween.set_parallel(true)

    # Squash
    _ui_tween.tween_property(description_box, "scale", desc_scale * Vector2(0.96, 1.04), 0.10)
    _ui_tween.parallel().tween_property(start_button, "scale", start_scale * Vector2(0.96, 1.04), 0.10)

    # Stretch balik
    _ui_tween.chain().tween_property(description_box, "scale",  desc_scale * Vector2(1.04, 0.96), 0.10)
    _ui_tween.parallel().tween_property(start_button, "scale", start_scale *Vector2(1.04, 0.96), 0.10)

    # Normal
    _ui_tween.chain().tween_property(description_box, "scale", desc_scale * Vector2.ONE, 0.10)
    _ui_tween.parallel().tween_property(start_button, "scale", start_scale * Vector2.ONE, 0.10)



@export var float_speed := 0.6
@export var image_float_amp := 6.0
@export var desc_float_amp := 4.0
@export var button_float_amp := 3.0
@export var scroll_float_amp := 2.0

func _process(delta):
    
    float_time += delta
    
    var mouse = get_viewport().get_mouse_position()
    var viewport_size = get_viewport().get_visible_rect().size
    var center = viewport_size * 0.5

    var offset = (mouse - center) / center

    var image_float = sin(float_time * TAU * float_speed) * image_float_amp
    var desc_float = sin(float_time * TAU * float_speed + 0.5) * desc_float_amp
    var button_float = sin(float_time * TAU * float_speed + 0.9) * button_float_amp
    var scroll_float = sin(float_time * TAU * float_speed + 1.4) * scroll_float_amp
    
    preview_image.position = preview_image.position.lerp(
           image_base_pos
           + offset * 12
           + Vector2(0, image_float),
           delta * 8
    )
    
    description_box.position = description_box.position.lerp(
           desc_base_pos
           + offset * 8
           + Vector2(0, desc_float),
           delta * 8
    )
    
    start_button.position = start_button.position.lerp(
           button_base_pos
           + offset * 6
           + Vector2(0, button_float),
           delta * 8
    )       
    
    scroll_container.position = scroll_container.position.lerp(
           scroll_base_pos
           - offset * 4
           + Vector2(0, scroll_float),
           delta * 8
    )       
    
