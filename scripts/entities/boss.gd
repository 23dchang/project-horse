class_name Boss
extends Entity

# Stats + Skills


@onready var preview_arrows := $SkillsBar/BossPreviewArrows

func _ready():
	#preview_arrows.visible = false  # default hidden
	var area := $HoverArea
	area.mouse_entered.connect(_on_boss_hover)
	area.mouse_exited.connect(_on_boss_exit)
	
func _on_boss_hover():
	var bar := get_node_or_null("SkillsBar")
	if bar:
		bar.show_preview_arrows()

func _on_boss_exit():
	var bar := get_node_or_null("SkillsBar")
	if bar:
		bar.hide_preview_arrows()

#func _on_hover_area_mouse_entered() -> void:
	#preview_arrows.visible = true
	#
#func _on_hover_area_mouse_exited() -> void:
	#preview_arrows.visible = false
