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

func get_region_ref() -> int:
	return _region.get_region_index()

func _expand_region_up_to_cell_count() -> void:
	var expansion_done := false
	while not expansion_done:
		var front_spent = _region_cell_layer.expand_region_into_parent(get_region_ref(), _rng)
		if front_spent or _region.get_cell_count() >= _cell_limit:
			expansion_done = true
	
	perform_expansion_smoothing()

func perform_expansion_smoothing() -> void:
	"""
	Triangles on the frontier should be incorporated anytime they are
	surrounded on three corners by this region
	"""
	# For each frontier triangle, check if it is "surrounded"
	var still_smoothing: bool = true
	while still_smoothing:
		still_smoothing = false
		for front_cell_ind in _region.front_cell_indices():
			if _region.surrounding_cell_with_index(front_cell_ind):
				# Ensure the front is updated
				for neighbour_index in _region_cell_layer.get_edge_sharing_neighbours(front_cell_ind):
					if _region_cell_layer.get_region_by_index_for_cell_index(neighbour_index) == _region_cell_layer.get_region_ref():
						_region.add_cell_index_to_front(neighbour_index)
				# Move front cell to the region and mark for another pass
				_region.add_cell_index_to_region(front_cell_ind)
				still_smoothing = true
