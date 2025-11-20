# This should be a sibling node to the node that initializes
# SkillsLibrary. Pass the config to lib during initialization.
class_name SkillsLibraryConfig
extends Node

# === Available in the Editor ===
@export var max_skill_tiers: int = 3
@export var default_seed: int = 888
@export var default_skill_attributes: Dictionary = {
	"tier": 1,
	"max_base": 10.0,
	"max_bonus": 16.0,
	"max_coins": 3,
}

# === Technical Restraint cannot directly access from Editor ===
@onready var default_schema: SkillSchema = SkillSchema.new().load_args(default_skill_attributes)
