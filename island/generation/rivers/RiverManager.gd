extends Stage

const RiverLayer: GDScript = preload("geometry/RiverLayer.gd")
const WaterMesh: GDScript = preload("mesh/WaterMesh.gd")
const DebugRiverMesh: GDScript = preload("mesh/DebugRiverMesh.gd")
const HeightMesh: GDScript = preload("../height/mesh/HeightMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes
var _rng := RandomNumberGenerator.new()

func _init(
	river_count: int,
	erode_depth: float,
	material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed
	
	_data.river_layer = RiverLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer,
		river_count,
		erode_depth,
		_rng.randi(),
	)
	_meshes.water_mesh = WaterMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer,
		_data.river_layer,
		material_lib
	)
	_meshes.debug_river_mesh = DebugRiverMesh.new(
		_data.grid_tri_cell_layer,
		_data.height_layer,
		_data.river_layer
	)
	_meshes.eroded_height_mesh = HeightMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer,
		material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.river_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_meshes.water_mesh.perform()
	emit_signal("percent_complete", self, 50.0)
	_meshes.debug_river_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_meshes.eroded_height_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.RIVER

func _to_string() -> String:
	return "River Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"rivers": _meshes.water_mesh,
		"river_debug": _meshes.debug_river_mesh,
		"terrain": _meshes.eroded_height_mesh,
	}
