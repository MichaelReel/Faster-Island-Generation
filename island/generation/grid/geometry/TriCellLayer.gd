class_name TriCellLayer
extends Object

var _point_layer: PointLayer
var _tri_side: float
var _tri_height: float
var _tri_per_row: int
var _tri_rows: int
var _cells: Array[PackedInt32Array] = []
var _edge_neighbour_indices: Array[PackedInt32Array] = []  # Links to neighbour cells by index
var _corner_neighbours_indices: Array[PackedInt32Array] = []  # Links to touching cells by index
var _tris_using_point_by_index: Array[PackedInt32Array] = []  # Cells touching a given point

func _init(point_layer: PointLayer, tri_side: float) -> void:
	_point_layer = point_layer
	_tri_side = tri_side
	_tri_height = sqrt(0.75) * _tri_side

func perform() -> void:
	"""Reference the point indices and create triangles"""
	for point_index in range(_point_layer.get_total_point_count()):
		_tris_using_point_by_index.append(PackedInt32Array())
	
	_tri_per_row = (_point_layer.get_points_per_row() - 1) * 2
	_tri_rows = _point_layer.get_row_count() - 1
	
	for tri_row_ind in range(_tri_rows):
		for tri_col_ind in range(_tri_per_row):
			var new_triangle: PackedInt32Array = _create_tri_cell(Vector2i(tri_col_ind, tri_row_ind))
			_cells.append(new_triangle)
		
	for cell_ind in range(get_total_cell_count()):
		_edge_neighbour_indices.append(_get_edge_sharing_neighbours(cell_ind))
		_corner_neighbours_indices.append(_get_corner_only_sharing_neighbours(cell_ind))
		for point_index in _cells[cell_ind]:
			_tris_using_point_by_index[point_index].append(cell_ind)

func get_triangle_as_point_indices(triangle_index: int) -> PackedInt32Array:
	return _cells[triangle_index]

func get_triangles_using_point_by_index(point_index: int) -> PackedInt32Array:
	return _tris_using_point_by_index[point_index]

func get_triangles_as_vector3_arrays() -> Array:
	"""Return each triangle as an array of 3d vectors for surface creation"""
	var vec3_array: Array = _cells.map(_get_points_as_vector3_array_for_point_indices)
	return vec3_array

func get_triangle_as_vector3_array_for_index(triangle_index: int) -> PackedVector3Array:
	"""Return the points of triangle, by index, as an array of 3d vectors"""
	return _get_points_as_vector3_array_for_point_indices(
		get_triangle_as_point_indices(triangle_index)
	)

func get_point_as_vector3(point_index: int, height: float = 0) -> Vector3:
	var vec2d: Vector2 = _point_layer.get_point_for_index(point_index)
	return Vector3(vec2d.x, height, vec2d.y)

func get_tri_cell_index_for_vector2i(vector: Vector2i) -> int:
	return vector.x + (vector.y * _tri_per_row)

func get_tri_cell_vector2i_for_index(index: int) -> Vector2i:
	return Vector2i(index % _tri_per_row, index / _tri_per_row)

func get_connected_point_indices_by_point_index(point_index: int) -> PackedInt32Array:
	return _point_layer.get_connected_point_indices_by_point_index(point_index)

func get_total_point_count() -> int:
	return _point_layer.get_total_point_count()

func get_total_cell_count() -> int:
	return len(_cells)

func get_triangles_grid_dimensions() -> Vector2i:
	return Vector2i(_tri_per_row, _tri_rows)

func get_valid_adjacent_point_indices_from_list(point_indices: PackedInt32Array) -> Dictionary:
	# -> Dictionary[int, PackedInt32Array]
	return _point_layer.get_valid_adjacent_point_indices_from_list(point_indices)
	
func get_edge_sharing_neighbours(cell_ind: int) -> PackedInt32Array:
	return _edge_neighbour_indices[cell_ind]

func get_corner_only_sharing_neighbours(cell_ind: int) -> PackedInt32Array:
	return _corner_neighbours_indices[cell_ind]

func get_cell_index_at_xz_position(xz: Vector2) -> int:
	return get_tri_cell_index_for_vector2i(_get_cell_vector2i_surrounding_xz(xz))

func get_tri_cell_horizontal_border(vector: Vector2i) -> int:
	"""This indicates the side of the triangle which is a flat edge connection to another row
	
	Returns: -1 if the flat edge is "up" to a lower indexed row, or
			 +1 if "down" to a higher indexed row
	"""
	var row_even: bool = vector.y % 2 == 0
	var column_even: bool = vector.x % 2 == 0
	
	return -1 if row_even == column_even else +1

func get_rotation_direction_around_cell(point_ind_a: int, point_ind_b: int, cell_ind: int) -> int:
	"""
	Get the rotation of the points, in the given order, around the cell
	+1 and -1 for CW and ACW rotations respectively.
	0 for no rotation; I.e.: input error, etc.
	"""
	# This relies on the order of the cells on creation in _create_tri_cell
	var ordered_points_in_the_cell: PackedInt32Array = _cells[cell_ind]
	var index_a_in_order: int = ordered_points_in_the_cell.find(point_ind_a)
	if ordered_points_in_the_cell[(index_a_in_order + 1) % 3] == point_ind_b:
		return 1
	if ordered_points_in_the_cell[(index_a_in_order + 2) % 3] == point_ind_b:
		return -1
	return 0

func _get_points_as_vector3_array_for_point_indices(point_indices: PackedInt32Array) -> PackedVector3Array:
	"""Return an array from a list of point indices as an array of 3d vectors"""
	return PackedVector3Array(Array(point_indices).map(get_point_as_vector3))

