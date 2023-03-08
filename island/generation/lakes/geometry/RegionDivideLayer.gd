class_name RegionDividelLayer
extends Object

var _outline_manager: OutlineManager
var _lake_regions: int
var _region_cell_layer: RegionCellLayer
var _region_indices: PackedInt64Array
var _rng := RandomNumberGenerator.new()

func _init(outline_manager: OutlineManager, lake_regions: int, rng_seed: int) -> void:
	_outline_manager = outline_manager
	_lake_regions = lake_regions
	_rng.seed = rng_seed
	_region_cell_layer = _outline_manager.get_region_cell_layer()

func perform() -> void:
	_setup_regions()
	
	var expansion_done := false
	while not expansion_done:
		var done = true
		for region_index in _region_indices:
			if not _region_cell_layer.expand_region_into_parent(region_index, _rng):
				done = false
		if done:
			expansion_done = true
	
	pass
	
#	_expand_margins()
	
#	for region in _regions:
#		var _lines: Array[Edge] = region.get_perimeter_lines(false)

#func _expand_margins() -> void:
#	for region in _regions:
#		region.expand_margins()

func _setup_regions() -> void:
	var parent_region_index = _outline_manager.get_island_region_index()
	var start_triangles = _region_cell_layer.get_some_triangles_in_region(_lake_regions, parent_region_index, _rng)
	
	for tri_index in start_triangles:
		var new_region = Region.new(_region_cell_layer, parent_region_index)
		new_region.add_cell_index_to_front(tri_index)
		_region_indices.append(new_region.get_region_index())

