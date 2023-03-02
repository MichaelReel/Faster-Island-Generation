class_name TerrainManager
extends Object
"""
This is the primary interface for generating a terrain and returning the generated features.
"""

signal stage_percent_complete(stage, percent)
signal stage_complete(stage, duration_us)
signal all_stages_complete()

var _grid_manager: GridManager

func _init(
	random_seed: int,
	tri_side: float,
	bounds_side: float
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	var points_per_row = int(bounds_side / tri_side)
	_grid_manager = GridManager.new(tri_side, points_per_row)

func perform(up_to_stage_with_name: String = "") -> void:
	var stages: Array[Stage] = [
		_grid_manager
	]
	
	for stage in stages:
		var _err = stage.connect("percent_complete", _on_stage_percent_complete)
		var time_start = Time.get_ticks_usec()
		stage.perform()
		emit_signal("stage_complete", stage, Time.get_ticks_usec() - time_start)
		if up_to_stage_with_name == str(stage):
			break
	
	emit_signal("all_stages_complete")

func _on_stage_percent_complete(stage: Stage, percent: float):
	emit_signal("stage_percent_complete", stage, percent)
