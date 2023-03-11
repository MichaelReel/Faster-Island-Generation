class_name LakeLayer
extends Object

var _outline_manager: OutlineManager
var _region_divide_layer: RegionDivideLayer
var _lakes_per_region: int
var _region_cell_layer: RegionCellLayer
var _lake_indices: PackedInt64Array
var _rng := RandomNumberGenerator.new()

func _init(outline_manager: OutlineManager, region_divide_layer: RegionDivideLayer, lakes_per_region: int, rng_seed: int) -> void:
	_outline_manager = outline_manager
	_region_divide_layer = region_divide_layer
	_lakes_per_region = lakes_per_region
	_rng.seed = rng_seed
	_region_cell_layer = _outline_manager.get_region_cell_layer()

func perform() -> void:
	_setup_lake_regions()
	
	var expansion_done := false
	while not expansion_done:
		var done = true
		for lake_index in _lake_indices:
			if not _region_cell_layer.expand_region_into_parent(lake_index, _rng):
				done = false
		if done:
			expansion_done = true

#	for lake_index in _lake_indices:
#		_region_divide_layer.reduce_region_and_create_margin(lake_index)
	
#	for region in _regions:
#		var _lines: Array[Edge] = region.get_perimeter_lines(false)

func get_lake_region_indices() -> PackedInt64Array:
	return _lake_indices

func _setup_lake_regions() -> void:
	var region_indices: PackedInt64Array = _region_divide_layer.get_region_indices()
	for region_index in region_indices:
		var start_triangles = _region_cell_layer.get_some_triangles_in_region(_lakes_per_region, region_index, _rng)
		
		for tri_index in start_triangles:
			var new_lake = Region.new(_region_cell_layer, region_index)
			_region_cell_layer.add_cell_to_subregion(tri_index, new_lake.get_region_index())
			_lake_indices.append(new_lake.get_region_index())
