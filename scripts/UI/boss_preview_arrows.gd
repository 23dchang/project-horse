class_name PreviewArrow
extends Node2D  

@onready var outline : Line2D = $OutlineLine
@onready var main    : Line2D = $MainLine
#@onready var circle  : Node2D = $CircleHead

var node_start : Node
var node_end   : Node

@export var curve_height : float = -80
@export var curve_points : int = 32
@export var trim_start : float = 20.0
@export var trim_end   : float = 20.0

func _ready():
	outline.width = 8
	outline.default_color = Color.BLACK

	main.width = 3
	main.default_color = Color.RED

	outline.z_index = 0
	main.z_index = 1

	outline.clear_points()
	main.clear_points()

func _process(_delta):
	if not node_start or not node_end:
		return

	global_position = node_start.global_position

	var full = node_end.global_position - node_start.global_position
	var length = full.length()
	var dir = full.normalized()

	var p0 = dir * trim_start
	var p2 = dir * max(length - trim_end, 0.0)

	var p1 = (p0 + p2) * 0.5
	p1.y += curve_height

	outline.clear_points()
	main.clear_points()

	for i in range(curve_points + 1):
		var t = float(i) / float(curve_points)
		var pt = p0 * pow(1 - t, 2) + p1 * 2 * (1 - t) * t + p2 * pow(t, 2)

		outline.add_point(pt)
		main.add_point(pt)

	# circle tip
	#if main.get_point_count() >= 2:
		#var p_last = main.get_point_position(main.get_point_count() - 1)
		#var p_prev = main.get_point_position(main.get_point_count() - 2)
		#var d = (p_last - p_prev).normalized()
#
		#circle.position = p_last + d * 12