func _get_cell_vector2i_surrounding_xz(xz: Vector2) -> Vector2i:
	var internal_xz = xz + _point_layer.get_mesh_center_xz()
	
	var row : int = int(floor(internal_xz.y / _tri_height))
	if row > 0 and row < _tri_rows:
		var even_row: bool = row % 2 == 0
		# col is trickier than row as it relies on both x and z
		var col := int(floor(internal_xz.x / (_tri_side * 0.5)))
		var even_raw_col: bool = col % 2 == 0
		# Get internal positions in row and raw_col
		var y_in_row: float = internal_xz.y - (row * _tri_height)
		var x_in_raw_col: float = internal_xz.x - (col * 0.5 * _tri_side)
		# Get scaled position of point in the row and raw_col
		var scaled_y: float = y_in_row / _tri_height
		var scaled_x: float = x_in_raw_col / (0.5 * _tri_side)
		# Modify col depending on polarity
		if even_row == even_raw_col:
			if scaled_y > scaled_x:
				col -= 1
		else:
			if scaled_y < (1.0 - scaled_x):
				col -= 1
		if col > 0 and col < _tri_per_row:
			return Vector2i(col, row)
	return Vector2i(-1,-1)

func _create_tri_cell(vector: Vector2i) -> PackedInt32Array:
	var row: int = vector.y
	var col: int = vector.x
	var row_even: bool = row % 2 == 0
	var column_even: bool = col % 2 == 0
	var points: PackedInt32Array = []
	if row_even:
		if column_even:
			points.append(_point_index(Vector2i(col/2, row)))
			points.append(_point_index(Vector2i((col/2)+1, row)))
			points.append(_point_index(Vector2i(col/2, row+1)))
		else:  # (col_odd)
			points.append(_point_index(Vector2i((col/2)+1, row)))
			points.append(_point_index(Vector2i((col/2)+1, row+1)))
			points.append(_point_index(Vector2i(col/2, row+1)))
	else:  # (row_odd)
		if column_even:
			points.append(_point_index(Vector2i(col/2, row)))
			points.append(_point_index(Vector2i((col/2)+1, row+1)))
			points.append(_point_index(Vector2i(col/2, row+1)))
		else:  # (col_odd)
			points.append(_point_index(Vector2i(col/2, row)))
			points.append(_point_index(Vector2i((col/2)+1, row)))
			points.append(_point_index(Vector2i((col/2)+1, row+1)))
	return points

func _point_index(vector: Vector2i) -> int:
	return _point_layer.get_point_index_for_vector2i(vector)

func _get_edge_sharing_neighbours(cell_ind: int) -> PackedInt32Array:
	"""
	Return the immediate, edge sharing, neighbours for a given cell
	as an array of indexes of tri_cells.
	
	The neighbours will be the previous and next cells on the same row
	and the adjacent cell on the above or below row, depending on the orientation of the triangle.
	"""
	var tri_cell_coords: Vector2i = get_tri_cell_vector2i_for_index(cell_ind)
	var tri_grid_dimensions: Vector2i = get_triangles_grid_dimensions()
	var neighbours: PackedInt32Array = []
	
	# Include cell to the left, if there is one
	if tri_cell_coords.x - 1 >= 0:
		neighbours.append(get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(-1, 0)))
	
	# Include cell to the right, if there is one
	if tri_cell_coords.x + 1 < tri_grid_dimensions.x:
		neighbours.append(get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(+1, 0)))
	
	# Include the cell in the adjacent row where the flat edge is, if the cell exists
	var inter_row_dir: int = get_tri_cell_horizontal_border(tri_cell_coords)
	if tri_cell_coords.y + inter_row_dir >= 0 and tri_cell_coords.y + inter_row_dir < tri_grid_dimensions.y:
		neighbours.append(get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(0, inter_row_dir)))
	
	return neighbours

func _get_corner_only_sharing_neighbours(cell_ind: int) -> PackedInt32Array:
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
	
	var tri_cell_coords: Vector2i = get_tri_cell_vector2i_for_index(cell_ind)
	var tri_grid_dimensions: Vector2i = get_triangles_grid_dimensions()
	var neighbours: PackedInt32Array = []
	
	# Include cell to the left, if there is one
	if tri_cell_coords.x - 2 >= 0:
		neighbours.append(get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(-2, 0)))
	
	# Include cell to the right, if there is one
	if tri_cell_coords.x + 2 < tri_grid_dimensions.x:
		neighbours.append(get_tri_cell_index_for_vector2i(tri_cell_coords + Vector2i(+2, 0)))
	
	# Cell direction is important, as this will determine which side has the 4 or the 3 triangles
	var four_cell_row_dir: int = get_tri_cell_horizontal_border(tri_cell_coords)
	var three_cell_row_dir: int = -four_cell_row_dir
	var four_cell_row: int = tri_cell_coords.y + four_cell_row_dir
	var three_cell_row: int = tri_cell_coords.y + three_cell_row_dir
	
	# Include the 4 cells in the adjacent row where the flat edge is, if the cells exists
	if four_cell_row >= 0 and four_cell_row < tri_grid_dimensions.y:
		for x in range(max(tri_cell_coords.x - 2, 0), min(tri_cell_coords.x + 3, tri_grid_dimensions.x)):
			if x == tri_cell_coords.x:
				# Skip the middle cell
				continue
			neighbours.append(get_tri_cell_index_for_vector2i(Vector2i(x, four_cell_row)))
	
	# Include the 3 cells in the adjacent row there the point id, if the cells exists
	if three_cell_row >= 0 and three_cell_row < tri_grid_dimensions.y:
		for x in range(max(tri_cell_coords.x - 1, 0), min(tri_cell_coords.x + 2, tri_grid_dimensions.x)):
			neighbours.append(get_tri_cell_index_for_vector2i(Vector2i(x, three_cell_row)))
	
	return neighbours
