class_name OutlineManager
extends Stage

var _grid_manager: GridManager
var _island_cell_limit: int
var _region_cell_layer: RegionCellLayer
var _island_outline_layer: IslandOutlineLayer
var _island_outline_mesh: IslandOutlineMesh
var _rng := RandomNumberGenerator.new()

func _init(grid_manager: GridManager, island_cell_limit: int, material_lib: MaterialLib, rng_seed: int) -> void:
	_grid_manager = grid_manager
	_island_cell_limit = island_cell_limit
	_rng.seed = rng_seed
	
	_region_cell_layer = RegionCellLayer.new(_grid_manager.get_tri_cell_layer())
	_island_outline_layer = IslandOutlineLayer.new(_region_cell_layer, _island_cell_limit, _rng.randi())
	_island_outline_mesh = IslandOutlineMesh.new(
		_grid_manager.get_tri_cell_layer(), _region_cell_layer, _island_outline_layer, material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_region_cell_layer.perform()
	emit_signal("percent_complete", self, 33.3)
	_island_outline_layer.perform()
	emit_signal("percent_complete", self, 66.6)
	_island_outline_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Outline Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _island_outline_mesh
	}
