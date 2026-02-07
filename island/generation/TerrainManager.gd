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
const MidLODManager: GDScript = preload("mid_lod/MidLODManager.gd")

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
var _mid_lod_manager: MidLODManager

func _init(
	random_seed: int,
	material_lib: MaterialLib,
	terrain_config: TerrainConfig,
) -> void:
	_terrain_data = TerrainData.new()
	_terrain_meshes = TerrainMeshes.new()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	
	_grid_manager = GridManager.new(
		terrain_config, material_lib, _terrain_data, _terrain_meshes,
	)
	_region_manager = RegionManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_lake_manager = LakeManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_height_manager = HeightManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_river_manager = RiverManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_civil_manager = CivilManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_cliff_manager = CliffManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
	)
	_mid_lod_manager = MidLODManager.new(
		terrain_config, material_lib, rng.randi(), _terrain_data, _terrain_meshes,
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
		_mid_lod_manager,
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
	if _terrain_data:
		return _terrain_data.get_height_at_xz(xz)
	else:
		return 0.0

func _on_stage_percent_complete(stage: Stage, percent: float):
	emit_signal("stage_percent_complete", stage, percent)
