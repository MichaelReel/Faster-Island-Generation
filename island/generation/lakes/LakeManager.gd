extends Stage

const GridManager: GDScript = preload("../grid/GridManager.gd")
const RegionManager: GDScript = preload("../region/RegionManager.gd")
const RegionDivideLayer: GDScript = preload("geometry/RegionDivideLayer.gd")
const LakeLayer: GDScript = preload("geometry/LakeLayer.gd")
const LakeDebugMesh: GDScript = preload("mesh/LakeDebugMesh.gd")
const LakeOutlineMesh: GDScript = preload("mesh/LakeOutlineMesh.gd")

var _grid_manager: GridManager
var _region_manager: RegionManager
var _region_divide_layer: RegionDivideLayer
var _lake_layer: LakeLayer
var _lake_debug_mesh: LakeDebugMesh
var _lake_outline_mesh: LakeOutlineMesh
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: RegionManager,
	lake_regions: int, 
	lakes_per_region: int,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_region_manager = outline_manager
	_rng.seed = rng_seed
	
	_region_divide_layer = RegionDivideLayer.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_region_manager.get_island_outline_layer(),
		lake_regions, _rng.randi(),
	)
	_lake_layer = LakeLayer.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_region_divide_layer,
		lakes_per_region,
		_rng.randi(),
	)
	_lake_debug_mesh = LakeDebugMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_region_manager.get_island_outline_layer(),
		_region_divide_layer.get_region_indices(),
		_lake_layer.get_lake_region_indices(),
		material_lib,
	)
	_lake_outline_mesh = LakeOutlineMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_lake_layer
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_region_divide_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_lake_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_lake_debug_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_lake_outline_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.LAKE

func _to_string() -> String:
	return "Lake Stage"

func get_lake_layer() -> LakeLayer:
	return _lake_layer

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _lake_debug_mesh,
		"lake_outlines": _lake_outline_mesh,
	}
