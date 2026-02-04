extends Stage

const BaseContinuityLayer: GDScript = preload("geometry/BaseContinuityLayer.gd")
const NoiseAddLayer: GDScript = preload("geometry/NoiseAddLayer.gd")
const NoiseDebugMesh: GDScript = preload("mesh/NoiseDebugMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes

var _rng := RandomNumberGenerator.new()
var _base_continuity_layer: BaseContinuityLayer
var _noise_add_layer: NoiseAddLayer
var _noise_debug_mesh: NoiseDebugMesh

func _init(
	tri_side: float,
	bounds_side: float,
	noise_height: float,
	upper_ground_cell_size: float,
	material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed
	
	_base_continuity_layer = BaseContinuityLayer.new(
		_data.grid_tri_cell_layer,
		_data.cliff_layer,
	)
	_noise_add_layer = NoiseAddLayer.new(
		_base_continuity_layer,
		_rng.randi(),
		noise_height,
	)
	_noise_debug_mesh = NoiseDebugMesh.new(
		_data.grid_point_layer,
		_noise_add_layer,
		tri_side,
		bounds_side,
		upper_ground_cell_size,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_base_continuity_layer.perform()
	#_noise_add_layer.perform()
	#_noise_debug_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.LOCAL

func _to_string() -> String:
	return "Local Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"upper_terrain": _noise_debug_mesh
	}

func get_height_at_xz(xz: Vector2) -> float:
	if _base_continuity_layer:
		return _base_continuity_layer.get_height_at_xz(xz)
	else:
		return 0.0
