class_name RegionCellLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _region_index_by_cell_index: PackedInt64Array = []  # Link from a cell to it's parent reference index
var _root_region_index: int
var _region_by_index: Array[Region] = []  # Link from region index to the Region
var _region_fronts_by_cell_index: Array[PackedInt64Array] = []
var _point_to_cells_map: Array[PackedInt64Array] = []

func _init(tri_cell_layer: TriCellLayer) -> void:
	_tri_cell_layer = tri_cell_layer
	_root_region_index = create_new_region()

func perform() -> void:
	for cell_ind in range(_tri_cell_layer.get_total_cell_count()):
		_region_by_index[_root_region_index].region_cells.append(cell_ind)
		_region_fronts_by_cell_index.append(PackedInt64Array())
		_region_index_by_cell_index.append(_root_region_index)  # Default all cells to root region

	_map_point_indices_to_connected_cell_indices()

func get_root_region_index() -> int:
	return _region_by_index[_root_region_index].region_index

func create_new_region(parent_region_index: int = 0) -> int:
	"""Creates a new region in the Region Cell Layer and returns the index for the new region"""
	var new_region = Region.new()
	new_region.region_index = len(_region_by_index)
	new_region.parent_index = parent_region_index
	_region_by_index.append(new_region)
	return new_region.region_index

func get_region_count() -> int:
	return len(_region_by_index)

func get_region_by_index(index: int) -> Region:
	return _region_by_index[index]

func get_index_by_region(region: Region) -> int:
	return _region_by_index.find(region)

func get_parent_index_by_region_index(region_index: int) -> int:
	return _region_by_index[region_index].parent_index

func get_middle_triangle_index() -> int:
	return _tri_cell_layer.get_tri_cell_index_for_vector2i(
		_tri_cell_layer.get_triangles_grid_dimensions() / 2
	)

func get_region_index_for_cell(cell_index: int) -> int:
	return _region_index_by_cell_index[cell_index]

func get_front_cell_indices(region_index: int) -> PackedInt64Array:
	return _region_by_index[region_index].region_front

func get_region_fronts_by_cell_index(cell_index: int) -> PackedInt64Array: 
	return _region_fronts_by_cell_index[cell_index]

func get_cell_count_by_region_index(region_index: int) -> int:
	return len(_region_by_index[region_index].region_cells)

func get_region_front_point_indices_by_front_cell_index(region_index: int, front_cell_index: int) -> PackedInt64Array:
	var front_point_indices: PackedInt64Array = []
	for point_index in _tri_cell_layer.get_triangle_as_point_indices(front_cell_index):
		for cell_index in _point_to_cells_map[point_index]:
			if _region_index_by_cell_index[cell_index] == region_index and not point_index in front_point_indices:
				front_point_indices.append(point_index)
	return front_point_indices

func add_cell_to_subregion_front(cell_index: int, sub_region_index: int) -> void:
	var region = _region_by_index[sub_region_index]
	if region.parent_index != get_region_index_for_cell(cell_index):
		printerr("Attempt to add cell to front when cell is not in parent region of target region")
	
	# Ignore attempts to re-add cells to the same front
	if cell_index in region.region_front:
		return
	
	# If cell is already in region, chuck an error, move back to front should be separate
	if cell_index in region.region_cells:
		printerr("Attempt to add cell to front when cell is already in target region")

	region.region_front.append(cell_index)
	_region_fronts_by_cell_index[cell_index].append(sub_region_index)

func remove_cell_from_subregion_front(cell_index: int, fronting_region_index: int) -> void:
	var fronting_region = _region_by_index[fronting_region_index]
	if cell_index in fronting_region.region_front:
		fronting_region.region_front.remove_at(fronting_region.region_front.find(cell_index))
	var ind_in_fronts_by_cell: int = _region_fronts_by_cell_index[cell_index].find(fronting_region_index)
	_region_fronts_by_cell_index[cell_index].remove_at(ind_in_fronts_by_cell)

