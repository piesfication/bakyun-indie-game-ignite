extends Control

const TIER_1_OPTIONS: Array[String] = [
	EnhancementManager.OPTION_NONE,
	EnhancementManager.OPTION_OVERDRIVE,
	EnhancementManager.OPTION_PIERCE,
	EnhancementManager.OPTION_CHAIN,
	EnhancementManager.OPTION_NOVA,
]

const MENU_LEVEL_PATH := "res://scenes/menus/level_menu.tscn"
const MENU_STORY_PATH := "res://scenes/menus/story_menu.tscn"
const TIER_OPTIONS: Array[String] = [
	EnhancementManager.OPTION_NONE,
	EnhancementManager.OPTION_OVERDRIVE,
	EnhancementManager.OPTION_PIERCE,
	EnhancementManager.OPTION_CHAIN,
	EnhancementManager.OPTION_NOVA,
]

var _status_label: Label
var _option_buttons: Dictionary = {}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.09, 0.14, 1.0)
	add_child(background)

	var root := MarginContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 32)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 32)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	outer.add_child(vbox)

	var title := Label.new()
	title.text = "Enhancement Debug"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "F3 from title screen also opens this scene"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)

	var nav_row := HBoxContainer.new()
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_row.add_theme_constant_override("separation", 12)
	vbox.add_child(nav_row)

	nav_row.add_child(_make_nav_button("Go to Level Menu", Callable(self, "_open_level_menu")))
	nav_row.add_child(_make_nav_button("Go to Story Menu", Callable(self, "_open_story_menu")))
	nav_row.add_child(_make_nav_button("Go to Title", Callable(self, "_open_title_screen")))

	_build_tier_section(vbox, 1, "Tier 1 Enhancement", "Disable Tier 1")
	_build_tier_section(vbox, 2, "Tier 2 Enhancement", "Disable Tier 2")

	var footer := Label.new()
	footer.text = "Enhancement state is saved to user://enhancements.cfg"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.modulate = Color(0.8, 0.82, 0.9, 1.0)
	vbox.add_child(footer)

func _make_nav_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 42)
	button.pressed.connect(callback)
	return button

func _refresh_ui() -> void:
	var current_tier1 := EnhancementManager.get_tier1_selection()
	var current_tier2 := EnhancementManager.get_tier2_selection()
	_status_label.text = "Tier 1: %s | Tier 2: %s" % [current_tier1.to_upper(), current_tier2.to_upper()]

	for tier in [1, 2]:
		var current := EnhancementManager.get_tier_selection(tier)
		for option in TIER_OPTIONS:
			var button: Button = _option_buttons.get(_button_key(tier, option), null)
			if button == null:
				continue
			button.text = _option_label(option, tier)
			button.button_pressed = option == current

func _build_tier_section(parent: VBoxContainer, tier: int, title_text: String, disable_button_text: String) -> void:
	var tier_label := Label.new()
	tier_label.text = title_text
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 24)
	parent.add_child(tier_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for option in TIER_OPTIONS:
		var option_name := option
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(func() -> void:
			_set_tier(tier, option_name)
		)
		_option_buttons[_button_key(tier, option_name)] = button
		grid.add_child(button)

	var clear_button := Button.new()
	clear_button.text = disable_button_text
	clear_button.custom_minimum_size = Vector2(0, 48)
	clear_button.pressed.connect(func() -> void:
		_clear_tier(tier)
	)
	parent.add_child(clear_button)

func _button_key(tier: int, option: String) -> String:
	return "%d:%s" % [tier, option]

func _option_label(option: String, tier: int) -> String:
	match option:
		EnhancementManager.OPTION_NONE:
			return "None"
		EnhancementManager.OPTION_OVERDRIVE:
			return "T%d Overdrive" % tier + (" - heal 1 HP after instakill" if tier == 1 else " - refill random combo")
		EnhancementManager.OPTION_PIERCE:
			return "T%d Pierce" % tier + (" - +1 damage vs slowed enemies" if tier == 1 else " - spawn secondary burst on first hit")
		EnhancementManager.OPTION_CHAIN:
			return "T%d Chain" % tier + (" - prioritize slowed targets, +1 bounce" if tier == 1 else " - final bounce instakill")
		EnhancementManager.OPTION_NOVA:
			return "T%d Nova" % tier + (" - shared damage on slowed enemies" if tier == 1 else " - longer slow duration")
		_:
			return option.capitalize()

func _set_tier(tier: int, option: String) -> void:
	EnhancementManager.set_tier_selection(tier, option)
	_refresh_ui()

func _clear_tier(tier: int) -> void:
	EnhancementManager.clear_tier_selection(tier)
	_refresh_ui()

func _open_level_menu() -> void:
	Current.setcurrentmode("Level")
	get_tree().change_scene_to_file(MENU_LEVEL_PATH)

func _open_story_menu() -> void:
	Current.setcurrentmode("Story")
	get_tree().change_scene_to_file(MENU_STORY_PATH)

func _open_title_screen() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
