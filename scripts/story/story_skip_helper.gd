extends RefCounted
class_name StorySkipHelper

const STORY_MENU_SCENE: String = "res://scenes/menus/story_menu.tscn"
const LOADING_SCREEN_SCENE: String = "res://scenes/core/loading_screen.tscn"


static func complete_chapter_and_return(owner: Node, chapter_number: int, bgm_fade_duration: float = 5.0) -> void:
	if owner == null or not owner.is_inside_tree():
		return

	Dialogic.current_state_info["skip_request_handled"] = true
	if Dialogic.current_timeline != null:
		await Dialogic.end_timeline(true)

	if owner.has_node("/root/StoryProgress"):
		StoryProgress.mark_chapter_completed(chapter_number)

	await go_to_scene(owner, STORY_MENU_SCENE, bgm_fade_duration)


static func skip_chapter_and_return(owner: Node, bgm_fade_duration: float = 5.0) -> void:
	await go_to_scene(owner, STORY_MENU_SCENE, bgm_fade_duration)


static func go_to_scene(owner: Node, scene_path: String, bgm_fade_duration: float = 5.0) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	if scene_path.is_empty():
		return

	Dialogic.current_state_info["skip_request_handled"] = true
	if Dialogic.current_timeline != null:
		await Dialogic.end_timeline(true)

	LoadingManager.set_target_scene(scene_path)
	await Transition.fade_out()
	if bgm_fade_duration >= 0.0:
		await AudioManager.stop_bgm(bgm_fade_duration)
	owner.get_tree().change_scene_to_file(LOADING_SCREEN_SCENE)
	await Transition.fade_in()
