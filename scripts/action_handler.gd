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
var bar_slot_defaults: Dictionary = {}

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
				print("Empty slot remaining")
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

func display_player_selections() -> void:
	print("\n=== PLAYER SELECTION SUMMARY ===")

	for player_index in range(player_selections.size()):
		print("\nPlayer ", player_index + 1, ":")

		var slots: Array = player_selections[player_index]

		for slot_index in range(slots.size()):
			var skill_slot: SkillSlot = slots[slot_index]

			if skill_slot == null:
				print("   Slot", slot_index, " = EMPTY")
			else:
				print("   Slot ", slot_index,
					" = Skill ", skill_slot.skill.skill_id)

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
	print("Populating boss skills bar")
	if entity == null:
		print("ERROR: Boss reference not found in populate_entity_skill_bar()")
		return

	var bar: BossSkillsBar = entity.get_node_or_null("SkillsBar")
	if bar == null:
		print("ERROR: BossSkillsBar not found under boss")
		return

	var container: GridContainer = bar.get_node("TripleSkills/EmptySkillsContainer")
	var ui_slots := container.get_children()

	# Clear ALL UI slots back to default (ColorRect)
	for i in range(ui_slots.size()):
		var slot := ui_slots[i]

		# If slot became a label from last round, restore default ColorRect
		if slot is Label:
			var rect := ColorRect.new()
			rect.color = Color(0.0339, 0.0339, 0.0339, 1)
			rect.custom_minimum_size = slot.custom_minimum_size
			container.remove_child(slot)
			slot.queue_free()
			container.add_child(rect)
			container.move_child(rect, i)

	# Apply boss_skills to their exact source_slot_index positions
	for skill_slot in boss_skills:
		var idx: int = skill_slot.source_slot_index
		if idx < 0 or idx >= ui_slots.size():
			continue

		var rect := container.get_child(idx)

		# Replace placeholder with label
		var lbl := Label.new()
		lbl.text = "P%d" % skill_slot.skill.skill_id
		lbl.custom_minimum_size = rect.custom_minimum_size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 40)
		lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP

		container.remove_child(rect)
		rect.queue_free()
		container.add_child(lbl)
		container.move_child(lbl, idx)

		# Store actual SkillSlot for later lookup
		lbl.set_meta("skill_slot", skill_slot)

		print("  [populate] Boss UI slot ", idx, " → SkillID_", skill_slot.skill.skill_id)


func prepare_preview_arrows() -> void:
	print("Generating boss preview arrows...")
	if boss_skills.is_empty():
		print("[arrows] No boss skills → no preview lines.")
		return

	if entity == null:
		print("[arrows] ERROR: No boss reference.")
		return

	var bar: BossSkillsBar = entity.get_node_or_null("SkillsBar")
	if bar == null:
		print("[arrows] ERROR: No BossSkillsBar.")
		return

	# Clear previous arrows
	for child in bar.boss_preview_arrows.get_children():
		child.queue_free()

	var container := bar.get_node("TripleSkills/EmptySkillsContainer")
	var ui_slots := container.get_children()

	for skill_slot in boss_skills:
		var start_idx: int = skill_slot.source_slot_index
		var target_player: int = skill_slot.target_player_index
		var target_slot: int = skill_slot.target_slot_index

		if start_idx < 0 or start_idx >= ui_slots.size():
			continue

		var start_node := ui_slots[start_idx]
		if not (start_node is Label):
			continue

		# Get target player's UI slot
		if target_player < 0 or target_player >= players_ref.size():
			continue

		var player: Player = players_ref[target_player]
		var p_bar := player.get_node("SkillsBar")
		var p_container := p_bar.get_node("TripleSkills/EmptySkillsContainer")
		var p_slots := p_container.get_children()

		if target_slot < 0 or target_slot >= p_slots.size():
			continue

		var end_node := p_slots[target_slot]

		# Create arrow
		var arrow := bar.ARROW_SCENE.instantiate()
		bar.boss_preview_arrows.add_child(arrow)
		arrow.node_start = start_node
		arrow.node_end = end_node
		arrow.visible = false # only visible on hover
		
