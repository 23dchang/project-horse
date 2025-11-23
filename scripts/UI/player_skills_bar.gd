# player_skills_bar.gd
class_name SkillsBar
extends Control

@export var y_offset := -130

@onready var bar_3: Control = $TripleSkills

@onready var empty_container: GridContainer  = $TripleSkills/EmptySkillsContainer
#@onready var skills_container: GridContainer = $TripleSkills/SkillsContainer


func _ready():
	# position skill boxes above player
	position.y = y_offset

	
func generate_placeholder_skill_icons():
	print("[PlayerSkillsBar] generate_placeholder_skill_icons()")
	bar_3.visible = true
