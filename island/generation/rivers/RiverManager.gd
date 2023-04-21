class_name RiverManager
extends Stage

const HeightMesh = preload("../height/mesh/HeightMesh.gd")
const RiverLayer = preload("geometry/RiverLayer.gd")
const WaterMesh = preload("mesh/WaterMesh.gd")
const DebugRiverMesh = preload("mesh/DebugRiverMesh.gd")

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_count: int
var _erode_depth: float
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _river_layer: RiverLayer
var _water_mesh: WaterMesh
var _debug_mesh: DebugRiverMesh
var _eroded_height_mesh: HeightMesh

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
		_grid_manager.get_tri_cell_layer(),
		_outline_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_height_manager.get_height_layer(),
		_river_count,
		_erode_depth,
		_rng.randi(),
	)
	_water_mesh = WaterMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_outline_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_height_manager.get_height_layer(),
		_river_layer,
		material_lib
	)
	_debug_mesh = DebugRiverMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_height_manager.get_height_layer(),
		_river_layer
	)
	_eroded_height_mesh = HeightMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_outline_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_height_manager.get_height_layer(),
		material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_river_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_water_mesh.perform()
	emit_signal("percent_complete", self, 50.0)
	_debug_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_eroded_height_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.RIVER

func _to_string() -> String:
	return "River Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"rivers": _water_mesh,
		"river_debug": _debug_mesh,
		"terrain": _eroded_height_mesh,
	}

func get_river_layer() -> RiverLayer:
	return _river_layer
