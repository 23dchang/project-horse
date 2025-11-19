# NOTE: BossFightManager is no longer used and is only being preserved since the
# damage logic was never ported over to combat_manager.gd or the clash system.
# Once we have a working combat manager and clash system, this script can be freely deleted.

class_name BossFightManager
extends Node

const PLAYER1_SCENE = preload("res://scenes/entities/player1.tscn")
const PLAYER2_SCENE = preload("res://scenes/entities/player2.tscn")
const BOSS_SCENE = preload("res://scenes/entities/boss.tscn")
const ARROW_SCENE := preload("res://scenes/UI/boss_preview_arrows.tscn")
const MAX_PLAYERS = 2

var players: Array[Entity] = []
var boss: Entity
var boss_preview_arrows : Node = null
#vars for turn order
var turn_order: Array[Entity] = []
var current_turn: int = 0

#health display debug
@onready var player1Health = $CanvasLayer/Player1Health
@onready var player2Health = $CanvasLayer/Player2Health
@onready var bossHealth = $CanvasLayer/BossHealth


func _ready() -> void:
	spawn_players()
	spawn_boss()
	show_boss_preview() #shows lines from boss to 
	update_health_display()
	start_boss_fight()

func spawn_players() -> void:
	var player_positions = [Vector2(-600, -150), Vector2(-200, -150)]
	#player_positions = [Vector2(-600, -120), Vector2(20, 0)] #comment out to move back to original 
	
	for i in range(MAX_PLAYERS):
		var player_instance
		if i == 0:
			player_instance = PLAYER1_SCENE.instantiate() as Entity
		if i == 1:
			player_instance = PLAYER2_SCENE.instantiate() as Entity
		player_instance.global_position = player_positions[i]
		player_instance.name = "Player_%d" % (i + 1)
		
		add_child(player_instance)
		players.append(player_instance)
			
		#generate skills bar for this player
		var bar = player_instance.get_node_or_null("SkillsBar")
		if bar:
			bar.show_bar()
			
		#generate skills column for this player
		var col = player_instance.get_node_or_null("SkillsColumn")
		if col:
			col.generate_skills()
		print((i + 1))


func spawn_boss() -> void:
	var boss_position = Vector2(600, -150)
	#boss_position = Vector2(700, 100)
	var boss_instance = BOSS_SCENE.instantiate() as Entity
	boss_instance.global_position = boss_position
	boss_instance.name = "Boss"
	
	add_child(boss_instance)
	boss = boss_instance

	#boss_preview_arrows = boss_instance.get_node("SkillsBar/TripleSkills/BossPreviewArrows")
	boss_preview_arrows = boss_instance.get_node("SkillsBar/BossPreviewArrows")
	#boss_preview_arrows = get_node("BossPreviewArrows")

	var bar: SkillsBar = boss_instance.get_node_or_null("SkillsBar")
	if bar:
		#print("Boss bar found. Showing bar.")
		bar.show_bar()
	else:
		push_error("Boss has NO SkillsBar node!")

func get_player_skill_nodes() -> Array[Control]:
	var result : Array[Control] = []

	for player in players:
		var root := player.get_node_or_null("SkillsBar/TripleSkills/EmptySkillsContainer")
		if root == null:
			continue

		for child in root.get_children():
			if child is ColorRect or child is TextureRect:
				result.append(child)

	#print("[get_player_skill_nodes] Found ", result.size(), "player skills total.")
	#for n in result:
		#print("  Player Skill:", n.name, "@", n.global_position)

	return result
	
func get_boss_skill_nodes() -> Array[Control]:
	var result : Array[Control] = []

	var root := boss.get_node_or_null("SkillsBar/TripleSkills/EmptySkillsContainer")
	if root == null:
		print("ERROR: Boss TripleSkills not found.")
		return result

	for child in root.get_children():
		# Your Skill icons are ColorRect or TextureRect
		if child is ColorRect or child is TextureRect:
			result.append(child)

	#print("[get_boss_skill_nodes] Found ", result.size(), "boss skills.")
	#for n in result:
		#print("  Boss Skill: ", n.name, " @", n.global_position)

	return result

