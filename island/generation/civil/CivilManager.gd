extends Stage

const GridManager: GDScript = preload("../grid/GridManager.gd")
const RegionManager: GDScript = preload("../region/RegionManager.gd")
const LakeManager: GDScript = preload("../lakes/LakeManager.gd")
const HeightManager: GDScript = preload("../height/HeightManager.gd")
const RiverManager: GDScript = preload("../rivers/RiverManager.gd")
const SettlementLayer: GDScript = preload("geometry/SettlementLayer.gd")
const RoadLayer: GDScript = preload("geometry/RoadLayer.gd")
const SettlementsMesh: GDScript = preload("mesh/SettlementsMesh.gd")
const RoadsMesh: GDScript = preload("mesh/RoadsMesh.gd")

var _grid_manager: GridManager
var _region_manager: RegionManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _settlement_layer: SettlementLayer
var _road_layer: RoadLayer
var _settlements_mesh: SettlementsMesh
var _roads_mesh: RoadsMesh

func _init(
	grid_manager: GridManager,
	region_manager: RegionManager,
	lake_manager: LakeManager,
	height_manager: HeightManager,
	river_manager: RiverManager,
	settlement_spread: int,
	slope_penalty: float,
	river_penalty: float,
	material_lib: MaterialLib,
	rng_seed: int,
) -> void:
	_grid_manager = grid_manager
	_region_manager = region_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_manager = river_manager
	_material_lib = material_lib
	_rng.seed = rng_seed
	
	_settlement_layer = SettlementLayer.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_height_manager.get_height_layer(),
		settlement_spread,
	)
	
	_road_layer = RoadLayer.new(
		_grid_manager.get_tri_cell_layer(),
		_region_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_height_manager.get_height_layer(),
		_river_manager.get_river_layer(),
		_settlement_layer,
		slope_penalty,
		river_penalty,
	)
	
	_settlements_mesh = SettlementsMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_height_manager.get_height_layer(),
		_settlement_layer,
		material_lib,
	)
	
	_roads_mesh = RoadsMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_height_manager.get_height_layer(),
		_road_layer,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_settlement_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_road_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_settlements_mesh.perform()
	emit_signal("percent_complete", self, 75.0)
	_roads_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CIVIL

func _to_string() -> String:
	return "Civil Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"settlements": _settlements_mesh,
		"roads": _roads_mesh,
	}

func get_settlement_layer() -> SettlementLayer:
	return _settlement_layer

func get_road_layer() -> RoadLayer:
	return _road_layer
