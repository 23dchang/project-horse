class_name EntityLibrary
extends RefCounted

var entity_ct: int = 0
var skills_lib: SkillsLibrary

var lib_config: EntityLibraryConfig

# TODO: maybe generate random enemy entities 

# INFO: For fixed boss/player skill sets, ingest here in the Entity
# library and assign the sets to our respective characters.
func _init(config: EntityLibraryConfig, skills_library: SkillsLibrary) -> void:
	lib_config = config
	skills_lib = skills_library


## Populates an Entity object's skills attribute. [br]
## [code]entity[/code] is the Entity object to be populated. [br]
## [code]mode[/code] is an integer. 0 is auto generate skills,
## and 1 is load fixed skillset (1 is not implemented yet).
func initialize_skills(entity: Entity, mode: int = 0) -> void:
	# Mode 0 is auto generate skills
	# Mode 1 loads pre set skill sets.
	# Concern - how to distinguish entities for skill loading?
	# Many options, open to discussion.
	if mode:
		# TODO: load_skills logic
		return

	var skills: Array[Skill]
	var _seed: int = _compute_seed(entity)

	var gen: SkillsLibrary.SkillGenerator = skills_lib.generator(_seed)
	var entity_skillset_specs: Dictionary = lib_config.entity_skillset_specs
	var skill_schema: SkillSchema = SkillSchema.new()

	for tier in entity_skillset_specs.keys():
		var skill_cards_ct: int = entity_skillset_specs[tier]
		skill_schema.set_tier(tier)

		for ct in range(skill_cards_ct):
			# INFO: for fine grain control load skills instead.
			# Can also discuss on how to open up
			# more of the abstraction layers.
			skills.push_back(gen.gen_random_skill(skill_schema))

	# WARNING: bad practice here.
	entity.skills = skills
	entity_ct += 1


func _compute_seed(entity: Entity) -> int:
	var _seed: int = entity_ct
	var sprite: Sprite2D = entity.sprite
	var resource_path: String = sprite.texture.resource_path if sprite else ""
	if not resource_path.is_empty():
		_seed += resource_path.hash()
	return _seed
