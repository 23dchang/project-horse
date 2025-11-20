class_name SkillsLibrary
extends RefCounted

# Idk why. skills_ct is used to provide skills
# sequential ids. all_skills no idea
var all_skills: Array[Skill]
var skills_ct: int

## The SkillsLibrary's configuration file. Allows for
## tweaking some internal library values without
## modifying the source code.
var lib_config: SkillsLibraryConfig


## Initialize [code]SkillsLibrary[/code] object. [br]
## [code]config[/code] : pass in configuration.
func _init(config: SkillsLibraryConfig) -> void:
	lib_config = config


## Provides methods for generating consistent skill sequences.
## [code]_seed[/code]: number passed into the 'SkillGenerator' such that
## the Skill sequences are consistent across game sessions.
func generator(_seed: int = lib_config.default_seed) -> SkillGenerator:
	return SkillGenerator.new(_seed, self)


func get_all_skills() -> Array[Skill]:
	return all_skills


## Internal class to aid [code]SkillsLibrary[/code].
class SkillGenerator:
	var max_tier: int
	var _rng: RandomNumberGenerator
	var _lib: SkillsLibrary

	# After initialization only gen_random_skill is
	# intended for high level use by the programmers.
	func _init(_seed: int, lib: SkillsLibrary) -> void:
		_rng = RandomNumberGenerator.new()
		_lib = lib
		_rng.seed = _seed
		max_tier = _lib.lib_config.max_skill_tiers

	## Returns a randomly generated [code]Skill[/code]
	## given a [code]SkillSchema[/code]
	func gen_random_skill(schema: SkillSchema = _lib.lib_config.default_schema) -> Skill:
		schema.normalize(_lib.lib_config.default_schema)
		var tier: int = schema.tier
		var max_base: float = schema.max_base
		var max_bonus: float = schema.max_bonus
		var max_coins: int = schema.max_coins

		var id: int = compute_skill_id()

		var skill = Skill.new(
			id,
			roll_value(tier, max_base),
			roll_value(tier, max_bonus),
			_rng.randi_range(1, max_coins)
		)

		_lib.all_skills.push_back(skill)

		return skill

	func roll_value(tier: int, cap: float) -> float:
		# How does this work?
		# |----|----|----|
		#   t1   t2   t3
		# Value rolling windows are tier dependent,
		# never have lower tier skill stronger than a
		# higher tier.
		var window_size: float = cap / max_tier
		var min_value: float = (tier - 1) * window_size
		var max_value: float = min_value + window_size

		var val := _rng.randf_range(min_value, max_value)

		val = clampf(val, 1, cap)

		return val

	func compute_skill_id() -> int:
		var id: int = _lib.skills_ct
		_lib.skills_ct += 1
		return id
