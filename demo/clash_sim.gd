extends Node2D

@export var up_down_fluct:float = 10
@export var slap_back_dist:float = 200

var throw_to_ends_timer:Timer

@onready var p1:CharacterBody2D = $P1
@onready var p2:CharacterBody2D = $P2


func _physics_process(delta: float) -> void:
	var dist = (p1.global_position - p2.global_position).length()
	var dir = (p1.global_position - p2.global_position).normalized()
	
	if throw_to_ends_timer and not throw_to_ends_timer.is_stopped():
		p1.velocity = slap_back_dist * dir
		p2.velocity = -slap_back_dist * dir
		p1.move_and_slide()
		p2.move_and_slide()
		return
	
	p1.velocity = -1/(dist * 0.000001+0.001) * dir
	p2.velocity = 1/(dist * 0.000001+0.001) * dir
	
	p1.move_and_slide()
	p2.move_and_slide()
	
	if p1.get_slide_collision_count() > 0:
		
		throw_to_ends_timer = Timer.new()
		add_child(throw_to_ends_timer)
		throw_to_ends_timer.one_shot = true
		throw_to_ends_timer.start(randf())
		
	pass
	
	
	
	
	
