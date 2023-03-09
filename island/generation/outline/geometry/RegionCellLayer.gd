class_name RegionCellLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _edge_neighbour_indices: Array[PackedInt64Array] = []  # Links to neighbour cells by index
var _corner_neighbours_indices: Array[PackedInt64Array] = []  # Links to touching cells by index
var _cell_parents: PackedInt64Array = []  # Link from a cell to it's parent reference index
var _root_region: Region
var _region_by_index: Array[Region] = []  # Link from region index to the Region
var _point_to_cells_map: Array[PackedInt64Array] = []

func _init(tri_cell_layer: TriCellLayer) -> void:
	_tri_cell_layer = tri_cell_layer
	_root_region = Region.new(self, 0)

func perform() -> void:
	for cell_ind in range(_tri_cell_layer.get_cell_count()):
		_edge_neighbour_indices.append(_get_edge_sharing_neighbours(cell_ind))
		_corner_neighbours_indices.append(_get_corner_only_sharing_neighbours(cell_ind))
		_cell_parents.append(_root_region.get_region_index())  # Default all cells to root region

	_map_point_indices_to_connected_cell_indices()

func get_region_ref() -> int:
	return _root_region.get_region_index()

func register_region(parent: Region) -> int:
	var index = len(_region_by_index)
	_region_by_index.append(parent)
	return index

func get_region_count() -> int:
	return len(_region_by_index)

func get_region_by_index(index: int) -> Region:
	return _region_by_index[index]

func get_index_by_region(parent: Region) -> int:
	return _region_by_index.find(parent)

func get_middle_triangle_index() -> int:
	return _tri_cell_layer.get_tri_cell_index_for_vector2i(
		_tri_cell_layer.get_triangles_grid_dimensions() / 2
	)

func get_region_by_index_for_cell_index(cell_index: int) -> int:
	return _cell_parents[cell_index]

func update_cell_to_region(cell_index: int, region_index: int) -> void:
	_cell_parents[cell_index] = region_index

func return_cell_to_parent_region(cell_index: int, parent_index: int) -> void:
	var region_index: int = get_region_by_index_for_cell_index(cell_index)
	var region: Region = get_region_by_index(region_index)
#	var parent_index = region.get_parent_index()
	update_cell_to_region(cell_index, parent_index)
	region.remove_cell_index_from_region(cell_index)

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
			if _cell_parents[tri_index] == region_ind:
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
	var region : Region = get_region_by_index(region_index)
	if region.front_empty():
		return true
	
	var random_front_cell_index = region.random_front_cell_index(rng)
	
	for neighbour_index in get_edge_sharing_neighbours(random_front_cell_index):
		if get_region_by_index_for_cell_index(neighbour_index) == region.get_parent_index():
			region.add_cell_index_to_front(neighbour_index)
	
	region.add_cell_index_to_region(random_front_cell_index)
	return region.front_empty()
