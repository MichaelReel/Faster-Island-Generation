class_name IslandOutlineLayer
extends Object

var _region_cell_layer: RegionCellLayer
var _region: Region
var _cell_limit: int
var _rng := RandomNumberGenerator.new()

func _init(region_cell_layer: RegionCellLayer, cell_limit: int, rng_seed: int) -> void:
	_region_cell_layer = region_cell_layer
	_region = Region.new(_region_cell_layer, _region_cell_layer.get_region_ref())

	_cell_limit = cell_limit
	_rng.seed = rng_seed

func perform() -> void:
	var start_triangle_index = _region_cell_layer.get_middle_triangle_index()
	_region.add_cell_index_to_front(start_triangle_index)
	_expand_region_up_to_cell_count()

func _expand_region_up_to_cell_count() -> void:
	var expansion_done := false
	while not expansion_done:
		var front_spent = expand_region_into_parent(_region, _rng)
		if front_spent or _region.get_cell_count() >= _cell_limit:
			expansion_done = true

func expand_region_into_parent(region: Region, rng: RandomNumberGenerator) -> bool:
	"""
	Extend by a cell into the parent medium
	Return true if there is no space left
	"""
	if region.front_empty():
		return true
	
	var random_front_cell = region.random_front_cell_index(rng)
	
	for neighbour_index in _region_cell_layer.get_edge_sharing_neighbours(random_front_cell):
		if _region_cell_layer.get_parent_reference_for_cell_index(neighbour_index) == _region_cell_layer.get_region_ref():
			region.add_cell_index_to_front(neighbour_index)
	
	region.add_cell_index_to_region(random_front_cell)
	return region.front_empty()

func get_region_ref() -> int:
	return _region.get_region_index()