func add_cell_to_subregion(cell_index: int, sub_region_index: int) -> void:
	var sub_region: Region = _region_by_index[sub_region_index]
	if sub_region.parent_index != get_region_index_for_cell(cell_index):
		printerr("Attempt to add cell when cell is not in parent region of target region")
	
	if cell_index in sub_region.region_cells:
		printerr("Attempt to add cell when cell is already in target region")
		return
	
	# remove from any region fronts this cell in
	for fronting_region_index in _region_fronts_by_cell_index[cell_index]:
		var fronting_region = _region_by_index[fronting_region_index]
		if cell_index in fronting_region.region_front:
			fronting_region.region_front.remove_at(fronting_region.region_front.find(cell_index))
	_region_fronts_by_cell_index[cell_index].clear()
	
	# Add to subregion and set the mapping
	sub_region.region_cells.append(cell_index)
	_region_index_by_cell_index[cell_index] = sub_region.region_index
	
	# Remove from parent
	var parent_region: Region = _region_by_index[sub_region.parent_index]
	var index_in_parent = parent_region.region_cells.find(cell_index)
	parent_region.region_cells.remove_at(index_in_parent)

func remove_cell_from_current_subregion(cell_index: int) -> void:
	"""Cell should return to the parent region"""
	var sub_region = _region_by_index[get_region_index_for_cell(cell_index)]
	var cell_pos_in_cells: int = sub_region.region_cells.find(cell_index)
	if cell_pos_in_cells >= 0:
		sub_region.region_cells.remove_at(cell_pos_in_cells)
		_region_index_by_cell_index[cell_index] = sub_region.parent_index
	else:
		printerr("Attempt to remove cell %d not in region %d" % [cell_index, sub_region.region_index])

func get_some_triangles_in_region(count: int, region_index: int, rng: RandomNumberGenerator) -> PackedInt64Array:
	"""Get upto count random cells from the region referenced by region_index"""
	var region : Region = get_region_by_index(region_index)
	
	var actual_count : int = min(count, len(region.region_cells))
	var random_cells: PackedInt64Array = region.region_cells.duplicate()
	ArrayUtils.shuffle_int64(rng, random_cells)
	return random_cells.slice(0, actual_count)

func get_region_cell_indices_by_region_index(region_index: int) -> PackedInt64Array:
	return _region_by_index[region_index].region_cells

func random_front_cell_index(region_index: int, rng: RandomNumberGenerator) -> int:
	var region: Region = _region_by_index[region_index]
	var random_pos_in_front: int = rng.randi_range(0, len(region.region_front) - 1)
	var random_cell_index: int = region.region_front[random_pos_in_front]
	
	# Some debug, warn if this cell doesn't have the correct parent region
	if _region_index_by_cell_index[random_cell_index] != region.parent_index:
		printerr("Random front cell is not in parent region")
	
	return random_cell_index

# TODO: Remove pass-through functions and just return the underlying TriCellLayer

func get_total_cell_count() -> int:
	return _tri_cell_layer.get_total_cell_count()

func get_connected_point_indices_by_point_index(point_index: int) -> PackedInt64Array:
	return _tri_cell_layer.get_connected_point_indices_by_point_index(point_index)

func get_edge_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	return _tri_cell_layer.get_edge_sharing_neighbours(cell_ind)

func get_corner_only_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	return _tri_cell_layer.get_corner_only_sharing_neighbours(cell_ind)

func get_triangle_as_point_indices(cell_ind: int) -> PackedInt64Array:
	return _tri_cell_layer.get_triangle_as_point_indices(cell_ind)

func get_total_point_count() -> int:
	return _tri_cell_layer.get_total_point_count()

func get_point_as_vector3(point_index: int, height: float = 0) -> Vector3:
	return _tri_cell_layer.get_point_as_vector3(point_index, height)

func get_triangles_using_point_by_index(point_index: int) -> PackedInt64Array:
	return _tri_cell_layer.get_triangles_using_point_by_index(point_index)

func point_has_any_cell_with_parent(point_index: int, region_index: int) -> bool:
	for tri_index in _point_to_cells_map[point_index]:
		if _region_index_by_cell_index[tri_index] == region_index:
			return true
	return false

func point_has_any_cell_with_parent_in_list_get_region_index(point_index: int, region_indices: PackedInt64Array) -> int:
	"""Return the first region index found in the list that this point has a cell in"""
	for tri_index in _point_to_cells_map[point_index]:
		if _region_index_by_cell_index[tri_index] in region_indices:
			return _region_index_by_cell_index[tri_index]
	return -1

