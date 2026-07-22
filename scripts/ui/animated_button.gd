extends TextureButton
class_name AnimatedButton

@export_range(1.0, 2.0, 0.01) var hover_scale_multiplier: float = 1.08
@export_range(0.1, 1.0, 0.01) var pressed_scale_multiplier: float = 0.9
@export_range(0.01, 1.0, 0.01, "suffix:s") var hover_duration: float = 0.12
@export_range(0.01, 1.0, 0.01, "suffix:s") var press_duration: float = 0.07
@export_range(0.01, 1.0, 0.01, "suffix:s") var release_duration: float = 0.16

var _base_scale: Vector2 = Vector2.ONE
var _is_hovered: bool = false
var _scale_tween: Tween = null


func _ready() -> void:
	_base_scale = scale
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not button_down.is_connected(_on_button_down):
		button_down.connect(_on_button_down)
	if not button_up.is_connected(_on_button_up):
		button_up.connect(_on_button_up)


func _exit_tree() -> void:
	_kill_scale_tween()


func _on_mouse_entered() -> void:
	_is_hovered = true
	_tween_to_scale(_base_scale * hover_scale_multiplier, hover_duration, Tween.TRANS_BACK, Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	_is_hovered = false
	_tween_to_scale(_base_scale, hover_duration, Tween.TRANS_BACK, Tween.EASE_OUT)


func _on_button_down() -> void:
	_tween_to_scale(_base_scale * pressed_scale_multiplier, press_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_up() -> void:
	var target_scale: Vector2 = _base_scale * hover_scale_multiplier if _is_hovered else _base_scale
	_tween_to_scale(target_scale, release_duration, Tween.TRANS_BACK, Tween.EASE_OUT)


func _tween_to_scale(target_scale: Vector2, duration: float, transition: Tween.TransitionType, easing: Tween.EaseType) -> void:
	if not is_inside_tree():
		scale = target_scale
		return
	_kill_scale_tween()
	_scale_tween = create_tween()
	_scale_tween.set_trans(transition)
	_scale_tween.set_ease(easing)
	_scale_tween.tween_property(self, "scale", target_scale, duration)


func _kill_scale_tween() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = null
