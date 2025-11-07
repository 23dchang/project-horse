class_name BossFightManager
extends Node

const PLAYER_SCENE = preload("res://scenes/entities/player.tscn")
const BOSS_SCENE = preload("res://scenes/entities/boss.tscn")
const MAX_PLAYERS = 2

var players: Array[Entity] = []
var boss: Entity


func _ready() -> void:
	spawn_players()
	spawn_boss()
	start_boss_fight()


func spawn_players() -> void:
	var player_positions = [Vector2(-450, -200), Vector2(-400, 150)]
	
	for i in range(MAX_PLAYERS):
		var player_instance = PLAYER_SCENE.instantiate() as Entity
		player_instance.global_position = player_positions[i]
		player_instance.name = "Player_%d" % (i + 1)
		print(player_instance.name)
		
		add_child(player_instance)
		players.append(player_instance)


func spawn_boss() -> void:
	var boss_position = Vector2(200, 0)
	var boss_instance = BOSS_SCENE.instantiate() as Entity
	boss_instance.global_position = boss_position
	boss_instance.name = "Boss"
	
	add_child(boss_instance)
	boss = boss_instance


func start_boss_fight() -> void:
	
	# Transitions to the actual boss fight
	pass
