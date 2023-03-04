class_name TriCellLayer
extends Object

var _point_layer: PointLayer
var _edge_layer: EdgeLayer
var _tri_per_row: int
var _tri_rows: int
var _cells: Array[PackedInt64Array] = []

func _init(point_layer: PointLayer, edge_layer: EdgeLayer) -> void:
	_point_layer = point_layer
	_edge_layer = edge_layer

func perform() -> void:
	"""Reference the point indices and create triangles"""
	_tri_per_row = (_point_layer.get_points_per_row() - 1) * 2
	_tri_rows = _point_layer.get_row_count() - 1
	
	for tri_row_ind in range(_tri_rows):
		for tri_col_ind in range(_tri_per_row):
			var new_triangle: PackedInt64Array = _create_tri_cell(Vector2i(tri_col_ind, tri_row_ind))
			_cells.append(new_triangle)

func get_triangles_as_vector3_arrays() -> Array:
	"""Return each triangle as an array of 3d vectors for surface creation"""
	var vec3_array: Array = _cells.map(get_points_as_vector3_array_for_point_indices)
	return vec3_array

func get_triangle_as_vector3_array_for_index(triangle_index: int) -> PackedVector3Array:
	"""Return the points of triangle, by index, as an array of 3d vectors"""
	return get_points_as_vector3_array_for_point_indices(_cells[triangle_index])

func get_points_as_vector3_array_for_point_indices(point_indices: PackedInt64Array) -> PackedVector3Array:
	"""Return an array from a list of point indices as an array of 3d vectors"""
	return PackedVector3Array(Array(point_indices).map(get_point_as_vector3))

func get_point_as_vector3(point_index: int, height: float = 0) -> Vector3:
	var vec2d: Vector2 = _point_layer.get_point_for_index(point_index)
	return Vector3(vec2d.x, height, vec2d.y)

func get_tri_cell_index_for_vector2i(vector: Vector2i) -> int:
	return vector.x + (vector.y * _tri_per_row)

func get_tri_cell_vector2i_for_index(index: int) -> Vector2i:
	return Vector2i(index % _tri_per_row, index / _tri_per_row)

func get_tri_cell_horizontal_border(vector: Vector2i) -> int:
	"""This indicates the side of the triangle which is a flat edge connection to another row
	
	Returns: -1 if the flat edge is "up" to a lower indexed row, or
			 +1 if "down" to a higher indexed row
	"""
	var row_even: bool = vector.y % 2 == 0
	var column_even: bool = vector.x % 2 == 0
	
	return -1 if row_even == column_even else +1

func _create_tri_cell(vector: Vector2i) -> PackedInt64Array:
	var row: int = vector.y
	var col: int = vector.x
	var row_even: bool = row % 2 == 0
	var column_even: bool = col % 2 == 0
	var points: PackedInt64Array = []
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

func get_cell_count() -> int:
	return len(_cells)

func get_triangles_grid_dimensions() -> Vector2i:
	return Vector2i(_tri_per_row, _tri_rows)
