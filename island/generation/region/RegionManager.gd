extends Stage

const GridManager: GDScript = preload("../grid/GridManager.gd")
const IslandOutlineLayer: GDScript = preload("geometry/IslandOutlineLayer.gd")
const RegionCellLayer: GDScript = preload("geometry/RegionCellLayer.gd")
const IslandDebugMesh: GDScript = preload("mesh/IslandDebugMesh.gd")
const IslandOutlineMesh: GDScript = preload("mesh/IslandOutlineMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes
var _rng := RandomNumberGenerator.new()

func _init(
	terrain_config: TerrainConfig,
	material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed
	
	_data.region_cell_layer = RegionCellLayer.new(_data.grid_tri_cell_layer)
	_data.island_outline_layer = IslandOutlineLayer.new(
		_data.grid_tri_cell_layer, _data.region_cell_layer, terrain_config.island_cell_limit, _rng.randi()
	)
	_meshes.island_debug_mesh = IslandDebugMesh.new(
		_data.grid_tri_cell_layer, _data.region_cell_layer, _data.island_outline_layer, material_lib
	)
	_meshes.island_outline_mesh = IslandOutlineMesh.new(
		_data.grid_tri_cell_layer, _data.region_cell_layer, _data.island_outline_layer
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.region_cell_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_data.island_outline_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_meshes.island_debug_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_meshes.island_outline_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.OUTLINE

func _to_string() -> String:
	return "Outline Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _meshes.island_debug_mesh,
		"island_outline": _meshes.island_outline_mesh,
	}
