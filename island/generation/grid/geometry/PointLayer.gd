class_name PointLayer
extends Object

var _tri_side: float
var _tri_height: float
var _points_per_row: int
var _point_rows: int
var _mesh_center: Vector2
var _grid_points: PackedVector2Array = []
var _connected_point_indices_by_point_index: Array[PackedInt64Array] = []

func _init(tri_side: float, points_per_row: int) -> void:
	"""
	Initialize this set of grid points
	
	tri_side: The distance between any 2 adjacent points
	points_per_row: The number of points across the x-axis aligned row
	"""
	_tri_side = tri_side
	_tri_height = sqrt(0.75) * _tri_side
	_points_per_row = points_per_row
	var row_width: float = (_points_per_row + 0.5) * _tri_side
	_point_rows = int(row_width / _tri_height)
	var half_full_width: float = _tri_side * (_points_per_row - 0.5) * 0.5
	var half_full_height: float = _tri_height * (_point_rows - 1) * 0.5
	_mesh_center = Vector2(half_full_width, half_full_height)

func perform() -> void:
	"""Lay out points for the grid"""
	for row_ind in range(_point_rows):
		var point_row: PackedVector2Array = []
		var offset: float = (row_ind % 2) * (_tri_side / 2.0)
		var z: float = _tri_height * row_ind
		for col_ind in range(_points_per_row):
			var x: float = offset + (_tri_side * col_ind)
			var new_point := Vector2(x - _mesh_center.x, z - _mesh_center.y)
			point_row.append(new_point)
		_grid_points.append_array(point_row)
	
	for point_index in range(len(_grid_points)):
		_connected_point_indices_by_point_index.append(_get_connected_point_indices_by_point_index(point_index))

func get_connected_point_indices_by_point_index(point_index: int) -> PackedInt64Array:
	return _connected_point_indices_by_point_index[point_index]

func _get_connected_point_indices_by_point_index(point_index: int) -> PackedInt64Array:
	"""
	There are up to six connected points, left, right, 2 above and 2 below
	Depending on the row the point is on, the positions of the connected points can be calculated
	"""
	# row  |
	#  0   | 0_____1_____2_____3_____4
	#      |  \    /\    /\    /\    /
	#      |   \  /  \  /  \  /  \  /
	#  1   |   0\/___1\/___2\/___3\/     Where (x) is odd, the connected (y+/-1) are: (x) and (x+1)
	#      |    /\    /\    /\    /\
	#      |   /  \  /  \  /  \  /  \
	#  2   | 0/___1\/___2\/___3\/___4\   Where (x) is even, the connected (y+/-1) are: (x-1) and (x)
	#      |  \    /\    /\    /\    /
	#      |   \  /  \  /  \  /  \  /
	#  3   |   0\/___1\/___2\/___3\/
	
	var point_coords: Vector2i = get_vector2i_for_point_index(point_index)
	var point_grid_dimensions: Vector2i = get_point_grid_dimensions()
	var neighbours: PackedInt64Array = []
	
	# Include point to the left, if there is one
	if point_coords.x - 1 >= 0:
		neighbours.append(get_point_index_for_vector2i(point_coords + Vector2i(-1, 0)))
	
	# Include point to the right, if there is one
	if point_coords.x + 1 < point_grid_dimensions.x:
		neighbours.append(get_point_index_for_vector2i(point_coords + Vector2i(+1, 0)))
	
	# Include x == x on the above and lower rows
	if point_coords.y - 1 >= 0:
		neighbours.append(get_point_index_for_vector2i(point_coords + Vector2i(0, -1)))
	if point_coords.y + 1 < point_grid_dimensions.y:
		neighbours.append(get_point_index_for_vector2i(point_coords + Vector2i(0, +1)))
	
	# On even rows include, y+/-1 and x-1, On odd rows include, y+/-1 and x+1
	var offset_x = point_coords.x + (-1 if point_coords.x % 2 == 0 else 1)
	if offset_x >= 0 and offset_x < point_grid_dimensions.x:
		if point_coords.y - 1 >= 0:
			neighbours.append(get_point_index_for_vector2i(Vector2i(offset_x, point_coords.y - 1)))
		if point_coords.y + 1 < point_grid_dimensions.y:
			neighbours.append(get_point_index_for_vector2i(Vector2i(offset_x, point_coords.y + 1)))
	
	return neighbours

func get_point_index_for_vector2i(vector: Vector2i) -> int:
	return vector.x + (vector.y * _points_per_row)

func get_point_for_index(index: int) -> Vector2:
	return _grid_points[index]

func get_point_for_vector2i(vector: Vector2i) -> Vector2:
	return get_point_for_index(get_point_index_for_vector2i(vector))

func get_vector2i_for_point_index(index: int) -> Vector2i:
	return Vector2i(index % _points_per_row, index / _points_per_row)

func get_points_per_row() -> int:
	return _points_per_row

func get_row_count() -> int:
	return _point_rows

func get_point_grid_dimensions() -> Vector2i:
	return Vector2i(_points_per_row, _point_rows)

func get_total_point_count() -> int:
	return len(_grid_points)
