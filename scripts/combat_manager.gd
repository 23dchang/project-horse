class_name CombatManager
extends Node

# References to battle entities (set by BattleManager)
var players: Array[Entity] = []
var boss: Entity

# Execute all skills in the provided queue
func resolve_skills(skill_queue: Array) -> void:
	print("\n--- Resolving %d skills ---" % skill_queue.size())
	
	# Execute all skills based on speed order
	for i in range(skill_queue.size()):
		var skill_slot = skill_queue[i]
		
		# Skip if user is dead
		if skill_slot.user.is_dead:
			print("\n[%d] %s is dead, skipping skill" % [i + 1, skill_slot.user.name])
			continue
		
		# TODO: Add logic to identify clash vs free attack
		
		# Get target entity
		var target: Entity = skill_slot.target_entity
		
		# Validate target
		if target == null:
			print("ERROR: No valid target found!")
			continue
		
		# Checks if hte target is dead
		if target.is_dead:
			continue
		
		# TODO: Apply damage by either calling the clash system or through a direct attack
		
		# Check if target died from this skill
		if target.is_dead:
			print("%s has been defeated!" % target.name)
		
		# Small delay between skills for visual clarity
		await get_tree().create_timer(0.5).timeout
	
	# After execution
