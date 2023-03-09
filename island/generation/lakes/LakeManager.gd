class_name LakeManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _region_divide_layer: RegionDividelLayer
var _region_debug_mesh: RegionDebugMesh
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_regions: int, 
	_lakes_per_region: int,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_rng.seed = rng_seed
	
	_region_divide_layer = RegionDividelLayer.new(outline_manager, lake_regions, _rng.randi())
#	_lake_layer = null
	_region_debug_mesh = RegionDebugMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_outline_manager.get_region_cell_layer(),
		_outline_manager.get_island_region_index(),
		material_lib
	)


func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_region_divide_layer.perform()
	
	emit_signal("percent_complete", self, 66.6)
	_region_debug_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Lake Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _region_debug_mesh
	}
