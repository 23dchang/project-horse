class_name BattleManager
extends Node

# Possible battle states
enum State {
	PRE_BATTLE,
	SKILL_SELECTION,
	COMBAT,
	END_WIN,
	END_LOSS
}

var state: State = State.PRE_BATTLE

# Subsystems
var prelim_handler: PrelimCombatHandler
var action_handler: ActionHandler
var combat_manager: CombatManager
var clash_system: ClashSystem
var UI_Test_System: BossFightManager

# References to players and enemy
var players: Array = []
var enemy: Entity



# Initialize subsystems and start battle
func _ready():
	# Adriano's testing before moving to prelim
	#UI_Test_System = BossFightManager.new()
	#add_child(UI_Test_System)
	
	# turned off to test UI
	_initialize_subsystems()
	start_battle()
	


func _initialize_subsystems():
	
	prelim_handler = PrelimCombatHandler.new()
	add_child(prelim_handler)
	
	action_handler = ActionHandler.new()
	add_child(action_handler)
	
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	
	# TODO: Initialize clash_system when ready

func start_battle():
	state = State.PRE_BATTLE
	
	# Pre-battle spawn and setup
	prelim_handler.setup_fight()
	
	# Store references
	players = prelim_handler.players
	enemy = prelim_handler.enemy
	
	# Pass references to combat manager
	combat_manager.players = players
	combat_manager.boss = enemy
	
	# Store original skill pools for all players
	for player in players:
		action_handler.store_original_pool(player)
		
	# Sets action_handlers boss ref to this one 
	action_handler.set_boss_reference(enemy)
	
	_start_skill_selection()

# Skill selection phase
func _start_skill_selection():
	state = State.SKILL_SELECTION
	print("\n Phase: Skill Selection")
	
	# Boss selects its skills FIRST
	var boss_skills = await _get_boss_skills()
	
	# Make boss skills visible to UI
	action_handler.set_boss_skills(boss_skills)
	
	# populates empty boss skill slots with P; NP if unsuccessful
	action_handler.populate_entity_skill_bar() 
	
	# Setup skill selection for all characters
	action_handler.setup_selection(players)
	
	# Generate red preview arrows. Only visible when hovering over boss/enemy entity 
	action_handler.prepare_preview_arrows()
	
	"""
	TODO: Load the player skills into the skills_columns. For each players, load up to 9 skills
	(for 3 columns with 3 skills each). Loading also includes updating the description box 
	labels with 
	
	Right now skills dont have much info
	

	TODO: The player can click on 
	"""
	
	# populates the 
	action_handler.populate_player_skill_selection()
	
	# Wait for all character selections to complete
	# UI should call action_handler.set_skill_for_slot() multiple times
	await action_handler.all_selections_complete
	
	# Get all player skills
	var all_skills = action_handler.get_all_selected_skills()
	
	# Add boss skills to the queue
	all_skills += boss_skills
	
	# Wait for "Start Combat" button press
	print("\nWaiting for 'Start Combat' button...")
	await action_handler.combat_start_requested
	
	# Execute combat phase
	_on_skills_ready(all_skills)

# Boss AI skill selection (placeholder)
func _get_boss_skills() -> Array:
	var skills: Array = []
	
	# TODO: Replace with actual boss AI logic
	# Boss creates skills that target specific player skill slots
	for boss_slot_index in range(3):
		var random_skill = enemy.skills.pick_random() if enemy.skills.size() > 0 else Skill.new(1)
		
		# Pick a random player
		var target_player_index = randi() % players.size()
		
		# Pick a random skill slot from that player
		var target_slot_index = randi() % players[target_player_index].max_skill_slots
		
		# Create boss skill targeting a specific player's specific slot
		var skill_slot = ActionHandler.SkillSlot.new(
			enemy, # user
			random_skill, # skill being used
			boss_slot_index, # source_slot_index (which boss slot being used)
			target_slot_index, # target_slot_index (which player slot to target)
			target_player_index, # target_player_index (which player to hit)
			players[target_player_index] # entity being targeted
		)
		skills.append(skill_slot)
		
		# Print the boss' skill selection
		print("  [_get_boss_skills()] Boss Slot %d -> Player %d Slot %d (Skill %d)" % 
			[boss_slot_index, target_player_index, target_slot_index, random_skill.skill_id])
	
	return skills

# Combat phase - execute all skills in speed order
func _on_skills_ready(skill_queue: Array):
	state = State.COMBAT
	print("\n Phase: Combat")
	print("Executing %d skills in speed order" % skill_queue.size())
	
	# Sort all skills by user speed (highest speed first)
	skill_queue.sort_custom(func(a, b): return a.user.speed > b.user.speed)
	
	# Let combat manager resolve skills
	await combat_manager.resolve_skills(skill_queue)
	
	# After combat, check for end
	if _check_battle_end():
		_end_battle()
	else:
		# Reset for next turn
		_start_skill_selection()

# Check if battle ended
func _check_battle_end() -> bool:
	var all_players_dead = players.all(func(p): return p.is_dead)
	var enemy_dead = enemy.is_dead
	
	return all_players_dead or enemy_dead

# Handle battle end
func _end_battle():
	if enemy.is_dead:
		state = State.END_WIN
		print("Win!")
	else:
		state = State.END_LOSS
		print("Loss!")
	
	# TODO: Add scene transitions or victory/defeat screens

func _on_start_combat_pressed() -> void:
	action_handler.request_combat_start()
