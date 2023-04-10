class_name CivilManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _settlement_layer: SettlementLayer
var _road_layer: RoadLayer
var _settlements_mesh: SettlementsMesh
var _roads_mesh: RoadsMesh
var _debug_road_mesh: DebugRoadMesh

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
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
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_manager = river_manager
	_material_lib = material_lib
	_rng.seed = rng_seed
	
	_settlement_layer = SettlementLayer.new(
		_lake_manager.get_lake_layer(),
		_outline_manager.get_region_cell_layer(),
		_height_manager.get_height_layer(),
		settlement_spread,
	)
	
	_road_layer = RoadLayer.new(
		_lake_manager.get_lake_layer(),
		_outline_manager.get_region_cell_layer(),
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
	
	_debug_road_mesh = DebugRoadMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_height_manager.get_height_layer(),
		_road_layer,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_settlement_layer.perform()
	emit_signal("percent_complete", self, 20.0)
	_road_layer.perform()
	emit_signal("percent_complete", self, 40.0)
	_settlements_mesh.perform()
	emit_signal("percent_complete", self, 60.0)
	_roads_mesh.perform()
	emit_signal("percent_complete", self, 80.0)
	_debug_road_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.CIVIL

func _to_string() -> String:
	return "Civil Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"settlements": _settlements_mesh,
		"roads": _roads_mesh,
		"debug": _debug_road_mesh,
	}

func get_settlement_layer() -> SettlementLayer:
	return _settlement_layer

func get_road_layer() -> RoadLayer:
	return _road_layer
