# Small demo script for entity/skill lib.
extends Node

var skills_lib: SkillsLibrary
var entity_lib: EntityLibrary
var gen: SkillsLibrary.SkillGenerator
var test_entity: Entity = Entity.new()
var s = SkillSchema.new()

var active = false


func _ready() -> void:
	skills_lib = SkillsLibrary.new($SkillsLibConfig)
	entity_lib = EntityLibrary.new($EntityLibConfig, skills_lib)
	gen = skills_lib.generator()
	s.tier = 3
	s.max_base = 10
	s.max_bonus = 16
	s.max_coins = 3


'''
Skills Runtime 1:
Skill(skill_id=0, base_roll=1.333, bonus_roll=18.667, 	coins=2, odds=0.500)
Skill(skill_id=1, base_roll=13.333, bonus_roll=20.000, 	coins=2, odds=0.500)
Skill(skill_id=2, base_roll=4.000, bonus_roll=5.333, 	coins=3, odds=0.500)
Skill(skill_id=3, base_roll=1.333, bonus_roll=16.000, 	coins=1, odds=0.500)
Skill(skill_id=4, base_roll=12.000, bonus_roll=10.667, 	coins=3, odds=0.500)

Skills Runtime 2:
Skill(skill_id=0, base_roll=1.333, bonus_roll=18.667, 	coins=2, odds=0.500)
Skill(skill_id=1, base_roll=13.333, bonus_roll=20.000, 	coins=2, odds=0.500)
Skill(skill_id=2, base_roll=4.000, bonus_roll=5.333, 	coins=3, odds=0.500)
Skill(skill_id=3, base_roll=1.333, bonus_roll=16.000, 	coins=1, odds=0.500)
Skill(skill_id=4, base_roll=12.000, bonus_roll=10.667, 	coins=3, odds=0.500)
Skill(skill_id=5, base_roll=9.333, bonus_roll=6.667, 	coins=1, odds=0.500)

Summary - behaviors are consistent
'''


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		print(gen.gen_random_skill(s))

	if Input.is_key_pressed(KEY_T) and not active:
		active = true
		entity_lib.initialize_skills(test_entity)
		'''
		Runtime 1:
		Skills generated (expecting 6): 6
		Skill(skill_id=0, base_roll=1.000, bonus_roll=1.000, 	coins=1, odds=0.500)
		Skill(skill_id=1, base_roll=2.373, bonus_roll=5.143, 	coins=3, odds=0.500)
		Skill(skill_id=2, base_roll=1.574, bonus_roll=3.780, 	coins=2, odds=0.500)
		Skill(skill_id=3, base_roll=3.396, bonus_roll=6.190, 	coins=3, odds=0.500)
		Skill(skill_id=4, base_roll=3.834, bonus_roll=10.616, 	coins=2, odds=0.500)
		Skill(skill_id=5, base_roll=9.717, bonus_roll=14.850, 	coins=1, odds=0.500)

		Runtime 2:
		Skills generated (expecting 6): 6
		Skill(skill_id=0, base_roll=1.000, bonus_roll=1.000, 	coins=1, odds=0.500)
		Skill(skill_id=1, base_roll=2.373, bonus_roll=5.143, 	coins=3, odds=0.500)
		Skill(skill_id=2, base_roll=1.574, bonus_roll=3.780, 	coins=2, odds=0.500)
		Skill(skill_id=3, base_roll=3.396, bonus_roll=6.190, 	coins=3, odds=0.500)
		Skill(skill_id=4, base_roll=3.834, bonus_roll=10.616, 	coins=2, odds=0.500)
		Skill(skill_id=5, base_roll=9.717, bonus_roll=14.850, 	coins=1, odds=0.500)
		
		Consistent. Good
		'''
		print("Skills generated (expecting 6): ", len(test_entity.skills))
		for skill in test_entity.skills:
			print(skill)
