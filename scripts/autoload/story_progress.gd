extends Node

signal progress_changed

const SAVE_PATH := "user://story_progress.cfg"
const REQUIRED_WINS_PER_CHAPTER := 3
const MAX_CHAPTERS := 5

var highest_visible_chapter: int = 1
var mission_progress: int = 0
var dialogic_saved_variables: Dictionary = {}
var dialogic_saved_from_chapter: int = 0

func _ready() -> void:
	_load_state()

func get_visible_chapter_limit() -> int:
	return highest_visible_chapter

func is_chapter_visible(chapter_number: int) -> bool:
	return chapter_number <= highest_visible_chapter

func is_chapter_unlocked(chapter_number: int) -> bool:
	if chapter_number <= 1:
		return true
	if chapter_number < highest_visible_chapter:
		return true
	# Final chapter unlocks immediately after Chapter 4 completion.
	if chapter_number == MAX_CHAPTERS and is_chapter_visible(chapter_number):
		return true
	if chapter_number == highest_visible_chapter:
		return mission_progress >= REQUIRED_WINS_PER_CHAPTER
	return false

func is_chapter_locked(chapter_number: int) -> bool:
	return is_chapter_visible(chapter_number) and not is_chapter_unlocked(chapter_number)

func get_chapter_progress_text(chapter_number: int) -> String:
	if chapter_number <= 1:
		return ""
	if not is_chapter_visible(chapter_number):
		return "Hey, you’re skipping ahead. Finish the last chapter first."
	if is_chapter_unlocked(chapter_number):
		return ""
	return "We’re not done yet. Complete 3 missions! (%d/%d)" % [mission_progress, REQUIRED_WINS_PER_CHAPTER]

func get_confirm_button_text(chapter_number: int) -> String:
	if is_chapter_locked(chapter_number):
		return "LOCKED"
	return "WE BALL!"

func record_mission_win() -> void:
	if highest_visible_chapter <= 1:
		return
	if mission_progress >= REQUIRED_WINS_PER_CHAPTER:
		return
		
	mission_progress += 1
	_save_state()
	progress_changed.emit()

func mark_chapter_completed(chapter_number: int) -> void:
	if chapter_number != highest_visible_chapter:
		return
	_capture_dialogic_variables(chapter_number)
	if highest_visible_chapter < MAX_CHAPTERS:
		highest_visible_chapter += 1
		mission_progress = 0
	_save_state()
	progress_changed.emit()

func reset_progress() -> void:
	highest_visible_chapter = 1
	mission_progress = 0
	dialogic_saved_variables.clear()
	dialogic_saved_from_chapter = 0
	_reset_dialogic_variables_to_default()
	_save_state()
	progress_changed.emit()

func _reset_dialogic_variables_to_default() -> void:
	if not has_node("/root/Dialogic"):
		return
	if typeof(Dialogic.current_state_info) != TYPE_DICTIONARY:
		return

	Dialogic.current_state_info["variables"] = ProjectSettings.get_setting("dialogic/variables", {}).duplicate(true)

func apply_saved_dialogic_variables() -> void:
	if dialogic_saved_variables.is_empty():
		return
	if not has_node("/root/Dialogic"):
		return
	if typeof(Dialogic.current_state_info) != TYPE_DICTIONARY:
		return

	Dialogic.current_state_info["variables"] = dialogic_saved_variables.duplicate(true)

func _capture_dialogic_variables(chapter_number: int) -> void:
	if not has_node("/root/Dialogic"):
		return
	if typeof(Dialogic.current_state_info) != TYPE_DICTIONARY:
		return

	var raw_vars: Variant = Dialogic.current_state_info.get("variables", {})
	if typeof(raw_vars) != TYPE_DICTIONARY:
		return

	dialogic_saved_variables = (raw_vars as Dictionary).duplicate(true)
	dialogic_saved_from_chapter = maxi(dialogic_saved_from_chapter, chapter_number)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	highest_visible_chapter = int(config.get_value("story", "highest_visible_chapter", 1))
	mission_progress = int(config.get_value("story", "mission_progress", 0))
	var loaded_dialogic_vars: Variant = config.get_value("dialogic", "saved_variables", {})
	if typeof(loaded_dialogic_vars) == TYPE_DICTIONARY:
		dialogic_saved_variables = (loaded_dialogic_vars as Dictionary).duplicate(true)
	else:
		dialogic_saved_variables = {}
	dialogic_saved_from_chapter = int(config.get_value("dialogic", "saved_from_chapter", 0))
	highest_visible_chapter = clampi(highest_visible_chapter, 1, MAX_CHAPTERS)
	mission_progress = clampi(mission_progress, 0, REQUIRED_WINS_PER_CHAPTER)
	dialogic_saved_from_chapter = clampi(dialogic_saved_from_chapter, 0, MAX_CHAPTERS)

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("story", "highest_visible_chapter", highest_visible_chapter)
	config.set_value("story", "mission_progress", mission_progress)
	config.set_value("dialogic", "saved_variables", dialogic_saved_variables)
	config.set_value("dialogic", "saved_from_chapter", dialogic_saved_from_chapter)
	config.save(SAVE_PATH)
