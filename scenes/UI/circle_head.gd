extends Node2D
# optional: class_name CircleHead

@export var radius: float = 10.0
@export var color: Color = Color.RED

#func _ready():
	#add_to_group("circle_heads")   # <-- tells Godot this is a circle head

#func _draw() -> void:
	#draw_circle(Vector2.ZERO, radius, color)
#
	#print("[CircleHead] _draw()")
	#print("  self:", self)
	#print("  local position:", position)
	#print("  global position:", global_position)
	#print("  parent:", get_parent())
	#print("\n")
