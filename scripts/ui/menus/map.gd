extends Node2D

@export_range(0.0, 100.0, 0.1) var sky_float_amplitude: float = 12.0
@export_range(0.0, 100.0, 0.1) var cloud_float_amplitude: float = 20.0
@export_range(0.0, 100.0, 0.1) var world_float_amplitude: float = 7.0
@export_range(0.0, 100.0, 0.1) var panel_float_amplitude: float = 5.0
@export_range(0.1, 10.0, 0.01) var float_speed: float = 1.6
@export_range(0.0, TAU, 0.01) var phase_offset: float = PI * 0.65

@onready var sky = $SkyBackground
@onready var cloud = $CloudBackground
@onready var world = $SeaBackground
@onready var icon = $Map/Icon
@onready var iconshade = $Map/IconShadow
@onready var path = $Map/MapPath
@onready var panel_sprite = $Overlay/Panel/PanelSprite
@onready var panel = $Overlay/Panel

@export var tutorial_panel: Texture2D
@export var journey_panel: Texture2D
@export var endless_panel: Texture2D
@export var basecamp_panel: Texture2D

var _time_accum: float = 0.0
var _sky_position: Vector2
var _cloud_position: Vector2
var _world_position: Vector2
var _icon_position: Vector2
var _iconshade_position: Vector2
var _path_position: Vector2

@onready var overlay = $Overlay
@onready var title_label = $Overlay/Panel/Title
@onready var action_container = $Overlay/Panel/ActionContainer

var map_button_scene = preload("res://scenes/ui/map_button.tscn")
@onready var close_button = $Overlay/Panel/CloseButton

var location_data = {}

var title_position
var action_position

func _ready() -> void:
	title_position = title_label.position.y
	action_position = action_container.position.y
	
	close_button.pressed.connect(_on_close_pressed)
	location_data = {
		   "tutorial": {
			  "title": "\"Hehe~ First time here? Don't worry! I'll teach you everything you need to know.\"",
			  "description": "...",
			  "panel": tutorial_panel,
			  "actions": [
				 {"text": "Tutorial", "id": "tutorial"}
			  ]
		   },

		   "journey": {
			  "title": "\"Our next adventure is waiting! Let's see what surprises are hiding ahead!\"",
			  "description": "...",
			  "panel": journey_panel,
			  "actions": [
				 {"text": "Mission", "id": "mission"},
				 {"text": "Story", "id": "story"}
			  ]
		   },

		   "endless": {
			  "title": "\"Think you can keep up forever? Let's find out how long we can survive!\"",
			  "description": "...",
			  "panel": endless_panel,
			  "actions": [
				 {"text": "Endless", "id": "endless"}
			  ]
		   },

		   "basecamp": {
			  "title": "\"Home sweet home! Take a little break, look through our memories!\"",
			  "description": "...",
			  "panel": basecamp_panel,
			  "actions": [
				 #{"text": "Album", "id": "album"},
				 {"text": "Archive", "id": "archive"},
				 {"text": "Training", "id": "training"}
			  ]
		   }
	}
	
	for icon in $Map/Icon.get_children():
		icon.clicked.connect(_on_icon_clicked)
		
	_sky_position = sky.position
	_cloud_position = cloud.position
	_world_position = world.position
	_icon_position = icon.position
	_iconshade_position = iconshade.position
	_path_position = path.position

func _on_close_pressed():
	overlay.visible = false
	
func _on_icon_clicked(location_id):

	overlay.visible = true
	
	var data = location_data[location_id]
	var actions = data["actions"]
	print(actions)
	
	title_label.text = data["title"]
	
	title_label.position.y = title_position
	action_container.position.y = action_position
	
	if (location_id == "endless" or location_id == "tutorial"):
		title_label.position.y = title_position - 40
		action_container.position.y = action_position + 31
		
	panel_sprite.texture = data["panel"]
	
	for child in action_container.get_children():
		child.queue_free()
	
	for action in actions:
		var button = map_button_scene.instantiate()
		action_container.add_child(button)
		button.setup(
			action["text"],
			action["id"]
		)
		button.pressed.connect(_on_action_pressed)

func _on_action_pressed(action_id: String):
	print(action_id)
	
	match action_id:
		"mission":
			LoadingManager.set_target_scene("res://scenes/menus/level_menu.tscn")
			await Transition.fade_out()
			get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
			await Transition.fade_in()

		"story":
			LoadingManager.set_target_scene("res://scenes/menus/story_menu.tscn")
			await Transition.fade_out()
			get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
			await Transition.fade_in()

		"album":
			pass

		"archive":
			LoadingManager.set_target_scene("res://scenes/menus/archive.tscn")
			await Transition.fade_out()
			get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
			await Transition.fade_in()

		"training":
			pass

		"tutorial":
			LoadingManager.set_target_scene("res://scenes/gameplay/levels/tutorial.tscn")
			await Transition.fade_out()
			get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
			await Transition.fade_in()

		"endless":
			LoadingManager.set_target_scene("res://scenes/menus/endless/endless_menu.tscn")
			await Transition.fade_out()
			get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
			await Transition.fade_in()

func _process(delta: float) -> void:
	_time_accum += delta
	sky.position.y = _sky_position.y + sin(_time_accum * float_speed + phase_offset+ 3) * sky_float_amplitude
	#sky.position.x = _sky_position.x + sin(_time_accum * float_speed + phase_offset) * ba_float_amplitude
	cloud.position.y = _cloud_position.y + sin(_time_accum * float_speed + phase_offset + 5) * cloud_float_amplitude
	world.position.y = _world_position.y + sin(_time_accum * float_speed + phase_offset) * world_float_amplitude
	icon.position.y = _icon_position.y + sin(_time_accum * float_speed + phase_offset) * world_float_amplitude
	iconshade.position.y = _iconshade_position.y + sin(_time_accum * float_speed + phase_offset) * world_float_amplitude
	path.position.y = _path_position.y + sin(_time_accum * float_speed + phase_offset) * world_float_amplitude
