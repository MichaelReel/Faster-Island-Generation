extends Stage


const RegionDivideLayer: GDScript = preload("geometry/RegionDivideLayer.gd")
const LakeLayer: GDScript = preload("geometry/LakeLayer.gd")
const LakeDebugMesh: GDScript = preload("mesh/LakeDebugMesh.gd")
const LakeOutlineMesh: GDScript = preload("mesh/LakeOutlineMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes
var _rng := RandomNumberGenerator.new()

func _init(
	lake_regions: int, 
	lakes_per_region: int,
	material_lib: MaterialLib,
	rng_seed: int,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	_rng.seed = rng_seed
	
	_data.region_divide_layer = RegionDivideLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.island_outline_layer,
		lake_regions,
		_rng.randi(),
	)
	_data.lake_layer = LakeLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.region_divide_layer,
		lakes_per_region,
		_rng.randi(),
	)
	_meshes.lake_debug_mesh = LakeDebugMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.island_outline_layer,
		_data.region_divide_layer.get_region_indices(),
		_data.lake_layer.get_lake_region_indices(),
		material_lib,
	)
	_meshes.lake_outline_mesh = LakeOutlineMesh.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.region_divide_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_data.lake_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_meshes.lake_debug_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_meshes.lake_outline_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.LAKE

func _to_string() -> String:
	return "Lake Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _meshes.lake_debug_mesh,
		"lake_outlines": _meshes.lake_outline_mesh,
	}
