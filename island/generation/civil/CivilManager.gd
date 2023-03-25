class_name CivilManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_manager: LakeManager,
	height_manager: HeightManager,
	river_manager: RiverManager,
	material_lib: MaterialLib,
	rng_seed: int,
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_manager = river_manager
	_material_lib = material_lib
	_rng.seed = rng_seed
	
	# TODO: Create settlement and road layers here

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CIVIL

func _to_string() -> String:
	return "Civil Stage"

func get_mesh_dict() -> Dictionary:
	return {}
