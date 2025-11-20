## To be passed into [code]SkillsLibrary.generator().gen_random_skill()[/code]
class_name SkillSchema
extends RefCounted

## Skill tier level. Higher stronger.
var tier: int

## Max base value for the skill.
var max_base: float

## Max bonus value for the skill.
var max_bonus: float

## Max number of coins for the skill.
var max_coins: int


func set_tier(val: int) -> SkillSchema:
	tier = val
	return self


func set_max_base(val: float) -> SkillSchema:
	max_base = val
	return self


func set_max_bonus(val: float) -> SkillSchema:
	max_bonus = val
	return self


func set_max_coins(val: int) -> SkillSchema:
	max_coins = val
	return self


func load_args(args: Dictionary) -> SkillSchema:
	return (
		set_tier(args.tier)
		. set_max_base(args.max_base)
		. set_max_bonus(args.max_bonus)
		. set_max_coins(args.max_coins)
	)


## Normalizes the SkillSchema's attributes based on the
## provided default schema. Assume schema is populated safely
## from a config file.
func normalize(schema: SkillSchema) -> void:
	tier = tier if tier else schema.tier
	max_base = max_base if not is_zero_approx(max_base) else schema.max_base
	max_bonus = max_bonus if not is_zero_approx(max_bonus) else schema.max_bonus
	max_coins = max_coins if max_coins else schema.max_coins
