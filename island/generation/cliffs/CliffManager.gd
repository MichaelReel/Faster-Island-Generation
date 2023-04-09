class_name CliffManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _civil_manager: CivilManager
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _min_slope: float

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_manager: LakeManager,
	height_manager: HeightManager,
	river_manager: RiverManager,
	civil_manager: CivilManager,
	min_slope: float,
	material_lib: MaterialLib,
	rng_seed: int,
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_manager = river_manager
	_civil_manager = civil_manager
	_min_slope = min_slope
	_material_lib = material_lib
	_rng.seed = rng_seed

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CLIFF

func _to_string() -> String:
	return "Cliff Stage"

func get_mesh_dict() -> Dictionary:
	return {
	}
