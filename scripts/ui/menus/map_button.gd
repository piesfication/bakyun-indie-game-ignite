extends Control

signal pressed(action_id)

@onready var label = $Label
@onready var button = $TextureButton

var action_id := ""

func _ready():
	button.pressed.connect(_on_pressed)
	
func _on_pressed():
	pressed.emit(action_id)
	
func setup(text: String, id: String):
	label.text = text
	action_id = id
	