func _get_player_bar_slot(player_index: int, slot_index: int) -> Control:
	if player_index < 0 or player_index >= players_ref.size():
		return null

	var player: Entity = players_ref[player_index]
	var bar: SkillsBar = player.get_node_or_null("SkillsBar")
	if bar == null:
		print("\t[arrows] Player", player_index, "missing SkillsBar")
		return null

	var container: GridContainer = bar.get_node_or_null("TripleSkills/EmptySkillsContainer")
	if container == null:
		print("\t[arrows] Player", player_index, "missing EmptySkillsContainer")
		return null

	if slot_index < 0 or slot_index >= container.get_child_count():
		print("\t[arrows] Slot index", slot_index, "OOB for player", player_index)
		return null

	return container.get_child(slot_index) as Control

func register_boss_hover_signals(boss_entity: Node):
	var area := boss_entity.get_node_or_null("HoverArea")
	if area == null:
		push_error("\tBoss missing HoverArea")
		return

# used to set reference from battle manager
func set_boss_reference(b: Entity):
	entity = b
	
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
	print("\n=== Populating Players SkillsColumns...")
	
	for player_index in range(players_ref.size()):
		var player: Entity = players_ref[player_index]
		var skills_column: SkillsColumn = player.get_node_or_null("SkillsColumn")
		if skills_column == null:
			print("SkillsColumn missing for", player.name)
			continue

		# Get this player's full skill pool (12 skills right now)
		var pool: Array = get_available_skills(player_index)
		if pool.is_empty():
			print("    [WARN] No skills available for", player.name)
			continue

		# Make a shuffled copy of the pool
		# TODO: Check if skill pools shuffle every turn...
		var shuffled_pool: Array = pool.duplicate()
		shuffled_pool.shuffle()

		# Pick 9 skills from that pool (wrap if pool < 9)
		var needed_slots := 9
		var picked_skills: Array = []
		var idx := 0

		while picked_skills.size() < needed_slots:
			var skill: Skill = shuffled_pool[idx]
			picked_skills.append(skill)
			idx += 1
			if idx >= shuffled_pool.size():
				idx = 0 # wrap around if ever needed

		# assign 9 skills into the 3x3 grid
		var assign_index := 0

		for col_idx in range(skills_column.columns.size()):
			var col: GridContainer = skills_column.columns[col_idx]
			#print("--- Column", col_idx + 1, "---")
			
			#print("[VERIFY CHILDREN] Column", col_idx + 1)
			#for child in col.get_children():
				#print(" Child:", child.name, "| Class:", child.get_class())

			for row_idx in range(col.get_child_count()):
				if assign_index >= picked_skills.size():
					break

				
				var node: Control = col.get_child(row_idx)

				# Only replace placeholders
				if node is ColorRect:
					var skill: Skill = picked_skills[assign_index]

					var label := Label.new()
					# Text: P + skill_id (P1, P2, P3)
					label.text = "P%d" % skill.skill_id
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					label.custom_minimum_size = node.custom_minimum_size

					# Font + color
					label.add_theme_font_size_override("font_size", 40)
					label.add_theme_color_override("font_color", Color.BLACK)

					# Ensure label receives hover events
					label.mouse_filter = Control.MOUSE_FILTER_STOP

					# Replace the placeholder node
					col.remove_child(node)
					node.queue_free()
					col.add_child(label)
					col.move_child(label,row_idx)
					node.queue_free()
					

					# Store metadata:
					# - px_code (for current hover text)
					# - real skill instance (for future detailed tooltip / logic)
					label.set_meta("px_code", label.text)
					label.set_meta("skill", skill)

					# Connect hover signals so SkillsColumn can drive the description box
					if not label.mouse_entered.is_connected(skills_column._on_icon_hover_enter):
						label.mouse_entered.connect(skills_column._on_icon_hover_enter.bind(label))
					if not label.mouse_exited.is_connected(skills_column._on_icon_hover_exit):
						label.mouse_exited.connect(skills_column._on_icon_hover_exit.bind(label))

					#print("  ✓ Populated Column", col_idx + 1, "Row", row_idx + 1,
						 #"→", label.text, "(skill_id =", skill.skill_id, ")")

					assign_index += 1
				else:
					#print(" ✗ Skipped Column", col_idx + 1, "Row", row_idx + 1,
						#"(", node.get_class(), ")")
						pass
	
	print("=== Populated Players SkillColumns successfully ===")
						
