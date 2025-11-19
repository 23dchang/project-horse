class_name ActionHandler
extends Node

# Selection tracking - array of arrays
# Each player has their own array: [[skill0, skill1, skill2], [skill0, skill1, skill2]]
var player_selections: Array = [] # Array of Arrays of SkillSlots
var players_ref: Array = [] # Reference to player entities

# Boss skills visible during selection phase
var boss_skills: Array = [] # Array of SkillSlots

# Track original skill decks for refreshing
var original_skill_pool: Dictionary = { } # player -> original skills array

# Signals
signal all_selections_complete
signal combat_start_requested


# Setup skill selection for multiple players
func setup_selection(players: Array):
	player_selections.clear()
	players_ref = players

	# Initialize empty arrays for each player
	for player in players:
		# Refresh skill pool if empty
		if player.skills.is_empty():
			_refresh_skill_pool(player)

		var player_slots: Array = []
		for i in range(player.max_skill_slots):
			player_slots.append(null)
		player_selections.append(player_slots)


# Store original skill pool for a player (call this during battle setup)
func store_original_pool(player: Entity):
	if player not in original_skill_pool:
		original_skill_pool[player] = player.skills.duplicate()


# Refresh a player's skill pool back to their full
func _refresh_skill_pool(player: Entity):
	if player in original_skill_pool:
		player.skills = original_skill_pool[player].duplicate()


# Set boss skills (called by BattleManager after boss AI selects)
func set_boss_skills(skills: Array):
	boss_skills = skills


# TODO: Should be called by UI when the player picks/changes a skill for a specific slot
func set_skill_for_slot(
		player_index: int,
		slot_index: int,
		skill: Skill, \
		target_slot_index: int,
) -> bool:
	# Input Validation
	if player_index < 0 or player_index >= player_selections.size():
		print("Error: Invalid player index %d" % player_index)
		return false

	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		print("Error: Invalid slot index %d for player %d" % [slot_index, player_index])
		return false

	var player = players_ref[player_index]

	# Validates that the skill belongs to this player's available pool
	if skill not in player.skills:
		print("Error: Skill not in player's available pool")
		return false

	# Create skill slot targeting the boss
	# source_slot_index = where this skill sits in player's skill queue
	# target_slot_index = which boss slot this targets
	var skill_slot = SkillSlot.new(
		player, # user
		skill, # skill being used
		slot_index, # source_slot_index (where player places it)
		target_slot_index, # target_slot_index (which boss slot to hit)
		-1, # target_player_index (only used by the boss)
		boss_skills[0].user if boss_skills.size() > 0 else null, # target_entity (boss)
	)

	# Remove the skill from the available pool
	player.skills.erase(skill)

	# Set the new skill slot
	player_selections[player_index][slot_index] = skill_slot

	# Check if all slots are filled
	_check_if_complete()

	return true


# Clear a specific slot (for retargeting/reselection)
func clear_slot(player_index: int, slot_index: int) -> bool:
	if player_index < 0 or player_index >= player_selections.size():
		return false

	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		return false

	var old_skill_slot = player_selections[player_index][slot_index]

	# Return the skill to the pool
	if old_skill_slot != null:
		players_ref[player_index].skills.append(old_skill_slot.skill)

	player_selections[player_index][slot_index] = null
	return true


# Get the current skill slot (for UI display)
func get_slot_skill(player_index: int, slot_index: int):
	if player_index < 0 or player_index >= player_selections.size():
		return null

	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		return null

	return player_selections[player_index][slot_index]


# Get boss skill for a specific slot (for UI display)
func get_boss_slot_skill(slot_index: int):
	for skill_slot in boss_skills:
		if skill_slot.source_slot_index == slot_index:
			return skill_slot
	return null


# Check if all selections are complete
func _check_if_complete():
	for player_slots in player_selections:
		for skill_slot in player_slots:
			if skill_slot == null:
				return # Still have empty slots

	# Signals that the "Start Combat" button can now be interacted with
	all_selections_complete.emit()


# Get all selected skills from all players
func get_all_selected_skills() -> Array:
	var all_skills: Array = []
	for player_slots in player_selections:
		for skill_slot in player_slots:
			if skill_slot != null:
				all_skills.append(skill_slot)
	return all_skills


# Get number of filled slots for a specific player (for UI display)
func get_filled_slot_count(player_index: int) -> int:
	if player_index < 0 or player_index >= player_selections.size():
		return 0

	var count = 0
	for skill_slot in player_selections[player_index]:
		if skill_slot != null:
			count += 1
	return count


# Get remaining selections for a specific player (for UI display)
func get_remaining_selections(player_index: int) -> int:
	if player_index < 0 or player_index >= player_selections.size():
		return 0

	var total_slots = player_selections[player_index].size()
	return total_slots - get_filled_slot_count(player_index)


# Get available skills for a player (for UI display)
func get_available_skills(player_index: int) -> Array:
	if player_index < 0 or player_index >= players_ref.size():
		return []

	return players_ref[player_index].skills


# Called by UI "Start Combat" button
func request_combat_start():
	combat_start_requested.emit()


# Helper class representing a skill placed in a slot
class SkillSlot:
	var user # Entity performing the skill
	var skill: Skill # The skill being used
	var source_slot_index: int # Which slot this skill occupies (i.e. 0, 1, 2)
	var target_slot_index: int # Which slot is being targeted (i.e. 0, 1, 2)
	var target_player_index: int = -1 # Which player (for boss skills only)
	var target_entity # Direct reference to the entity being attacked


	func _init(
			_user,
			_skill: Skill,
			_source_slot_index: int,
			_target_slot_index: int, \
			_target_player_index: int = -1,
			_target_entity = null,
	):
		user = _user
		skill = _skill
		source_slot_index = _source_slot_index
		target_slot_index = _target_slot_index
		target_player_index = _target_player_index
		target_entity = _target_entity
