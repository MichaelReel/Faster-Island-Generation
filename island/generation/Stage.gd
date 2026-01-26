@abstract class_name Stage
extends Object
"""
Base interface for each stage
"""

@warning_ignore("unused_signal")
signal percent_complete(stage, percent)

enum GlobalStageProgressStep {
	GRID,
	OUTLINE,
	LAKE,
	HEIGHT,
	RIVER,
	CIVIL,
	CLIFF,
	LOCAL,
	ALL,
}

@abstract func perform() -> void

func get_mesh_dict() -> Dictionary:
	return {}

func get_progess_step() -> GlobalStageProgressStep:
	return GlobalStageProgressStep.ALL

@abstract func _to_string() -> String
