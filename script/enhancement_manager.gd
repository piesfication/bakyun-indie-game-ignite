extends Node

const SAVE_PATH := "user://enhancements.cfg"

const TIER_MIN := 1
const TIER_MAX := 5

const OPTION_NONE := "none"
const OPTION_OVERDRIVE := "overdrive"
const OPTION_PIERCE := "pierce"
const OPTION_CHAIN := "chain"
const OPTION_NOVA := "nova"

const NOVA_SLOW_DURATION_MULTIPLIER := 1.5

var tier_selections: Dictionary = {
	1: OPTION_NONE,
	2: OPTION_NONE,
	3: OPTION_NONE,
	4: OPTION_NONE,
	5: OPTION_NONE,
}

func _ready() -> void:
	_load_state()

func get_tier_selection(tier: int) -> String:
	if not tier_selections.has(tier):
		return OPTION_NONE
	return String(tier_selections.get(tier, OPTION_NONE))

func set_tier_selection(tier: int, selection: String) -> void:
	if tier < TIER_MIN or tier > TIER_MAX:
		return

	var normalized := selection.to_lower()
	if normalized not in [OPTION_NONE, OPTION_OVERDRIVE, OPTION_PIERCE, OPTION_CHAIN, OPTION_NOVA]:
		normalized = OPTION_NONE

	tier_selections[tier] = normalized
	_save_state()

func clear_tier_selection(tier: int) -> void:
	set_tier_selection(tier, OPTION_NONE)

func is_tier_selected(tier: int, selection: String) -> bool:
	return get_tier_selection(tier) == selection.to_lower()

func get_tier1_selection() -> String:
	return get_tier_selection(1)

func set_tier1_selection(selection: String) -> void:
	set_tier_selection(1, selection)

func clear_tier1_selection() -> void:
	clear_tier_selection(1)

func is_tier1_selected(selection: String) -> bool:
	return is_tier_selected(1, selection)

func get_tier2_selection() -> String:
	return get_tier_selection(2)

func set_tier2_selection(selection: String) -> void:
	set_tier_selection(2, selection)

func clear_tier2_selection() -> void:
	clear_tier_selection(2)

func is_tier2_selected(selection: String) -> bool:
	return is_tier_selected(2, selection)

func get_overdrive_heal_amount() -> int:
	return 1 if is_tier1_selected(OPTION_OVERDRIVE) else 0

func should_overdrive_fill_random_combo() -> bool:
	return is_tier2_selected(OPTION_OVERDRIVE)

func get_pierce_damage_bonus_for(enemy: Node) -> int:
	if not is_tier1_selected(OPTION_PIERCE):
		return 0
	if not _is_slow_enemy(enemy):
		return 0
	return 1

func should_pierce_spawn_secondary_burst() -> bool:
	return is_tier2_selected(OPTION_PIERCE)

func get_chain_extra_bounces() -> int:
	return 1 if is_tier1_selected(OPTION_CHAIN) else 0

func should_prioritize_slow_for_chain() -> bool:
	return is_tier1_selected(OPTION_CHAIN)

func should_chain_last_hit_insta_kill() -> bool:
	return is_tier2_selected(OPTION_CHAIN)

func should_nova_shared_damage() -> bool:
	return is_tier1_selected(OPTION_NOVA)

func get_nova_slow_duration(base_duration: float) -> float:
	if not is_tier2_selected(OPTION_NOVA):
		return base_duration
	return base_duration * NOVA_SLOW_DURATION_MULTIPLIER

func _is_slow_enemy(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false

	if enemy.has_method("is_slow"):
		return enemy.call("is_slow") == true

	for prop in enemy.get_property_list():
		if String(prop.get("name", "")) == "slow_timer":
			return float(enemy.get("slow_timer")) > 0.0

	return false

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	var loaded_tiers: Dictionary = {}
	var loaded_tiers_variant: Variant = config.get_value("enhancements", "tier_selections", {})
	if typeof(loaded_tiers_variant) == TYPE_DICTIONARY:
		loaded_tiers = loaded_tiers_variant as Dictionary
	if not loaded_tiers.is_empty():
		for tier in range(TIER_MIN, TIER_MAX + 1):
			var tier_value: String = String(loaded_tiers.get(tier, loaded_tiers.get(str(tier), OPTION_NONE))).to_lower()
			tier_selections[tier] = tier_value

	for tier in range(TIER_MIN, TIER_MAX + 1):
		if not tier_selections.has(tier):
			tier_selections[tier] = OPTION_NONE

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("enhancements", "tier_selections", tier_selections)
	config.save(SAVE_PATH)
