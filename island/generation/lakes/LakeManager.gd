class_name LakeManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _region_divide_layer: RegionDividelLayer
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_regions: int, 
	lakes_per_region: int,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_rng.seed = rng_seed
	
	_region_divide_layer = RegionDividelLayer.new(outline_manager, lake_regions, _rng.randi())
#	_lake_layer = null


func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_region_divide_layer.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Lake Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"lakes": null
	}
