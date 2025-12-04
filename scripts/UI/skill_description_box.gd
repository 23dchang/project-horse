class_name SkillDescriptionBox
extends Control

@onready var icon_tex   : TextureRect = $Panel/Icon
@onready var name_label : Label       = $Panel/Name
@onready var description_label : Label= $Panel/SkillDescription
@onready var base_label : Label       = $Panel/Stats/BasePower
@onready var bonus_label: Label       = $Panel/Stats/CoinPower
@onready var coins_label: Label       = $Panel/Stats/Coins
@onready var odds_label : Label       = $Panel/Stats/Odds

@export var offset: Vector2 = Vector2(16, -16) # small offset from cursor/icon

func _ready() -> void:
	visible = false

func update_icon(texture: Texture2D):
	icon_tex.texture = texture

func show_for_skill(skill: Skill, icon: Texture2D, world_pos: Vector2) -> void:
	# Fill icon
	if icon:
		icon_tex.texture = icon
	elif skill.icon_texture:
		icon_tex.texture = skill.icon_texture
	
	# Fill skill information using your Skill class properties
	name_label.text = skill.get_display_name()
	description_label.text = skill.description if skill.description != "" else "No description available"
	
	base_label.text = "Base roll: %.1f" % skill.base_roll
	bonus_label.text = "Bonus roll: %.1f" % skill.bonus_roll
	coins_label.text = "Coins: %d" % skill.coins
	odds_label.text = "Odds: %s" % skill.get_odds_string()
	
	# Position near the icon (convert world -> local canvas)
	global_position = world_pos + offset
	visible = true

func hide_box() -> void:
	visible = false
