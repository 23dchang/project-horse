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

var entity: Entity = null

# Signals
signal all_selections_complete
signal combat_start_requested
signal boss_preview_ready


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


# Set entity skills (called by BattleManager after boss AI selects)
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
	
	
func populate_ui_skill_columns():
	for i in range(players_ref.size()):
		var player = players_ref[i]
		var available_skills = get_available_skills(i)

		var col = player.get_node_or_null("SkillsColumn")
		if col:
			col.populate_skill_icons(available_skills)
		else:
			print("ERROR: SkillsColumn missing from", player.name)

func populate_entity_skill_bar():
	if boss_skills.is_empty():
		print("ERROR: No boss skills to populate.")
		return
	
	if entity == null:
		print("ERROR: Boss reference not found in populate_boss_skill_bar()")
		return
	
	var bar: BossSkillsBar = entity.get_node_or_null("SkillsBar")
	if bar == null:
		print("ERROR: BossSkillsBar not found under boss")
		return
	
	var container = bar.get_node("TripleSkills/EmptySkillsContainer")
	var children = container.get_children()
	
	for i in range(min(children.size(), boss_skills.size())):
		var ui_icon = children[i]
		var skill_slot = boss_skills[i]
		var skill: Skill = skill_slot.skill
		
		# TEMPORARY: convert ColorRect → Label for quick check... 
		if ui_icon is ColorRect:
			var label := Label.new()
			label.text = "NP"      # Not populated yet
			label.custom_minimum_size = ui_icon.custom_minimum_size
			label.size = ui_icon.size
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			label.add_theme_font_size_override("font_size", 40)
			label.add_theme_color_override("font_color", Color.BLACK)

			container.remove_child(ui_icon)
			ui_icon.queue_free()
			ui_icon = label
			container.add_child(ui_icon)
			
			# Now populate the LABEL with "P"
			if ui_icon is Label:
				ui_icon.text = "P"
				ui_icon.set_meta("skill", skill)
		
		# should use this for end game when we have real skill icons
		# Convert ColorRect → TextureRect if needed
		#if ui_icon is ColorRect:
			#var tex_node := TextureRect.new()
			#tex_node.custom_minimum_size = ui_icon.custom_minimum_size
			#tex_node.size = ui_icon.size
			#container.remove_child(ui_icon)
			#ui_icon.queue_free()
			#ui_icon = tex_node
			#container.add_child(ui_icon)
		
		# Populate the icon
		#if ui_icon is TextureRect:
			#ui_icon.texture = skill.icon_texture
			#ui_icon.set_meta("skill", skill)
		
		print("   [populate_entity_skill_bar()] Boss bar slot %d populated with SkillID %d" % [i, skill.skill_id])

func prepare_preview_arrows() -> void:
	#print("\nPreparing Boss Preview Arrows")
	if boss_skills.is_empty():
		print("No boss skills for preview arrows.")
		return
	
	if entity == null:
		#print("ERROR: boss reference missing in ActionHandler.")
		return
	
	var bar: BossSkillsBar = entity.get_node_or_null("SkillsBar")
	if bar == null:
		#print("ERROR: BossSkillsBar missing under boss")
		return
	
	# Clear old arrows
	for child in bar.boss_preview_arrows.get_children():
		child.queue_free()
	
	var container = bar.get_node("TripleSkills/EmptySkillsContainer")
	var boss_ui_nodes = container.get_children()

	#print("\t(players_ref.size() =", players_ref.size(), ")")
	#print("Boss slots size: ", boss_ui_nodes.size())
	#print("Boss: Finding player skills to target...")
	#for i in range(min(boss_ui_nodes.size(), boss_skills.size())):
	for i in range(boss_ui_nodes.size()):
		var boss_icon = boss_ui_nodes[i]

		# Only proceed if it's a Label AND text == "P"
		if not (boss_icon is Label and boss_icon.text == "P"):
			#print("\t\tSkipping unpopulated boss slot:", boss_icon)
			continue

		var tgt = _get_empty_player_slot()
		if tgt == null:
			#print("\t\tNo empty player slots found...")
			continue
		
		var arrow := bar.ARROW_SCENE.instantiate()
		bar.boss_preview_arrows.add_child(arrow)
		
		arrow.node_start = boss_icon
		arrow.node_end   = tgt
		
		# stay hidden until hover
		arrow.visible = false

		#print("\t\tPrepared invisible arrow from boss slot", i, "-> empty player slot")

