class_name TerrainManager
extends Object
"""
This is the primary interface for generating a terrain and returning the generated features.
"""

const GridManager: GDScript = preload("grid/GridManager.gd")
const RegionManager: GDScript = preload("region/RegionManager.gd")
const LakeManager: GDScript = preload("lakes/LakeManager.gd")
const HeightManager: GDScript = preload("height/HeightManager.gd")
const RiverManager: GDScript = preload("rivers/RiverManager.gd")
const CivilManager: GDScript = preload("civil/CivilManager.gd")
const CliffManager: GDScript = preload("cliffs/CliffManager.gd")
const LocalManager: GDScript = preload("local/LocalManager.gd")

signal stage_percent_complete(stage, percent)
signal stage_complete(stage, duration_us)
signal all_stages_complete()

var _terrain_data: TerrainData
var _terrain_meshes: TerrainMeshes

var _grid_manager: GridManager
var _region_manager: RegionManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _civil_manager: CivilManager
var _cliff_manager: CliffManager
var _local_manager: LocalManager

func _init(
	random_seed: int,
	material_lib: MaterialLib,
	tri_side: float,
	bounds_side: float,
	island_cell_limit: int,
	lake_regions: int,
	lakes_per_region: int,
	diff_height: float,
	diff_max_multi: int,
	river_count: int,
	erode_depth: float,
	settlement_spread: int,
	slope_penalty: float,
	river_penalty: float,
	min_slope_to_cliff: float,
	max_cliff_height: float,
	noise_height: float,
	upper_ground_cell_size: float,
) -> void:
	_terrain_data = TerrainData.new()
	_terrain_meshes = TerrainMeshes.new()

	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	var points_per_row = int(bounds_side / tri_side)
	_grid_manager = GridManager.new(
		tri_side, points_per_row, material_lib, _terrain_data, _terrain_meshes,
	)
	_region_manager = RegionManager.new(
		island_cell_limit, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_lake_manager = LakeManager.new(
		lake_regions, lakes_per_region, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_height_manager = HeightManager.new(
		diff_height, diff_max_multi, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_river_manager = RiverManager.new(
		river_count, erode_depth, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_civil_manager = CivilManager.new(
		settlement_spread,
		slope_penalty,
		river_penalty,
		material_lib,
		rng.randi(),
		_terrain_data,
		_terrain_meshes,
	)
	_cliff_manager = CliffManager.new(
		min_slope_to_cliff,
		max_cliff_height,
		material_lib,
		rng.randi(),
		_terrain_data,
		_terrain_meshes,
	)
	_local_manager = LocalManager.new(
		tri_side,
		bounds_side,
		noise_height,
		upper_ground_cell_size,
		material_lib,
		rng.randi(),
		_terrain_data,
		_terrain_meshes,
	)

func perform(up_to_stage: Stage.GlobalStageProgressStep = Stage.GlobalStageProgressStep.ALL) -> void:
	var stages: Array[Stage] = [
		_grid_manager,
		_region_manager,
		_lake_manager,
		_height_manager,
		_river_manager,
		_civil_manager,
		_cliff_manager,
		_local_manager,
	]
	
	for stage in stages:
		var _err = stage.connect("percent_complete", _on_stage_percent_complete)
		var time_start = Time.get_ticks_usec()
		stage.perform()
		emit_signal("stage_complete", stage, Time.get_ticks_usec() - time_start)
		if up_to_stage == stage.get_progess_step():
			break
	
	emit_signal("all_stages_complete")

func get_height_at_xz(xz: Vector2) -> float:
	if _local_manager:
		return _local_manager.get_height_at_xz(xz)
	else:
		return 0.0

func _on_stage_percent_complete(stage: Stage, percent: float):
	emit_signal("stage_percent_complete", stage, percent)
