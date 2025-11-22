## Enables editor modification
class_name EntitySchema
extends Resource

@export var name:String = "Miku"
@export var icon:Texture = null
@export var max_hp: float = 50.0
@export var skills: Array[Skill] = []
@export var speed: float = 5

# Number of allowed moves
@export var moves: int = 1
