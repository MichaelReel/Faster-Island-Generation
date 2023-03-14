class_name RegionCellLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _edge_neighbour_indices: Array[PackedInt64Array] = []  # Links to neighbour cells by index
var _corner_neighbours_indices: Array[PackedInt64Array] = []  # Links to touching cells by index
var _region_index_by_cell_index: PackedInt64Array = []  # Link from a cell to it's parent reference index
var _root_region: Region
var _region_by_index: Array[Region] = []  # Link from region index to the Region
var _region_fronts_by_cell_index: Array[PackedInt64Array] = []
var _point_to_cells_map: Array[PackedInt64Array] = []

func _init(tri_cell_layer: TriCellLayer) -> void:
	_tri_cell_layer = tri_cell_layer
	_root_region = Region.new(self, 0)

func perform() -> void:
	for cell_ind in range(_tri_cell_layer.get_cell_count()):
		_root_region._region_cells.append(cell_ind)
		_region_fronts_by_cell_index.append(PackedInt64Array())
		_edge_neighbour_indices.append(_get_edge_sharing_neighbours(cell_ind))
		_corner_neighbours_indices.append(_get_corner_only_sharing_neighbours(cell_ind))
		_region_index_by_cell_index.append(_root_region._region_index)  # Default all cells to root region

	_map_point_indices_to_connected_cell_indices()

func get_root_region_index() -> int:
	return _root_region._region_index

func register_region(parent: Region) -> int:
	var index = len(_region_by_index)
	_region_by_index.append(parent)
	return index

func get_region_count() -> int:
	return len(_region_by_index)

func get_region_by_index(index: int) -> Region:
	return _region_by_index[index]

func get_index_by_region(region: Region) -> int:
	return _region_by_index.find(region)

func get_parent_index_by_region_index(region_index: int) -> int:
	return _region_by_index[region_index]._parent_index

func get_middle_triangle_index() -> int:
	return _tri_cell_layer.get_tri_cell_index_for_vector2i(
		_tri_cell_layer.get_triangles_grid_dimensions() / 2
	)

func get_region_by_index_for_cell_index(cell_index: int) -> int:
	return _region_index_by_cell_index[cell_index]

func get_front_cell_indices(region_index: int) -> PackedInt64Array:
	return _region_by_index[region_index]._region_front

func get_region_fronts_by_cell_index(cell_index: int) -> PackedInt64Array: 
	return _region_fronts_by_cell_index[cell_index]

func get_cell_count() -> int:
	return _tri_cell_layer.get_cell_count()

func add_cell_to_subregion_front(cell_index: int, sub_region_index: int) -> void:
	var region = _region_by_index[sub_region_index]
	if region._parent_index != get_region_by_index_for_cell_index(cell_index):
		printerr("Attempt to add cell to front when cell is not in parent region of target region")
	
	# Ignore attempts to re-add cells to the same front
	if cell_index in region._region_front:
		return
	
	# If cell is already in region, chuck an error, move back to front should be separate
	if cell_index in region._region_cells:
		printerr("Attempt to add cell to front when cell is already in target region")

	region._region_front.append(cell_index)
	_region_fronts_by_cell_index[cell_index].append(sub_region_index)

func remove_cell_from_subregion_front(cell_index: int, fronting_region_index: int) -> void:
	var fronting_region = _region_by_index[fronting_region_index]
	if cell_index in fronting_region._region_front:
		fronting_region._region_front.remove_at(fronting_region._region_front.find(cell_index))
	var ind_in_fronts_by_cell: int = _region_fronts_by_cell_index[cell_index].find(fronting_region_index)
	_region_fronts_by_cell_index[cell_index].remove_at(ind_in_fronts_by_cell)

func add_cell_to_subregion(cell_index: int, sub_region_index: int) -> void:
	var sub_region: Region = _region_by_index[sub_region_index]
	if sub_region._parent_index != get_region_by_index_for_cell_index(cell_index):
		printerr("Attempt to add cell when cell is not in parent region of target region")
	
	if cell_index in sub_region._region_cells:
		printerr("Attempt to add cell when cell is already in target region")
		return
	
	# remove from any region fronts this cell in
	for fronting_region_index in _region_fronts_by_cell_index[cell_index]:
		var fronting_region = _region_by_index[fronting_region_index]
		if cell_index in fronting_region._region_front:
			fronting_region._region_front.remove_at(fronting_region._region_front.find(cell_index))
	_region_fronts_by_cell_index[cell_index].clear()
	
	# Add to subregion and set the mapping
	sub_region._region_cells.append(cell_index)
	_region_index_by_cell_index[cell_index] = sub_region._region_index
	
	# Remove from parent
	var parent_region: Region = _region_by_index[sub_region._parent_index]
	var index_in_parent = parent_region._region_cells.find(cell_index)
	parent_region._region_cells.remove_at(index_in_parent)

func remove_cell_from_current_subregion(cell_index: int) -> void:
	"""Cell should return to the parent region"""
	var sub_region = _region_by_index[get_region_by_index_for_cell_index(cell_index)]
	var cell_pos_in_cells: int = sub_region._region_cells.find(cell_index)
	if cell_pos_in_cells >= 0:
		sub_region._region_cells.remove_at(cell_pos_in_cells)
		_region_index_by_cell_index[cell_index] = sub_region._parent_index
	else:
		printerr("Attempt to remove cell %d not in region %d" % [cell_index, sub_region._region_index])

func get_some_triangles_in_region(count: int, region_index: int, rng: RandomNumberGenerator) -> PackedInt64Array:
	"""Get upto count random cells from the region referenced by region_index"""
	var region : Region = get_region_by_index(region_index)
	
	var actual_count : int = min(count, region.get_cell_count())
	var random_cells: PackedInt64Array = region.get_cell_indices().duplicate()
	ArrayUtils.shuffle_int64(rng, random_cells)
	return random_cells.slice(0, actual_count)

