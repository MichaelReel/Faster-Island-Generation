class_name RiverManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_count: int
var _erode_depth: float
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _river_layer: RiverLayer
var _river_mesh: RiverMesh

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_manager: LakeManager,
	height_manager: HeightManager,
	river_count: int,
	erode_depth: float,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_count = river_count
	_erode_depth = erode_depth
	_material_lib = material_lib
	_rng.seed = rng_seed
	
	_river_layer = RiverLayer.new(
		_lake_manager.get_lake_layer(),
		_outline_manager.get_region_cell_layer(),
		_height_manager.get_height_layer(),
		_river_count,
		_erode_depth,
		_rng.randi(),
	)
	_river_mesh = RiverMesh.new(
		_outline_manager.get_region_cell_layer(),
		_height_manager.get_height_layer(),
		_river_layer
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_river_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_river_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.RIVER

func _to_string() -> String:
	return "River Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"rivers": _river_mesh
	}
