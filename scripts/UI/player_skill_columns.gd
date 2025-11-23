class_name SkillsColumn
extends Control

const SKILL_ICONS : Array[Texture2D] = [
	preload("res://assets/UI_Visuals/Skills_Icons/guard.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/heavy_melee.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/light_attack.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/light_spell.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/magic_guard.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/melee_buff.png"),
	preload("res://assets/UI_Visuals/Skills_Icons/team_heal.png"),
]

@onready var col1: GridContainer = $LayoutAnchorFixer/TripleCol/Column1/SkillsContainer
@onready var col2: GridContainer = $LayoutAnchorFixer/TripleCol/Column2/SkillsContainer
@onready var col3: GridContainer = $LayoutAnchorFixer/TripleCol/Column3/SkillsContainer
@onready var desc_box: SkillDescriptionBox = $CanvasLayer/SkillDescriptionBox
@onready var root_3 = $LayoutAnchorFixer/TripleCol

# sibling under the same Player node
@onready var player_bar: SkillsBar = (get_parent().get_node_or_null("SkillsBar")) as SkillsBar

@export var offset_position: Vector2 = Vector2(400, 0)
var _original_position: Vector2

var columns: Array
const ROWS_PER_COLUMN := 3

func _ready():
	root_3.visible = false
	columns = [col1, col2, col3]
	desc_box.visible = false
	#print("[SkillsColumn] Ready.")
	# TODO: UI centering bug. Description boxes hovering when shifted
	#_original_position = position   
	#position = _original_position + offset_position

func generate_placeholder_skill_icons():
	print("[SkillsColumn] generate_placeholder_skill_icons()")
	root_3.visible = true
	 # Connect hover signals to existing ColorRects
	for container in columns:
		for icon in container.get_children():
			if not icon.mouse_entered.is_connected(_on_icon_hover_enter):
				icon.mouse_entered.connect(_on_icon_hover_enter.bind(icon))
			if not icon.mouse_exited.is_connected(_on_icon_hover_exit):
				icon.mouse_exited.connect(_on_icon_hover_exit.bind(icon))

func _on_icon_hover_enter(icon: Control):
	# TextureRect case (real skills later)
	if icon is TextureRect:
		desc_box.icon_tex.texture = icon.texture
		desc_box.name_label.text = icon.get_meta("skill").name if icon.get_meta("skill") != null else ""
		desc_box.visible = true

	# Placeholder case
	elif icon is ColorRect:
		desc_box.icon_tex.texture = null
		desc_box.name_label.text = "Placeholder"
		desc_box.visible = true

	# Label case (P)
	elif icon is Label:
		desc_box.icon_tex.texture = null

		var px = icon.get_meta("px_code")
		if px:
			desc_box.name_label.text = px
		else:
			desc_box.name_label.text = icon.text  # fallback

		desc_box.visible = true

	# Follow cursor
	desc_box.position = get_viewport().get_mouse_position() + Vector2(20, 20)

func _on_icon_hover_exit(icon: Control):
	#print("[Hover] exit")
	desc_box.visible = false

#func populate_skill_icons(available_skills: Array):
	#print("[SkillsColumn] populate_skill_icons() with", available_skills.size(), "skills")
#
	#var skill_index := 0   # where we are in the player's skill list
#
	#for col_i in range(columns.size()):
		#var container = columns[col_i]
#
		#for row_i in range(container.get_child_count()):
			#if skill_index >= available_skills.size():
				## no more skills → leave placeholder
				#continue
#
			#var skill: Skill = available_skills[skill_index]
			#var icon_node = container.get_child(row_i)
#
			## Switch placeholder (ColorRect) to TextureRect if needed
			#if icon_node is ColorRect:
				#var tex_node := TextureRect.new()
				#tex_node.custom_minimum_size = icon_node.custom_minimum_size
				#tex_node.size = icon_node.size
				#container.remove_child(icon_node)
				#icon_node.queue_free()
				#icon_node = tex_node
				#container.add_child(icon_node)
#
			## Assign icon + skill metadata
			#if icon_node is TextureRect:
				#icon_node.texture = skill.icon_texture
				#icon_node.set_meta("skill", skill)
#
			## Connect hover signals
			#icon_node.mouse_entered.connect(_on_icon_hover_enter.bind(icon_node))
			#icon_node.mouse_exited.connect(_on_icon_hover_exit.bind(icon_node))
#
			##print("  [+] Column", col_i, "Row", row_i, "SkillID =", skill.skill_id)
#
			#skill_index += 1


#  ASSIGN REAL SKILLS AND CONNECT HOVER EVENTS
func show_skills(player: Entity) -> void:
	print("\n[SkillsColumn] show_skills() for", player.name)

	var skills = player.skills
	var skill_index := 0

	print("  Total skills found =", skills.size())

	for col_i in range(columns.size()):
		
		var container = columns[col_i]

		for row_i in range(container.get_child_count()):
			var icon = container.get_child(row_i)
			print("[DEBUG show_skills BEFORE] Column", col_i+1, "Row", row_i+1, "is:", icon.get_class())

			# Reset metadata + signals
			icon.set_meta("skill", null)
			#_disconnect_hover(icon)

			if skill_index >= skills.size():
				#print("    [-] No skill for Column", col_i, "Row", row_i, "(empty slot)")
				continue

			# Assign real skill
			var skill: Skill = skills[skill_index]
			icon.set_meta("skill", skill)

			#print("    [+] Skill assigned -> Column", col_i,
				  #"Row", row_i, "SkillID =", skill.skill_id)

			# Set real texture if provided
			if icon is TextureRect and skill.icon_texture:
				icon.texture = skill.icon_texture
				#print("       Set icon texture:", skill.icon_texture.resource_path)

			##_connect_hover(icon)
			#print("       Hover connected.")

			skill_index += 1

	print("[SkillsColumn] Skill assignment complete.\n")