func select_player_skills() -> void:
	print("\n[select_player_skills] BEGIN attaching click handlers...")

	for player_index in range(players_ref.size()):
		var player: Entity = players_ref[player_index]

		var skills_column: SkillsColumn = player.get_node_or_null("SkillsColumn")
		if skills_column == null:
			print("[select_player_skills] MISSING SkillsColumn for", player.name)
			continue

		var bar: SkillsBar = player.get_node_or_null("SkillsBar")
		if bar == null:
			print("[select_player_skills] MISSING SkillsBar for", player.name)
			continue

		var bar_container: GridContainer = bar.get_node("TripleSkills/EmptySkillsContainer")

		# --- CONNECT column skill clicks ---
		for col_idx in range(skills_column.columns.size()):
			var col: GridContainer = skills_column.columns[col_idx]

			for row_idx in range(col.get_child_count()):
				var node := col.get_child(row_idx)
				var label := node as Label
				if label == null:
					print("[select_player_skills] Non-label found in column, skipping:", node)
					continue

				label.mouse_filter = Control.MOUSE_FILTER_STOP

				# ALWAYS disconnect first (prevents suppressed connect failures)
				if label.gui_input.is_connected(_on_column_skill_gui_input):
					label.gui_input.disconnect(_on_column_skill_gui_input)

				#print("[select_player_skills] CONNECT column click -> Player", player_index,
					#"Col", col_idx, "Row", row_idx, "| Text:", label.text)

				label.gui_input.connect(
					_on_column_skill_gui_input.bind(player_index, col_idx, label)
				)

		# --- CONNECT bar slot clicks ---
		for slot_index in range(bar_container.get_child_count()):
			var slot_node := bar_container.get_child(slot_index) as Control
			if slot_node == null:
				continue
				
			_cache_bar_slot_default(player_index, slot_index, slot_node)

			slot_node.mouse_filter = Control.MOUSE_FILTER_STOP

			if slot_node.gui_input.is_connected(_on_bar_slot_gui_input):
				slot_node.gui_input.disconnect(_on_bar_slot_gui_input)

			#print("[select_player_skills] CONNECT bar click  -> Player", player_index,
				#"Slot", slot_index)

			slot_node.gui_input.connect(
				_on_bar_slot_gui_input.bind(player_index, slot_index)
			)

	print("[select_player_skills] DONE attaching handlers.\n")

func _on_column_skill_gui_input(
		event: InputEvent,
		player_index: int,
		column_index: int,
		label: Label
) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	print("\n[CLICK] Column Skill Click:",
		" Player:", player_index,
		" Col:", column_index,
		" Text:", label.text)

	var skill: Skill = label.get_meta("skill")
	if skill == null:
		print("[ERROR] Column label has NO skill meta!")
		return

	var slot_index := column_index # strict column → bar-slot mapping
	var player: Player = players_ref[player_index]
	var bar: SkillsBar = player.get_node("SkillsBar")
	var bar_container: GridContainer = bar.get_node("TripleSkills/EmptySkillsContainer")
	var bar_node: Control = bar_container.get_child(slot_index)

	var existing_slot: SkillSlot = get_slot_skill(player_index, slot_index)

	# If same skill clicked again, unselect it
	if existing_slot != null and existing_slot.skill == skill:
		print("[CLICK] Same skill -> CLEAR slot", slot_index)
		var ok := clear_slot(player_index, slot_index)
		print("[CLICK] clear_slot() returned:", ok)

		if ok:
			print("[CLICK] Resetting slot visual")
			_reset_bar_slot_visual(player_index, slot_index)
		return

	# If different skill already in bar slot, clear it first
	if existing_slot != null:
		print("[CLICK] Replacing old skill in slot", slot_index)
		var ok := clear_slot(player_index, slot_index)
		print("[CLICK] clearing old slot returned:", ok)

		if ok:
			_reset_bar_slot_visual(player_index, slot_index)

	# --- SET NEW SKILL ---
	print("[CLICK] Setting skill ", skill.skill_id, " into slot ", slot_index)
	var set_ok := set_skill_for_slot(player_index, slot_index, skill, slot_index)
	print("[CLICK] set_skill_for_slot() returned:", set_ok)

	if not set_ok:
		print("[ERROR] set_skill_for_slot FAILED")
		return

	# Refresh bar_node since we may have replaced it
	bar_node = bar_container.get_child(slot_index)


	# --- Replace ColorRect → Label if needed ---
	if bar_node is ColorRect:
		var lbl := Label.new()
		lbl.text = "P%d" % skill.skill_id
		
		# Explicitly FORCE label to be 50x50 no matter what
		lbl.custom_minimum_size = bar_node.custom_minimum_size
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# OPTIONAL but recommended:
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		lbl.add_theme_font_size_override("font_size", 32) # try 32 instead of 40
		lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP

		bar_container.add_child(lbl)
		bar_container.move_child(lbl, slot_index)
		bar_node.queue_free()
		bar_node = lbl
	else:
		bar_node.text = "P%d" % skill.skill_id

	# Attach metadata
	bar_node.set_meta("skill", skill)

	print("[CLICK] Slot ", slot_index, " is now P%d " % skill.skill_id)

