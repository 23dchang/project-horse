class_name Entity
extends CharacterBody2D

# Combat state
var current_hp: float = 0.0
@export var max_hp: float = 50.0
var is_defending: bool = false
var is_dead: bool = false
@export var skills: Array = []
@export var speed: float = 5
var max_skill_slots: int = 3

# Number of allowed moves
@export var moves: int = 1

# Animation and visuals
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	current_hp = max_hp


# Damage handling
func take_damage(amount: float) -> void:
	if is_dead:
		return
	
	current_hp -= amount
	current_hp = max(0.0, current_hp)
	
	play_animation("damaged")
	
	if current_hp <= 0:
		die()


# Animation control
func play_animation(anim_name: String) -> void:
	#if sprite and sprite.sprite_frames.has_animation(anim_name):
		#sprite.play(anim_name)
	
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


# Handles death
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	play_animation("death")


# Gets current HP%
func get_hp_percentage() -> float:
	return (current_hp / max_hp) * 100.0


# Checks if entity is alive
func is_alive() -> bool:
	return not is_dead and current_hp > 0
