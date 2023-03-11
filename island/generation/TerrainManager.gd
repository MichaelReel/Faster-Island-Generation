class_name TerrainManager
extends Object
"""
This is the primary interface for generating a terrain and returning the generated features.
"""

signal stage_percent_complete(stage, percent)
signal stage_complete(stage, duration_us)
signal all_stages_complete()

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager

func _init(
	random_seed: int,
	material_lib: MaterialLib,
	tri_side: float,
	bounds_side: float,
	island_cell_limit: int,
	lake_regions: int,
	lakes_per_region: int,
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	var points_per_row = int(bounds_side / tri_side)
	_grid_manager = GridManager.new(tri_side, points_per_row, material_lib)
	_outline_manager = OutlineManager.new(_grid_manager, island_cell_limit, material_lib, rng.randi())
	_lake_manager = LakeManager.new(_grid_manager, _outline_manager, lake_regions, lakes_per_region, material_lib, rng.randi())
	_height_manager = HeightManager.new(_grid_manager, _outline_manager, _lake_manager, material_lib, rng.randi())

func perform(up_to_stage_with_name: String = "") -> void:
	var stages: Array[Stage] = [
		_grid_manager,
		_outline_manager,
		_lake_manager,
		_height_manager,
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
