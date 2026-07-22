extends Node

signal progress_changed

const SAVE_PATH := "user://story_progress.cfg"
const REQUIRED_WINS_PER_CHAPTER := 3
const MAX_CHAPTERS := 5
const MAX_PLAYER_LEVEL := 20
const MAIN_STORY_EXP_REWARD := 120
const SIDE_STORY_EXP_REWARD := 50
const MISSION_EXP_REWARDS := {
	"easy": 20,
	"medium": 35,
	"hard": 60
}
const LEVEL_TOTAL_EXP := [
	0,
	60,
	130,
	220,
	300,
	390,
	490,
	600,
	720,
	850,
	990,
	1140,
	1300,
	1470,
	1650,
	1840,
	2040,
	2250,
	2470,
	2700
]

var highest_visible_chapter: int = 1
var mission_progress: int = 0
var dialogic_saved_variables: Dictionary = {}
var dialogic_saved_from_chapter: int = 0
var completed_chapters: Dictionary = {}
var completed_side_stories: Dictionary = {}
var total_exp: int = 0

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

func is_chapter_completed(chapter_number: int) -> bool:
	return bool(completed_chapters.get(str(chapter_number), false))

func get_player_level() -> int:
	var current_level: int = 1
	for i in range(LEVEL_TOTAL_EXP.size()):
		if total_exp >= int(LEVEL_TOTAL_EXP[i]):
			current_level = i + 1
		else:
			break
	return clampi(current_level, 1, MAX_PLAYER_LEVEL)

func get_current_level_exp() -> int:
	var level: int = get_player_level()
	return maxi(total_exp - get_level_total_exp(level), 0)

func get_current_level_required_exp() -> int:
	var level: int = get_player_level()
	if level >= MAX_PLAYER_LEVEL:
		return 0
	return maxi(get_level_total_exp(level + 1) - get_level_total_exp(level), 0)

func get_level_total_exp(level: int) -> int:
	var index: int = clampi(level, 1, MAX_PLAYER_LEVEL) - 1
	return int(LEVEL_TOTAL_EXP[index])

func get_exp_debug_text() -> String:
	var level: int = get_player_level()
	if level >= MAX_PLAYER_LEVEL:
		return "LV %d  MAX" % level
	return "LV %d  EXP %d/%d" % [level, get_current_level_exp(), get_current_level_required_exp()]

func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	total_exp = maxi(total_exp + amount, 0)
	_save_state()
	progress_changed.emit()

func reset_level_exp() -> void:
	total_exp = 0
	completed_side_stories.clear()
	_save_state()
	progress_changed.emit()

func record_mission_win(difficulty: String = "easy") -> void:
	if highest_visible_chapter <= 1:
		add_exp(_get_mission_exp_reward(difficulty))
		return
	if mission_progress < REQUIRED_WINS_PER_CHAPTER:
		mission_progress += 1
		
	total_exp = maxi(total_exp + _get_mission_exp_reward(difficulty), 0)
	_save_state()
	progress_changed.emit()

func mark_chapter_completed(chapter_number: int) -> void:
	var was_completed: bool = is_chapter_completed(chapter_number)
	completed_chapters[str(chapter_number)] = true
	if not was_completed:
		total_exp = maxi(total_exp + MAIN_STORY_EXP_REWARD, 0)
	if chapter_number != highest_visible_chapter:
		_save_state()
		progress_changed.emit()
		return
	_capture_dialogic_variables(chapter_number)
	if highest_visible_chapter < MAX_CHAPTERS:
		highest_visible_chapter += 1
		mission_progress = 0
	_save_state()
	progress_changed.emit()

func mark_side_story_completed(side_story_id: String) -> void:
	var normalized_id := side_story_id.strip_edges()
	if normalized_id.is_empty():
		return
	if bool(completed_side_stories.get(normalized_id, false)):
		return
	completed_side_stories[normalized_id] = true
	total_exp = maxi(total_exp + SIDE_STORY_EXP_REWARD, 0)
	_save_state()
	progress_changed.emit()

func reset_progress() -> void:
	highest_visible_chapter = 1
	mission_progress = 0
	dialogic_saved_variables.clear()
	dialogic_saved_from_chapter = 0
	completed_chapters.clear()
	completed_side_stories.clear()
	total_exp = 0
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
	var has_saved_total_exp: bool = config.has_section_key("story", "total_exp")
	total_exp = int(config.get_value("story", "total_exp", 0))
	var loaded_completed_chapters: Variant = config.get_value("story", "completed_chapters", {})
	if typeof(loaded_completed_chapters) == TYPE_DICTIONARY:
		completed_chapters = (loaded_completed_chapters as Dictionary).duplicate(true)
	else:
		completed_chapters = {}
	var loaded_completed_side_stories: Variant = config.get_value("story", "completed_side_stories", {})
	if typeof(loaded_completed_side_stories) == TYPE_DICTIONARY:
		completed_side_stories = (loaded_completed_side_stories as Dictionary).duplicate(true)
	else:
		completed_side_stories = {}
	var loaded_dialogic_vars: Variant = config.get_value("dialogic", "saved_variables", {})
	if typeof(loaded_dialogic_vars) == TYPE_DICTIONARY:
		dialogic_saved_variables = (loaded_dialogic_vars as Dictionary).duplicate(true)
	else:
		dialogic_saved_variables = {}
	dialogic_saved_from_chapter = int(config.get_value("dialogic", "saved_from_chapter", 0))
	highest_visible_chapter = clampi(highest_visible_chapter, 1, MAX_CHAPTERS)
	mission_progress = clampi(mission_progress, 0, REQUIRED_WINS_PER_CHAPTER)
	dialogic_saved_from_chapter = clampi(dialogic_saved_from_chapter, 0, MAX_CHAPTERS)
	total_exp = maxi(total_exp, 0)
	_migrate_completed_chapters_from_visibility()
	if not has_saved_total_exp:
		_migrate_total_exp_from_completed_content()

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("story", "highest_visible_chapter", highest_visible_chapter)
	config.set_value("story", "mission_progress", mission_progress)
	config.set_value("story", "total_exp", total_exp)
	config.set_value("story", "completed_chapters", completed_chapters)
	config.set_value("story", "completed_side_stories", completed_side_stories)
	config.set_value("dialogic", "saved_variables", dialogic_saved_variables)
	config.set_value("dialogic", "saved_from_chapter", dialogic_saved_from_chapter)
	config.save(SAVE_PATH)

func _migrate_completed_chapters_from_visibility() -> void:
	for chapter_number in range(1, highest_visible_chapter):
		completed_chapters[str(chapter_number)] = true
	if dialogic_saved_from_chapter >= MAX_CHAPTERS:
		completed_chapters[str(MAX_CHAPTERS)] = true

func _migrate_total_exp_from_completed_content() -> void:
	total_exp = 0
	for chapter_number in range(1, MAX_CHAPTERS + 1):
		if is_chapter_completed(chapter_number):
			total_exp += MAIN_STORY_EXP_REWARD
	for side_story_id in completed_side_stories.keys():
		if bool(completed_side_stories.get(side_story_id, false)):
			total_exp += SIDE_STORY_EXP_REWARD

func _get_mission_exp_reward(difficulty: String) -> int:
	var normalized := difficulty.strip_edges().to_lower()
	return int(MISSION_EXP_REWARDS.get(normalized, MISSION_EXP_REWARDS["easy"]))
