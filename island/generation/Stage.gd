class_name Stage
extends Object
"""
Base interface for each stage
"""

signal percent_complete(stage, percent)

func perform() -> void:
	pass

func get_mesh_dict() -> Dictionary:
	return {}

func _to_string() -> String:
	return "Unnamed Stage"