# TODO: How is boss AI choosing which player slots to attack?
# finds a player skill slot for boss to attack (random slot currently)
func _get_empty_player_slot() -> Node:
	#print("\tSearching for empty slot...")
	var candidates: Array = []
	
	# for each player
	for p in players_ref:
		var bar: SkillsBar = p.get_node_or_null("SkillsBar")
		if bar == null:
			print("\t  Player SkillsBar instance not found...")
			continue
		#else:
			#print("\tfound player ", p, " SkillsBar")
		
		# Use the actual container type (GridContainer)
		var container: GridContainer = bar.get_node_or_null("TripleSkills/EmptySkillsContainer")
		if container == null:
			print("\t  Player skill slot container not found...")
			continue
		#else:
			#print("\tfound player ", p, " SkillsBar's container")
		
		#print("\tSearching for ")
		for slot in container.get_children():
			var ctrl := slot as Control
			if ctrl == null:
				#print("\t    Child is not a Control:", slot)
				continue
				
			candidates.append(ctrl)
			#print("\t    Added candidate: ", ctrl.name, " type: ", ctrl.get_class())

	if candidates.is_empty():
		print("\tNo candidate found...")
		return null
	
	#print("\tSuccessfully found a candidate...")
	return candidates[randi() % candidates.size()]
	
# handles cursor hovering signal from boss entity
func register_boss_hover_signals(boss_entity: Node):
	var area := boss_entity.get_node_or_null("HoverArea")
	if area == null:
		push_error("\tBoss missing HoverArea")
		return

# used to set reference from battle manager
func set_boss_reference(b: Entity):
	entity = b
	
#func populate_player_skill_selection():
	#for player_index in range(players_ref.size()):
		#var player = players_ref[player_index]
		#var skills_column: SkillsColumn = player.get_node_or_null("SkillsColumn")
		#if skills_column == null:
			#print("SkillsColumn missing for", player.name)
			#continue
#
		#var px_counter := 1
#
		## Loop 3×3 grid
		#for col in skills_column.columns:
			#for i in range(col.get_child_count()):
				#var node = col.get_child(i)
#
				## Only replace placeholders
				#if node is ColorRect:
					#var label := Label.new()
					#label.text = "P%d" % px_counter
					#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					#label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					#label.custom_minimum_size = node.custom_minimum_size
					#
					## Font + color
					#label.add_theme_font_size_override("font_size", 40)
					#label.add_theme_color_override("font_color", Color.BLACK)
					#
					#label.mouse_filter = Control.MOUSE_FILTER_STOP
#
					## Replace the node
					#col.remove_child(node)
					#node.queue_free()
					#col.add_child(label)
#
					## Store UX metadata
					#label.set_meta("px_code", label.text)
					#label.set_meta("skill", null)  # will fill later when real skills exist
#
					## Connect hover behavior (SkillsColumn owns the signals)
					#if not label.mouse_entered.is_connected(skills_column._on_icon_hover_enter):
						#label.mouse_entered.connect(skills_column._on_icon_hover_enter.bind(label))
					#if not label.mouse_exited.is_connected(skills_column._on_icon_hover_exit):
						#label.mouse_exited.connect(skills_column._on_icon_hover_exit.bind(label))
#
					#px_counter += 1

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
		
		
func populate_player_skill_selection():
	
	for player_index in range(players_ref.size()):
		var player = players_ref[player_index]
		var skills_column: SkillsColumn = player.get_node_or_null("SkillsColumn")
		if skills_column == null:
			print("SkillsColumn missing for", player.name)
			continue

		print("\n=== Populating Skills for", player.name, "===")

		var px_counter := 1
		
		#print("\n[DEBUG] Inspecting initial placeholder types for", player.name)
		#for col_idx in range(skills_column.columns.size()):
			#var col = skills_column.columns[col_idx]
			#for row_idx in range(col.get_child_count()):
				#var n = col.get_child(row_idx)
				#print("Column", col_idx+1, "Row", row_idx+1, "is:", n.get_class())
		
		 #Iterate by column index so prints look nice
		for col_idx in range(skills_column.columns.size()):
			var col = skills_column.columns[col_idx]
			print("--- Column", col_idx + 1, "---")

			for row_idx in range(col.get_child_count()):
				var node = col.get_child(row_idx)

				# Only replace placeholders
				if node is ColorRect:
					var label := Label.new()
					label.text = "P%d" % px_counter
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					label.custom_minimum_size = node.custom_minimum_size

					# Font + color
					label.add_theme_font_size_override("font_size", 40)
					label.add_theme_color_override("font_color", Color.BLACK)

					# Ensure label receives hover events
					label.mouse_filter = Control.MOUSE_FILTER_STOP

					# Replace the node
					col.remove_child(node)
					node.queue_free()
					col.add_child(label)

					# Store metadata
					label.set_meta("px_code", label.text)
					label.set_meta("skill", null)

					# Connect hover signals
					if not label.mouse_entered.is_connected(skills_column._on_icon_hover_enter):
						label.mouse_entered.connect(skills_column._on_icon_hover_enter.bind(label))
					if not label.mouse_exited.is_connected(skills_column._on_icon_hover_exit):
						label.mouse_exited.connect(skills_column._on_icon_hover_exit.bind(label))

					print("   ✓ Populated Column", col_idx+1, "Row", row_idx+1,
						  "→", label.text)

					px_counter += 1

				else:
					# Not a placeholder → skip
					print("   ✗ Skipped Column", col_idx+1, "Row", row_idx+1,
						  "(", node.get_class(), ")")
