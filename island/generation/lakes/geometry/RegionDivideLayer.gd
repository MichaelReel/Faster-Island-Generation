class_name RegionDivideLayer
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
	
	for region_index in _region_indices:
		reduce_region_and_create_margin(region_index)
	
#	for region in _regions:
#		var _lines: Array[Edge] = region.get_perimeter_lines(false)

func get_region_indices() -> PackedInt64Array:
	return _region_indices

func _setup_regions() -> void:
	var parent_region_index = _outline_manager.get_island_region_index()
	var start_triangles = _region_cell_layer.get_some_triangles_in_region(_lake_regions, parent_region_index, _rng)
	
	for tri_index in start_triangles:
		var new_region_index = _region_cell_layer.create_new_region(parent_region_index)
		_region_cell_layer.add_cell_to_subregion_front(tri_index, new_region_index)
		_region_indices.append(new_region_index)

func reduce_region_and_create_margin(region_index: int) -> void:
	var border_cell_indices: PackedInt64Array = _find_inner_border_cell_indices(region_index)
	
	# Return the border cells to the parent and mark as frontier
	for border_cell_index in border_cell_indices:
		_region_cell_layer.remove_cell_from_current_subregion(border_cell_index) # , _outline_manager.get_island_region_index())
	
	# Recreate the frontier for this region, subset of removed cells
	for border_cell_index in border_cell_indices:
		if count_neighbours_with_parent(border_cell_index, region_index) > 0:
			_region_cell_layer.add_cell_to_subregion_front(border_cell_index, region_index)

func _find_inner_border_cell_indices(region_index: int) -> PackedInt64Array:
	"""Find the indices of the cells on the edge, but inside the notional perimeter"""
	var border_cells: PackedInt64Array = []
	# Find cells on the boundaries of the region
	var region_cells_indices: PackedInt64Array = _region_cell_layer.get_region_cell_indices_by_region_index(region_index)
	for cell_index in region_cells_indices:
		if count_corner_neighbours_with_parent(cell_index, region_index) < 9:
			border_cells.append(cell_index)
	return border_cells

func get_indices_of_neighbours_with_parent(cell_index: int, parent_index: int) -> PackedInt64Array:
	var parented_neighbours: PackedInt64Array = []
	for neighbour_index in _region_cell_layer.get_edge_sharing_neighbours(cell_index):
		if _region_cell_layer.get_region_index_for_cell(neighbour_index) == parent_index:
			parented_neighbours.append(neighbour_index)
	return parented_neighbours

func count_neighbours_with_parent(cell_index: int, parent_index: int) -> int:
	return len(get_indices_of_neighbours_with_parent(cell_index, parent_index))

func get_indices_of_corner_neighbours_with_parent(cell_index:int, parent_index: int) -> PackedInt64Array:
	var parented_corner_neighbours: PackedInt64Array = []
	for corner_neighbour in _region_cell_layer.get_corner_only_sharing_neighbours(cell_index):
		if _region_cell_layer.get_region_index_for_cell(corner_neighbour) == parent_index:
			parented_corner_neighbours.append(corner_neighbour)
	return parented_corner_neighbours

func count_corner_neighbours_with_parent(cell_index: int, parent_index: int) -> int:
	return len(get_indices_of_corner_neighbours_with_parent(cell_index, parent_index))

func get_indices_of_edge_and_corner_neighbours_with_parent(cell_index: int, parent_index: int) -> PackedInt64Array:
	return get_indices_of_neighbours_with_parent(cell_index, parent_index) + get_indices_of_corner_neighbours_with_parent(cell_index, parent_index)
