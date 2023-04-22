extends Stage

const GridManager: GDScript = preload("../grid/GridManager.gd")
const IslandOutlineLayer: GDScript = preload("geometry/IslandOutlineLayer.gd")
const RegionCellLayer: GDScript = preload("geometry/RegionCellLayer.gd")
const IslandDebugMesh: GDScript = preload("mesh/IslandDebugMesh.gd")
const IslandOutlineMesh: GDScript = preload("mesh/IslandOutlineMesh.gd")

var _grid_manager: GridManager
var _island_cell_limit: int
var _region_cell_layer: RegionCellLayer
var _island_outline_layer: IslandOutlineLayer
var _island_debug_mesh: IslandDebugMesh
var _island_outline_mesh: IslandOutlineMesh
var _rng := RandomNumberGenerator.new()

func _init(grid_manager: GridManager, island_cell_limit: int, material_lib: MaterialLib, rng_seed: int) -> void:
	_grid_manager = grid_manager
	_island_cell_limit = island_cell_limit
	_rng.seed = rng_seed
	
	_region_cell_layer = RegionCellLayer.new(_grid_manager.get_tri_cell_layer())
	_island_outline_layer = IslandOutlineLayer.new(
		_grid_manager.get_tri_cell_layer(), _region_cell_layer, _island_cell_limit, _rng.randi()
	)
	_island_debug_mesh = IslandDebugMesh.new(
		_grid_manager.get_tri_cell_layer(), _region_cell_layer, _island_outline_layer, material_lib
	)
	_island_outline_mesh = IslandOutlineMesh.new(
		_grid_manager.get_tri_cell_layer(), _region_cell_layer, _island_outline_layer
	)
	

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_region_cell_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_island_outline_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_island_debug_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_island_outline_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.OUTLINE

func _to_string() -> String:
	return "Outline Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _island_debug_mesh,
		"island_outline": _island_outline_mesh,
	}

func get_region_cell_layer() -> RegionCellLayer:
	return _region_cell_layer

func get_island_outline_layer() -> IslandOutlineLayer:
	return _island_outline_layer
