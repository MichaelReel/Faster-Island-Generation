extends Stage

const SettlementLayer: GDScript = preload("geometry/SettlementLayer.gd")
const RoadLayer: GDScript = preload("geometry/RoadLayer.gd")
const SettlementsMesh: GDScript = preload("mesh/SettlementsMesh.gd")
const RoadsMesh: GDScript = preload("mesh/RoadsMesh.gd")

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
	
	_data.settlement_layer = SettlementLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer, # _data.eroded_height_layer?
		terrain_config.settlement_spread,
	)
	_data.road_layer = RoadLayer.new(
		_data.grid_tri_cell_layer,
		_data.region_cell_layer,
		_data.lake_layer,
		_data.height_layer, # _data.eroded_height_layer?
		_data.river_layer,
		_data.settlement_layer,
		terrain_config.slope_penalty,
		terrain_config.river_penalty,
	)
	_meshes.settlements_mesh = SettlementsMesh.new(
		_data.grid_tri_cell_layer,
		_data.height_layer, # _data.eroded_height_layer?
		_data.settlement_layer,
		material_lib,
	)
	_meshes.roads_mesh = RoadsMesh.new(
		_data.grid_tri_cell_layer,
		_data.height_layer, # _data.eroded_height_layer?
		_data.road_layer,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.settlement_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_data.road_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_meshes.settlements_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_meshes.roads_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CIVIL

func _to_string() -> String:
	return "Civil Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"settlements": _meshes.settlements_mesh,
		"roads": _meshes.roads_mesh,
	}
