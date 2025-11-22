class_name Skill
extends Resource

@export var skill_id: int = 0
@export var name:String = "More cats when..."
@export var icon:Texture = null
@export var base_roll: float = 0.0
@export var bonus_roll: float = 0.0
@export var coins: int = 1
@export var odds: float = 0.5


func _init(
	_skill_id: int = 0,
	_base_roll: float = 0.0,
	_bonus_roll: float = 0.0,
	_coins: int = 1,
	_odds: float = 0.5
):
	skill_id = _skill_id
	base_roll = _base_roll
	bonus_roll = _bonus_roll
	coins = _coins
	odds = _odds


func _to_string() -> String:
	return 'Skill(skill_id=%d, base_roll=%.3f, bonus_roll=%.3f, coins=%d, odds=%.3f)' % \
			[skill_id, base_roll, bonus_roll, coins, odds]


func clash_value() -> float:
	var value: float = base_roll

	for coin_ct in range(coins):
		value += bonus_roll if heads() else 0.0

	return value


func heads() -> bool:
	return odds < randf()


func deduct_coin() -> void:
	coins = max(coins - 1, 0)