func _map_point_indices_to_connected_cell_indices() -> void:
	var total_points = _tri_cell_layer.get_total_point_count()
	for point_index in range(total_points):
		_point_to_cells_map.append(PackedInt64Array())
	
	for cell_ind in range(_tri_cell_layer.get_total_cell_count()):
		for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_ind):
			if not cell_ind in _point_to_cells_map[point_index]:
				_point_to_cells_map[point_index].append(cell_ind)

func region_surrounds_cell(region_ind: int, cell_ind: int) -> bool:
	for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_ind):
		var point_has_tri_in_region = false
		for tri_index in _point_to_cells_map[point_index]:
			if tri_index == cell_ind:
				continue
			if _region_index_by_cell_index[tri_index] == region_ind:
				point_has_tri_in_region = true
				break
		if not point_has_tri_in_region:
			# Not surrounded as one point is entirely outside the region
			return false
	# Not points found outside region
	return true

func expand_region_into_parent(region_index: int, rng: RandomNumberGenerator) -> bool:
	"""
	Extend by a cell into the parent medium
	Return true if there is no space left
	"""
	var region: Region = _region_by_index[region_index]
	var parent_index: int = region.parent_index
	if region.region_front.is_empty():
		return true
	
	var random_cell_index = random_front_cell_index(region_index, rng)
	
	for neighbour_index in get_edge_sharing_neighbours(random_cell_index):
		if get_region_index_for_cell(neighbour_index) == parent_index:
			add_cell_to_subregion_front(neighbour_index, region_index)
	
	add_cell_to_subregion(random_cell_index, region_index)
	return region.region_front.is_empty()

func identify_perimeter_points_for_region(region_index: int) -> void:
	var region: Region = get_region_by_index(region_index)
	var region_point_indices : PackedInt64Array = _get_point_indices_in_region(region_index)
	for point_index in region_point_indices:
		if point_has_any_cell_with_parent(point_index, region.parent_index):
			region.outer_perimeter_point_indices.append(point_index)
	
	for outer_point_index in region.outer_perimeter_point_indices:
		for point_index in get_connected_point_indices_by_point_index(outer_point_index):
			if (
				not point_index in region.outer_perimeter_point_indices 
				and point_index in region_point_indices
				and not point_index in region.inner_perimeter_point_indices
			):
				region.inner_perimeter_point_indices.append(point_index)

func get_outer_perimeter_point_indices(region_index: int) -> PackedInt64Array:
	var region: Region = get_region_by_index(region_index)
	return region.outer_perimeter_point_indices # _perimeter_points

func get_inner_perimeter_point_indices(region_index: int) -> PackedInt64Array:
	var region: Region = get_region_by_index(region_index)
	return region.inner_perimeter_point_indices # _inner_perimeter

func _get_point_indices_in_region(region_index: int) -> PackedInt64Array:
	"""Get all the point indices within the region"""
	var region: Region = get_region_by_index(region_index)
	if not region.point_indices_calculated:
		for cell_index in region.region_cells:
			for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_index):
				if not point_index in region.point_indices_in_region:
					region.point_indices_in_region.append(point_index)
		region.point_indices_calculated = true
	return region.point_indices_in_region

func get_valid_adjacent_point_indices_from_list(point_indices: PackedInt64Array) -> Dictionary:
	# -> Dictionary[int, PackedInt64Array]
	return _tri_cell_layer.get_valid_adjacent_point_indices_from_list(point_indices)

func get_all_point_indices_for_region_indices_in_list(region_indices: PackedInt64Array) -> PackedInt64Array:
	var total_point_indices: PackedInt64Array = []
	for region_index in region_indices:
		total_point_indices.append_array(_get_point_indices_in_region(region_index))
	return total_point_indices

func get_all_point_indices_not_in_point_index_list(other_point_indices: PackedInt64Array) -> PackedInt64Array:
	return PackedInt64Array(
		range(_tri_cell_layer.get_total_point_count()).filter(
			func(point_index: int): return not point_index in other_point_indices
		)
	)
