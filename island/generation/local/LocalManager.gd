extends Stage

const GridManager: GDScript = preload("../grid/GridManager.gd")
const RegionManager: GDScript = preload("../region/RegionManager.gd")
const LakeManager: GDScript = preload("../lakes/LakeManager.gd")
const HeightManager: GDScript = preload("../height/HeightManager.gd")
const RiverManager: GDScript = preload("../rivers/RiverManager.gd")
const CivilManager: GDScript = preload("../civil/CivilManager.gd")
const CliffManager: GDScript = preload("../cliffs/CliffManager.gd")
const BaseContinuityLayer: GDScript = preload("geometry/BaseContinuityLayer.gd")
const NoiseAddLayer: GDScript = preload("geometry/NoiseAddLayer.gd")
const NoiseDebugMesh: GDScript = preload("mesh/NoiseDebugMesh.gd")

var _grid_manager: GridManager
var _region_manager: RegionManager
var _lake_manager: LakeManager
var _height_manager: HeightManager
var _river_manager: RiverManager
var _civil_manager: CivilManager
var _cliff_manager: CliffManager
var _material_lib: MaterialLib
var _rng := RandomNumberGenerator.new()
var _base_continuity_layer: BaseContinuityLayer
var _noise_add_layer: NoiseAddLayer
var _noise_debug_mesh: NoiseDebugMesh

func _init(
	grid_manager: GridManager,
	region_manager: RegionManager,
	lake_manager: LakeManager,
	height_manager: HeightManager,
	river_manager: RiverManager,
	civil_manager: CivilManager,
	cliff_manager: CliffManager,
	tri_side: float,
	bounds_side: float,
	noise_height: float,
	upper_ground_cell_size: float,
	material_lib: MaterialLib,
	rng_seed: int,
) -> void:
	_grid_manager = grid_manager
	_region_manager = region_manager
	_lake_manager = lake_manager
	_height_manager = height_manager
	_river_manager = river_manager
	_civil_manager = civil_manager
	_cliff_manager = cliff_manager
	_material_lib = material_lib
	_rng.seed = rng_seed
	
	_base_continuity_layer = BaseContinuityLayer.new(
		_grid_manager.get_tri_cell_layer(),
		_cliff_manager.get_cliff_layer(),
	)
	_noise_add_layer = NoiseAddLayer.new(
		_base_continuity_layer,
		_rng.randi(),
		noise_height,
	)
	_noise_debug_mesh = NoiseDebugMesh.new(
		_grid_manager.get_point_layer(),
		_noise_add_layer,
		tri_side,
		bounds_side,
		upper_ground_cell_size,
		material_lib,
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_base_continuity_layer.perform()
	_noise_add_layer.perform()
	_noise_debug_mesh.perform()
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
