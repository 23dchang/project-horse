class_name SkillDescriptionBox
extends Control

@onready var icon_tex   : TextureRect = $Panel/Icon
@onready var name_label : Label       = $Panel/Name
@onready var description_label : Label= $Panel/SkillDescription
@onready var base_label : Label       = $Panel/Stats/BaseRoll
@onready var bonus_label: Label       = $Panel/Stats/BonusRoll
@onready var coins_label: Label       = $Panel/Stats/Coins
@onready var odds_label : Label       = $Panel/Stats/Odds
@export var offset: Vector2 = Vector2(16, -16) # small offset from cursor/icon

func _ready() -> void:
	visible = false

func update_icon(texture: Texture2D):
	icon_tex.texture = texture

func show_for_skill(skill: Skill, icon: Texture2D, world_pos: Vector2) -> void:
	# Fill fields
	if icon:
		icon_tex.texture = icon
	name_label.text  = skill.name
	base_label.text  = "Base roll: %d" % skill.base_roll
	bonus_label.text = "Bonus roll: %d" % skill.bonus_roll
	coins_label.text = "Coins: %d" % skill.coin_cost
	odds_label.text  = "Odds: %s" % skill.odds_string  # adapt to your APIodds_label.text  = "Odds: %s" % skill.odds_string  # adapt to your API
	description_label.text = "Description: This ability lets you beat the boss in one shot and you win"

	# Position near the icon (convert world -> local canvas)
	global_position = world_pos + offset

	visible = true

func hide_box() -> void:
	visible = false
