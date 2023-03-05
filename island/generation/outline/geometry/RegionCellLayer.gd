class_name RegionCellLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _edge_neighbour_indices: Array[PackedInt64Array] = []  # Links to neighbour cells by index
var _cell_parents: PackedInt64Array = []  # Link from a cell to it's parent reference index
var _root_region: Region
var _parent_reference: Array[Region] = []  # Link from parent reference to the parent Region
var _point_to_cells_map: Array[PackedInt64Array] = []

func _init(tri_cell_layer: TriCellLayer) -> void:
	_tri_cell_layer = tri_cell_layer
	_root_region = Region.new(self, 0)

func perform() -> void:
	for cell_ind in range(_tri_cell_layer.get_cell_count()):
		_edge_neighbour_indices.append(_get_edge_sharing_neighbours(cell_ind))
		_cell_parents.append(_root_region.get_region_index())  # Default all cells to root region
	
	_map_point_indices_to_connected_cell_indices()

func get_region_ref() -> int:
	return _root_region.get_region_index()

func register_region(parent: Region) -> int:
	var index = len(_parent_reference)
	_parent_reference.append(parent)
	return index

func get_region_count() -> int:
	return len(_parent_reference)

func get_parent_by_reference(index: int) -> Region:
	return _parent_reference[index]

func get_reference_by_parent(parent: Region) -> int:
	return _parent_reference.find(parent)

func get_middle_triangle_index() -> int:
	return _tri_cell_layer.get_tri_cell_index_for_vector2i(
		_tri_cell_layer.get_triangles_grid_dimensions() / 2
	)

func get_parent_reference_for_cell_index(cell_index: int) -> int:
	return _cell_parents[cell_index]

func update_cell_to_region(cell_index: int, region_index: int) -> void:
	_cell_parents[cell_index] = region_index

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
