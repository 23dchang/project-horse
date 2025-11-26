class_name PrelimCombatHandler
extends Node

const PLAYER1_SCENE = preload("res://scenes/entities/player1.tscn")
const PLAYER2_SCENE = preload("res://scenes/entities/player2.tscn")
const ENEMY_SCENE = preload("res://scenes/entities/boss.tscn")
const MAX_PLAYERS: int = 2
const MAX_SKILL_SLOTS: int = 3

var players: Array[Entity] = []
var enemy: Entity

func setup_fight() -> void:
	spawn_players() # generates players instances with all UI child scenes
	spawn_enemy() # generates enemy instance with all UI child scenes
	init_skills() # Setup skills for all entities
	apply_skills_to_UI() # inserts placeholder skill icons in UI


func spawn_players() -> void:
	#var player_positions = [Vector2(-450, -200), Vector2(-400, 150)]
	var player_positions = [Vector2(-600, -150), Vector2(-150, -150)]
	
	for i in range(MAX_PLAYERS):
		var player_instance: Entity
		if i == 0:
			player_instance = PLAYER1_SCENE.instantiate() as Entity
		else:
			player_instance = PLAYER2_SCENE.instantiate() as Entity

		player_instance.global_position = player_positions[i]
		player_instance.name = "Player_%d" % (i + 1)
		
		add_child(player_instance)
		players.append(player_instance)
		
		#generate skills bar for player instance
		var bar = player_instance.get_node_or_null("SkillsBar")
		if bar:
			bar.generate_placeholder_skill_icons()
			
		#generate skills column for player instance
		var col = player_instance.get_node_or_null("SkillsColumn")
		if col:
			col.generate_placeholder_skill_icons()
			
		print("Player %d Generated!\n" % (i + 1))

func spawn_enemy() -> void:
	var enemy_position = Vector2(200, 0)
	enemy_position = Vector2(600, -150)
	
	var enemy_instance = ENEMY_SCENE.instantiate() as Entity
	enemy_instance.global_position = enemy_position
	enemy_instance.name = "Enemy"
	
	add_child(enemy_instance)
	enemy = enemy_instance
	
	var bar: BossSkillsBar = enemy_instance.get_node_or_null("SkillsBar")
	if bar:
		bar.show_bar()
	else:
		push_error("Boss has NO SkillsBar node!")
		

func init_skills() -> void:
	
	# TODO: We should eventually switch to using a character library instead
	# of using this hardcoded template.
	var skill_templates = {
		1: Skill.new(1),
		2: Skill.new(2),
		3: Skill.new(3)
	}

	# Assigns skills to each player
	for player in players:
		player.skills = []
		for skill_id in [1,1,1,1,1,1,2,2,2,2,3,3]:
			var skill_instance = skill_templates[skill_id].duplicate()
			player.skills.append(skill_instance)
		
		# Max skills per turn
		player.max_skill_slots = MAX_SKILL_SLOTS
	
	# Assigns skills to the enemy
	enemy.skills = []
	for skill_id in [1,1,1,2,2,3]:
		var skill_instance = skill_templates[skill_id].duplicate()
		enemy.skills.append(skill_instance)
		
func apply_skills_to_UI():
	print("Inteserting placeholder skills for all players...")
	for player in players:
		var col := player.get_node_or_null("SkillsColumn")
		if col:
			col.show_skills(player)
