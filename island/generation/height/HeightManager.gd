extends Stage

const HeightLayer: GDScript = preload("geometry/HeightLayer.gd")
const HeightMesh: GDScript = preload("mesh/HeightMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes
var _rng := RandomNumberGenerator.new()

func _init(
	diff_height: float,
	diff_max_multi: int,
	material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed

	_data.height_layer = HeightLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.island_outline_layer,
		_data.lake_layer,
		diff_height,
		diff_max_multi,
		_rng.randi()
	)
	_meshes.height_mesh = HeightMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer,
		material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.height_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_meshes.height_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.HEIGHT

func _to_string() -> String:
	return "Height Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _meshes.height_mesh,
	}