func random_front_cell_index(region_index: int, rng: RandomNumberGenerator) -> int:
	var region: Region = _region_by_index[region_index]
	var random_pos_in_front: int = rng.randi_range(0, len(region._region_front) - 1)
	var random_cell_index: int = region._region_front[random_pos_in_front]
	
	# Some debug, warn if this cell doesn't have the correct parent region
	if _region_index_by_cell_index[random_cell_index] != region._parent_index:
		printerr("Random front cell is not in parent region")
	
	return random_cell_index

func get_edge_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	return _edge_neighbour_indices[cell_ind]

func _get_edge_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	"""
	Return the immediate, edge sharing, neighbours for a given cell
	as an array of indexes of tri_cells.
	
	The neighbours will be the previous and next cells on the same row
	and the adjacent cell on the above or below row, depending on the orientation of the triangle.
	"""
	var tri_cell_coords: Vector2i = _tri_cell_layer.get_tri_cell_vector2i_for_index(cell_ind)
	var tri_grid_dimensions: Vector2i = _tri_cell_layer.get_triangles_grid_dimensions()
	var neighbours: PackedInt64Array = []
	
	# Include cell to the left, if there is one
	if tri_cell_coords.x - 1 >= 0:
		neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(-1, 0)))
	
	# Include cell to the right, if there is one
	if tri_cell_coords.x + 1 < tri_grid_dimensions.x:
		neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(+1, 0)))
	
	# Include the cell in the adjacent row where the flat edge is, if the cell exists
	var inter_row_dir: int = _tri_cell_layer.get_tri_cell_horizontal_border(tri_cell_coords)
	if tri_cell_coords.y + inter_row_dir >= 0 and tri_cell_coords.y + inter_row_dir < tri_grid_dimensions.y:
		neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(0, inter_row_dir)))
	
	return neighbours

func get_corner_only_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	return _corner_neighbours_indices[cell_ind]

func _get_corner_only_sharing_neighbours(cell_ind: int) -> PackedInt64Array:
	"""
	Return the just-touching, corner sharing, neighbours for a given cell
	as an array of indexes of tri_cells.
	
	This is the 9 cells, if they are on the grid, that are not edge neighbours
	but share a point with the input cell.
	"""
	
	# Up pointing triangles:           Down pointing triangles:
	#        _\/____\/_                    _\/____  ____\/_         
	#         /\    /\                      /\    /\    /\          
	#        /  \  /  \                    /  \  /  \  /  \         
	#       /____\/____\                _\/____\/....\/____\/_      
	#      /\    ..    /\                /\    /.    .\    /\       
	#     /  \  .  .  /  \                 \  /  .  .  \  /         
	#  _\/____\....../____\/_               \/____..____\/          
	#   /\    /\    /\    /\                 \    /\    /           
	#     \  /  \  /  \  /                    \  /  \  /            
	#     _\/____\/____\/_                    _\/____\/_            
	#      /\          /\                      /\    /\             
	
	var tri_cell_coords: Vector2i = _tri_cell_layer.get_tri_cell_vector2i_for_index(cell_ind)
	var tri_grid_dimensions: Vector2i = _tri_cell_layer.get_triangles_grid_dimensions()
	var neighbours: PackedInt64Array = []
	
	# Include cell to the left, if there is one
	if tri_cell_coords.x - 2 >= 0:
		neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(-2, 0)))
	
	# Include cell to the right, if there is one
	if tri_cell_coords.x + 2 < tri_grid_dimensions.x:
		neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(+2, 0)))
	
	# Cell direction is important, as this will determine which side has the 4 or the 3 triangles
	var four_cell_row_dir: int = _tri_cell_layer.get_tri_cell_horizontal_border(tri_cell_coords)
	var three_cell_row_dir: int = -four_cell_row_dir
	var four_cell_row: int = tri_cell_coords.y + four_cell_row_dir
	var three_cell_row: int = tri_cell_coords.y + three_cell_row_dir
	
	# Include the 4 cells in the adjacent row where the flat edge is, if the cells exists
	if four_cell_row >= 0 and four_cell_row < tri_grid_dimensions.y:
		for x in range(max(tri_cell_coords.x - 2, 0), min(tri_cell_coords.x + 3, tri_grid_dimensions.x)):
			if x == tri_cell_coords.x:
				# Skip the middle cell
				continue
			neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(Vector2i(x, four_cell_row)))
	
	# Include the 3 cells in the adjacent row there the point id, if the cells exists
	if three_cell_row >= 0 and three_cell_row < tri_grid_dimensions.y:
		for x in range(max(tri_cell_coords.x - 1, 0), min(tri_cell_coords.x + 2, tri_grid_dimensions.x)):
			neighbours.append(_tri_cell_layer.get_tri_cell_index_for_vector2i(Vector2i(x, three_cell_row)))
	
	return neighbours

func _map_point_indices_to_connected_cell_indices() -> void:
	var total_points = _tri_cell_layer.get_point_count()
	for point_index in range(total_points):
		_point_to_cells_map.append(PackedInt64Array())
	
	for cell_ind in range(_tri_cell_layer.get_cell_count()):
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
	var parent_index: int = region._parent_index
	if region._region_front.is_empty():
		return true
	
	var random_cell_index = random_front_cell_index(region_index, rng)
	
	for neighbour_index in get_edge_sharing_neighbours(random_cell_index):
		if get_region_by_index_for_cell_index(neighbour_index) == parent_index:
			add_cell_to_subregion_front(neighbour_index, region_index)
	
	add_cell_to_subregion(random_cell_index, region_index)
	return region._region_front.is_empty()