func show_boss_preview():
	print("\n================ SHOW BOSS PROJECTIONS ================")

	# contains array of ColorRect nodes (skill icons)
	var boss_skills := get_boss_skill_nodes()
	var player_skills := get_player_skill_nodes()

	if boss_skills.is_empty():
		print("ERROR: No boss skills detected.")
		return
	if player_skills.is_empty():
		print("ERROR: No player skills detected.")
		return

	#print("\nGenerating arrows:")
	#print("  Boss skills:", boss_skills.size())
	#print("  Player skills:", player_skills.size())

	# random skill arrow mapping
	# for i in range(boss_skills.size()):
	#     var start_node = boss_skills[i]
	#     var end_node = player_skills[randi() % player_skills.size()]
	#
	#     print("\n[Arrow #", i+1, "]")
	#     print("  FROM:", start_node.name, " @", start_node.global_position)
	#     print("  TO:  ", end_node.name, " @", end_node.global_position)
	#
	#     var arrow := ARROW_SCENE.instantiate()
	#     boss_preview_arrows.add_child(arrow)
	#
	#     arrow.node_start = start_node
	#     arrow.node_end   = end_node
	
	# 1:1 skill arrow mapping
	var count: int = min(boss_skills.size(), player_skills.size())
	#print("\n=== Deterministic Mapping (1-to-1) ===")
	for i in range(count):
		var start_node = boss_skills[i]
		var end_node   = player_skills[i]

		#print("\n[Arrow #", i+1, "]")
		#print("  FROM:", start_node.name, " @", start_node.global_position)
		#print("  TO:  ", end_node.name, " @", end_node.global_position)

		var arrow := ARROW_SCENE.instantiate()
		boss_preview_arrows.add_child(arrow)

		arrow.node_start = start_node
		arrow.node_end   = end_node

	#print("\n=== All boss projection arrows generated (1:1 matching). ===")
	
	#var heads = get_tree().get_nodes_in_group("circle_heads")
	#for h in heads:
		#print("CIRCLE ->", h, " parent=", h.get_parent(), "  pos=", h.global_position)

func start_boss_fight() -> void:
	#make turn order
	_initialize_order()
	#start combat logic
	await _next_turn()


func _initialize_order() -> Array[Entity]:
	turn_order = players.duplicate()
	turn_order.append(boss)
	# Sort descending speed
	turn_order.sort_custom(_compare_speed)
	 
	#print turn order
	print ("TURN ORDER")
	for entity in turn_order:
		print("name: ", entity.name, ", speed: ", entity.speed)
	return turn_order

#func to calculate turn order; can be modified to account for speed ties?
func _compare_speed(a,b):
	# Higher speed first
	return a.speed > b.speed

# combat logic, called every turn
func _next_turn() -> void:
	var entity = turn_order[current_turn]
	print("\n-- TURN:", entity.name, "--")
	
	if entity is Player:
		await _player_turn(entity)
	else:
		await _boss_turn(entity)
	
	# Move to next turn if fight is ongoing
	current_turn = (current_turn + 1) % turn_order.size()
	#need to add logic for dead party as well
	if !boss.is_dead:
		await _next_turn()
	else:
		print("win")

#basic player turn logic; press space to attack
func _player_turn(player: Entity) -> void:
	print(player.name, " is choosing an action (press space)")
	# skill selection goes here instead of wait for space
	await _wait_for_space()
	print(player.name, " attacks")
	#placeholder damage
	boss.take_damage(10)
	print (boss.name, " takes 10 damage")
	update_health_display()

#replace this with skill selection
func _wait_for_space() -> void:
	await get_tree().create_timer(0.05).timeout  # delay to avoid double input
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept"):
			return

#boss turn; attacks randomly based on number of skill slots
#need to add skill slots having their own skills and targeting and stuff
func _boss_turn(boss_ent: Entity) -> void:
	await get_tree().create_timer(0.5).timeout
	for i in range(boss_ent.skill_slots):
		var target = randi_range(0, 1)
		print ("boss attacks ", players[target].name)
		players[target].take_damage(5)
		print (players[target].name, " takes 5 damage")
		update_health_display()
		await get_tree().create_timer(0.5).timeout

#update debug health display
func update_health_display():
	player1Health.text = "P1 HP: %d" % players[0].current_hp
	player2Health.text = "P2 HP: %d" % players[1].current_hp
	bossHealth.text = "Boss HP: %d" % boss.current_hp
