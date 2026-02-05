extends Stage

const CliffLayer: GDScript = preload("geometry/CliffLayer.gd")
const CliffLineMesh: GDScript = preload("mesh/CliffLineMesh.gd")
const CliffTerrainMesh: GDScript = preload("mesh/CliffTerrainMesh.gd")

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
	
	_data.cliff_layer = CliffLayer.new(
		_data.grid_tri_cell_layer,
		_data.lake_layer,
		_data.height_layer,
		_data.river_layer,
		_data.road_layer,
		terrain_config.min_slope_to_cliff,
		terrain_config.max_cliff_height,
	)
	
	_meshes.cliff_line_mesh = CliffLineMesh.new(
		_data.grid_tri_cell_layer,
		_data.cliff_layer
	)
	
	_meshes.cliff_terrain_mesh = CliffTerrainMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.cliff_layer,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.cliff_layer.perform()
	emit_signal("percent_complete", self, 33.3)
	_meshes.cliff_line_mesh.perform()
	emit_signal("percent_complete", self, 66.6)
	_meshes.cliff_terrain_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CLIFF

func _to_string() -> String:
	return "Cliff Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"cliff_debug": _meshes.cliff_line_mesh,
		"terrain": _meshes.cliff_terrain_mesh,
	}
