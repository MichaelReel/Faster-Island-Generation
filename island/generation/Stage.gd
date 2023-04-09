class_name Stage
extends Object
"""
Base interface for each stage
"""

signal percent_complete(stage, percent)

enum GlobalStageProgressStep {
	GRID,
	OUTLINE,
	LAKE,
	HEIGHT,
	RIVER,
	CIVIL,
	CLIFF,
	ALL,
}

func perform() -> void:
	pass

func get_mesh_dict() -> Dictionary:
	return {}

func get_progess_step() -> GlobalStageProgressStep:
	return GlobalStageProgressStep.ALL

func _to_string() -> String:
	return "Unnamed Stage"
