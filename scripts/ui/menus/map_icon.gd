extends Area2D
signal clicked(location_id)

@export var hover_scale := 1.2
@export var animation_time := 0.1
@export var location_id := ""

var _base_scale: Vector2

func _ready():
	
	_base_scale = scale

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		clicked.emit(location_id)
		
func _on_mouse_entered():
	create_tween().tween_property(
		self,
		"scale",
		_base_scale * hover_scale,
		animation_time
	)


func _on_mouse_exited():
	create_tween().tween_property(
		self,
		"scale",
		_base_scale,
		animation_time
	)
