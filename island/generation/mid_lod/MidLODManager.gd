extends Stage

const LowLODLayer: GDScript = preload("geometry/LowLODLayer.gd")

var _data: TerrainData
var _meshes: TerrainMeshes

var _rng := RandomNumberGenerator.new()
var _low_lod_layer: LowLODLayer

func _init(
	_terrain_config: TerrainConfig,
	_material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed
	
	_low_lod_layer = LowLODLayer.new(
		_data.grid_tri_cell_layer,
		_data.cliff_layer,
	)


func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_low_lod_layer.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.LOCAL

func _to_string() -> String:
	return "Local Stage"

func get_mesh_dict() -> Dictionary:
	return {}

func get_height_at_xz(xz: Vector2) -> float:
	if _low_lod_layer:
		return _low_lod_layer.get_height_at_xz(xz)
	else:
		return 0.0
