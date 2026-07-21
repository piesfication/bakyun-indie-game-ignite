extends Node2D

signal chapter_selected(chapter_name: String)

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

const GRAYSCALE_SHADER: Shader = preload("res://shaders/crosshair_grayscale.gdshader")

var _is_selected: bool = false
var _is_completed: bool = false
var _sprite_base_material: Material = null
var _grayscale_material: ShaderMaterial = null

func _ready() -> void:
	visible = false
	_sprite_base_material = _anim.material
	_anim.play("idle")

func set_completed(completed: bool) -> void:
	_is_completed = completed
	if _anim == null or not is_instance_valid(_anim):
		return
	if _is_completed:
		if _grayscale_material == null:
			_setup_grayscale_material()
		_anim.material = _grayscale_material
	else:
		_anim.material = _sprite_base_material

func activate() -> void:
	visible = true
	_anim.play("popup")
	await _anim.animation_finished
	_anim.play("idle")

func deactivate() -> void:
	_is_selected = false
	_anim.stop()
	visible = false

func on_selected() -> void:
	_is_selected = true
	_anim.play("clicked")
	await _anim.animation_finished
	_anim.play("idle_after_clicked")

func on_deselected() -> void:
	_is_selected = false
	_anim.play("return_to_idle")
	await _anim.animation_finished
	_anim.play("idle")

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chapter_selected.emit(name)

func _setup_grayscale_material() -> void:
	_grayscale_material = ShaderMaterial.new()
	_grayscale_material.shader = GRAYSCALE_SHADER
	_grayscale_material.set_shader_parameter("grayscale_amount", 1.0)