func _on_bar_slot_gui_input(event: InputEvent, player_index: int, slot_index: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	print("\n[CLICK] Bar Slot Click:",
		" Player:", player_index,
		" Slot:", slot_index)

	var existing_slot: SkillSlot = get_slot_skill(player_index, slot_index)
	if existing_slot == null:
		print("[CLICK] Slot already empty.")
		return

	print("[CLICK] Clearing slot", slot_index,
		" skill =", existing_slot.skill.skill_id)

	var cleared := clear_slot(player_index, slot_index)
	print("[CLICK] clear_slot() returned:", cleared)

	# Now fully restore the ColorRect
	if cleared:
		print("[CLICK] Resetting slot visual for player", player_index, "slot", slot_index)
		_reset_bar_slot_visual(player_index, slot_index)

	print("[CLICK] Slot", slot_index, "cleared.\n")
	
	
func _cache_bar_slot_default(
		player_index: int,
		slot_index: int,
		slot_node: Control
) -> void:
	var key := "%d_%d" % [player_index, slot_index]
	if bar_slot_defaults.has(key):
		return  # already cached

	var data := {
		"class": slot_node.get_class(),
		"min_size": slot_node.custom_minimum_size,
		"size": slot_node.size
	}

	if slot_node is ColorRect:
		data["color"] = (slot_node as ColorRect).color

	bar_slot_defaults[key] = data
	#print(" [cache] bar default for player", player_index,
		#"slot", slot_index, "=", data)

func _reset_bar_slot_visual(player_index: int, slot_index: int) -> void:
	var player: Entity = players_ref[player_index]
	var bar: SkillsBar = player.get_node_or_null("SkillsBar")
	if bar == null:
		print(" [reset] No SkillsBar for player", player_index)
		return

	var container := bar.get_node("TripleSkills/EmptySkillsContainer") as GridContainer
	if container == null:
		print("[reset] No EmptySkillsContainer for player", player_index)
		return
	if slot_index < 0 or slot_index >= container.get_child_count():
		print("[reset] slot index OOB:", slot_index)
		return

	var key := "%d_%d" % [player_index, slot_index]
	var cfg = bar_slot_defaults.get(key, null)

	var current := container.get_child(slot_index) as Control
	if cfg == null:
		# Fallback: just clear label text/meta
		if current is Label:
			(current as Label).text = ""
		current.set_meta("skill", null)
		current.set_meta("px_code", "")
		print("[reset] no cached defaults; just cleared label for p", player_index, "slot", slot_index)
		return

	# Remove current node from container
	container.remove_child(current)
	current.queue_free()

	# Recreate original node (ColorRect)
	var new_node: Control
	if cfg["class"] == "ColorRect":
		var rect := ColorRect.new()
		rect.color = cfg.get("color", Color.BLACK)
		new_node = rect
	else:
		# Shouldn't happen with your setup, but safe fallback
		new_node = Control.new()

	new_node.custom_minimum_size = cfg["min_size"]
	new_node.size = cfg["size"]
	new_node.mouse_filter = Control.MOUSE_FILTER_STOP

	# Add back into the same slot index
	container.add_child(new_node)
	container.move_child(new_node, slot_index)

	# Clear any gameplay metadata
	new_node.set_meta("skill", null)
	new_node.set_meta("px_code", "")

	# Re-wire click for future selections
	if not new_node.gui_input.is_connected(_on_bar_slot_gui_input):
		new_node.gui_input.connect(
			_on_bar_slot_gui_input.bind(player_index, slot_index)
		)

	print("[reset] Restored default ColorRect for player", player_index, "slot", slot_index)
	
