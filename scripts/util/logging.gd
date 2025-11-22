class_name Logging
extends RefCounted

static var debug_mode:bool = true

static func log(msg: String) -> void:
	if not debug_mode: return
	print(msg)
