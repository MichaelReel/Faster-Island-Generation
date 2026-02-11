extends Stage

const LowLODAggregateLayer: GDScript = preload("geometry/LowLODAggregateLayer.gd")
const MidLODPointLayer: GDScript = preload("geometry/MidLODPointLayer.gd")
const MidLODTriCellLayer: GDScript = preload("geometry/MidLODTriCellLayer.gd")
const MidLODBaseMesh: GDScript = preload("mesh/MidLODBaseMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes

var _rng := RandomNumberGenerator.new()

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
	
	_data.low_lod_agg_layer = LowLODAggregateLayer.new(
		_data.grid_tri_cell_layer,
		_data.cliff_layer,
	)
	
	_data.mid_lod_point_layer = MidLODPointLayer.new(
		_data.grid_tri_cell_layer,
		_data.low_lod_agg_layer,
		_terrain_config.mid_lod_subdivision,
	)
	
	_data.mid_lod_tri_cell_layer = MidLODTriCellLayer.new(
		_data.grid_tri_cell_layer,
		_data.mid_lod_point_layer,
		_terrain_config.mid_lod_subdivision,
	)
	
	_meshes.mid_lod_base_mesh = MidLODBaseMesh.new(
		_data.grid_tri_cell_layer,
		_data.mid_lod_tri_cell_layer,
		_material_lib,
	)


func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.low_lod_agg_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_data.mid_lod_point_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_data.mid_lod_tri_cell_layer.perform()
	emit_signal("percent_complete", self, 75.0)
	_meshes.mid_lod_base_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.LOCAL

func _to_string() -> String:
	return "Local Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _meshes.mid_lod_base_mesh
	}
