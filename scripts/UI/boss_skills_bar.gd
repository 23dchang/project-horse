class_name BossSkillsBar
extends Control

@export var y_offset := -130
@onready var bar_3: Control = $TripleSkills
# The node that will HOLD all arrow instances
@onready var boss_preview_arrows : Node = $BossPreviewArrows

# Preload arrow scene
const ARROW_SCENE := preload("res://scenes/UI/boss_preview_arrows.tscn")

# References that BattleManager or ActionHandler MUST inject
var players : Array = []
var boss : Node = null

func _ready():
	# position skill boxes y above player
	position.y = y_offset

# Call this from Player.gd
func show_bar():
	bar_3.visible = true
	
func show_preview_arrows():
	for arrow in boss_preview_arrows.get_children():
		arrow.visible = true

func hide_preview_arrows():
	for arrow in boss_preview_arrows.get_children():
		arrow.visible = false

func setup(players_array: Array, boss_ref: Node) -> void:
	# Called by BattleManager or ActionHandler after spawning characters
	players = players_array
	boss = boss_ref
	print("[BossSkillsBar] setup(): players + boss assigned.")

## GET PLAYER SKILL ICONS
#func get_player_skill_nodes() -> Array[Control]:
	#var result: Array[Control] = []
#
	#for p in players:
		#var root : Control = p.get_node_or_null("BossSkillsBar/TripleSkills/EmptySkillsContainer")
		#if root == null:
			#continue
#
		#for child in root.get_children():
			#if child is ColorRect or child is TextureRect:
				#result.append(child)
#
	#print("[BossSkillsBar] Found ", result.size(), " player skill nodes.")
	#return result
#
## GET BOSS SKILL ICONS
#func get_boss_skill_nodes() -> Array[Control]:
	#var result: Array[Control] = []
#
	#if boss == null:
		#print("[BossSkillsBar] ERROR: boss reference not set.")
		#return result
#
	#var root := boss.get_node_or_null("SkillsBar/TripleSkills/EmptySkillsContainer")
	#if root == null:
		#print("[BossSkillsBar] ERROR: Boss TripleSkills not found.")
		#return result
#
	#for child in root.get_children():
		#if child is ColorRect or child is TextureRect:
			#result.append(child)
#
	#print("[BossSkillsBar] Found", result.size(), "boss skill nodes.")
	#return result
#
##   SHOW BOSS PREVIEW ARROWS
#func show_boss_preview() -> void:
	#print("\n================ SHOW BOSS PROJECTIONS ================")
#
	#var boss_skills := get_boss_skill_nodes()
	#var player_skills := get_player_skill_nodes()
#
	#if boss_skills.is_empty():
		#print("ERROR: No boss skills detected.")
		#return
	#if player_skills.is_empty():
		#print("ERROR: No player skills detected.")
		#return
#
	## Clear old arrows each time
	#for child in boss_preview_arrows.get_children():
		#child.queue_free()
#
	#print("\n=== Deterministic Mapping (1-to-1) ===")
	#var count: int = min(boss_skills.size(), player_skills.size())
#
	#for i in range(count):
		#var start_node = boss_skills[i]
		#var end_node   = player_skills[i]
#
		#print("[Arrow #", i+1, "]  FROM:", start_node.name, "  TO:", end_node.name)
#
		#var arrow := ARROW_SCENE.instantiate()
		#boss_preview_arrows.add_child(arrow)
#
		#arrow.node_start = start_node
		#arrow.node_end   = end_node
#
	#print("\n=== All boss projection arrows generated ===")
