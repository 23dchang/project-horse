class_name ActionHandler
extends Node

# Selection tracking - array of arrays
var player_selections: Array = [] # Array of Arrays of SkillSlots
var players_ref: Array = [] # Reference to player entities

# Boss skills visible during selection phase
var boss_ref: Entity = null
var boss_skills: Array = [] # Array of SkillSlots

# Track original skill decks for refreshing
var original_skill_pool: Dictionary = { } # player -> original skills array

# Signals
signal all_selections_complete
signal combat_start_requested
signal boss_preview_ready(arrows: Array)

# Setup skill selection for all players
func setup_selection(players: Array):
	player_selections.clear()
	players_ref = players

	for player in players:
		if player.skills.is_empty():
			_refresh_skill_pool(player)

		var player_slots: Array = []
		for i in range(player.max_skill_slots):
			player_slots.append(null)
		player_selections.append(player_slots)

# Store a player's original skill pool for later refreshing
func store_original_pool(player: Entity):
	if player not in original_skill_pool:
		original_skill_pool[player] = player.skills.duplicate()

# Refresh a player's skill pool from the stored original
func _refresh_skill_pool(player: Entity):
	if player in original_skill_pool:
		player.skills = original_skill_pool[player].duplicate()

# Setup boss reference and skills for preview and targeting
func setup_boss(boss: Entity, skills: Array):
	boss_ref = boss
	boss_skills = skills

# Called by UI when the player picks/changes a skill for a specific slot
func set_skill_for_slot(player_index: int, slot_index: int, skill: Skill, target_slot_index: int) -> bool:
	if player_index < 0 or player_index >= player_selections.size():
		print("Error: Invalid player index %d" % player_index)
		return false
	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		print("Error: Invalid slot index %d for player %d" % [slot_index, player_index])
		return false

	var player = players_ref[player_index]

	if skill not in player.skills:
		print("Error: Skill not in player's available pool")
		return false

	var target_entity = boss_ref if boss_ref != null else null

	var skill_slot = SkillSlot.new(
		player,
		skill,
		slot_index,
		target_slot_index,
		-1,
		target_entity,
	)

	player.skills.erase(skill)
	player_selections[player_index][slot_index] = skill_slot
	_check_if_complete()
	return true

# Clear a skill slot and return the skill to the player's pool
func clear_slot(player_index: int, slot_index: int) -> bool:
	if player_index < 0 or player_index >= player_selections.size():
		return false
	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		return false

	var old_skill_slot = player_selections[player_index][slot_index]
	if old_skill_slot != null:
		players_ref[player_index].skills.append(old_skill_slot.skill)

	player_selections[player_index][slot_index] = null
	return true

# Get the skill slot at a specific player and slot index
func get_slot_skill(player_index: int, slot_index: int):
	if player_index < 0 or player_index >= player_selections.size():
		return null
	if slot_index < 0 or slot_index >= player_selections[player_index].size():
		return null
	return player_selections[player_index][slot_index]

# Get all selected skills across all players
func get_all_selected_skills() -> Array:
	var all_skills: Array = []
	for player_slots in player_selections:
		for skill_slot in player_slots:
			if skill_slot != null:
				all_skills.append(skill_slot)
	return all_skills

# Emit signal to request combat start
func request_combat_start():
	combat_start_requested.emit()

# Check if all slots are filled and emit completion signal
func _check_if_complete():
	for player_slots in player_selections:
		for skill_slot in player_slots:
			if skill_slot == null:
				return
	all_selections_complete.emit()

# Get all player skill nodes from the scene tree (used by show_boss_preview)
func get_player_skill_nodes() -> Array[Control]:
	var result : Array[Control] = []

	for player in players_ref:
		var root: Node = player.get_node_or_null("SkillsBar/TripleSkills/EmptySkillsContainer")
		if root == null:
			continue

		for child in root.get_children():
			if child is ColorRect or child is TextureRect:
				result.append(child)

	return result

# Get all boss skill nodes from the scene tree (used by show_boss_preview)
func get_boss_skill_nodes() -> Array[Control]:
	var result : Array[Control] = []
	
	if boss_ref == null:
		print("ERROR: Boss reference is null. Call setup_boss() first.")
		return result
	
	var root: Node = boss_ref.get_node_or_null("SkillsBar/TripleSkills/EmptySkillsContainer")
	if root == null:
		print("ERROR: Boss TripleSkills not found.")
		return result
	
	for child in root.get_children():
		if child is ColorRect or child is TextureRect:
			result.append(child)
	
	return result

# Create and display arrows showing boss skill targeting
func show_boss_preview():
	if boss_ref == null:
		print("ERROR: Boss reference is null. Cannot show preview.")
		return
	
	var boss_preview_arrows: Node = boss_ref.get_node_or_null("SkillsBar/BossPreviewArrows")
	if boss_preview_arrows == null:
		print("ERROR: BossPreviewArrows node not found on boss.")
		return
	
	for child in boss_preview_arrows.get_children():
		child.queue_free()
	
	var boss_skill_nodes := get_boss_skill_nodes()
	var player_skill_nodes := get_player_skill_nodes()

	if boss_skill_nodes.is_empty():
		print("ERROR: No boss skills detected.")
		return
	if player_skill_nodes.is_empty():
		print("ERROR: No player skills detected.")
		return

	var arrows_data: Array = []
	
	for i in range(boss_skills.size()):
		if i >= boss_skill_nodes.size():
			break
			
		var skill_slot: SkillSlot = boss_skills[i]
		var boss_node = boss_skill_nodes[i]
		
		var target_node = _find_target_skill_node(skill_slot, player_skill_nodes)
		
		if target_node != null:
			const ARROW_SCENE := preload("res://scenes/UI/boss_preview_arrows.tscn")
			var arrow = ARROW_SCENE.instantiate()
			boss_preview_arrows.add_child(arrow)
			arrow.node_start = boss_node
			arrow.node_end = target_node
			
			arrows_data.append({
				"arrow": arrow,
				"from": boss_node,
				"to": target_node,
				"skill": skill_slot.skill
			})

	boss_preview_ready.emit(arrows_data)

# Find the target skill node based on skill slot targeting information
func _find_target_skill_node(skill_slot: SkillSlot, player_skill_nodes: Array[Control]) -> Control:
	if skill_slot.target_player_index < 0 or skill_slot.target_player_index >= players_ref.size():
		return null
	
	var node_offset = 0
	
	for i in range(skill_slot.target_player_index):
		node_offset += players_ref[i].max_skill_slots
	
	node_offset += skill_slot.target_slot_index
	
	if node_offset < player_skill_nodes.size():
		return player_skill_nodes[node_offset]
	
	return null


# Helper class representing a skill placed in a slot
class SkillSlot:
	var user
	var skill: Skill
	var source_slot_index: int
	var target_slot_index: int
	var target_player_index: int = -1
	var target_entity

	func _init(_user, _skill: Skill, _source_slot_index: int, _target_slot_index: int, _target_player_index: int = -1, _target_entity = null):
		user = _user
		skill = _skill
		source_slot_index = _source_slot_index
		target_slot_index = _target_slot_index
		target_player_index = _target_player_index
		target_entity = _target_entity
