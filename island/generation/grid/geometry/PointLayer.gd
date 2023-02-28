class_name PointLayer
extends Object

var _tri_side: float
var _tri_height: float
var _points_per_row: int
var _point_rows: int
var _mesh_center: Vector2
var _grid_points: PackedVector2Array = []

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

func get_point_index_for_vector2i(vector: Vector2i) -> int:
	return vector.x + (vector.y * _points_per_row)

func get_point_for_vector2i(vector: Vector2i) -> Vector2:
	return _grid_points[get_point_index_for_vector2i(vector)]

func get_points_per_row() -> int:
	return _points_per_row

func get_row_count() -> int:
	return _point_rows

func get_total_point_count() -> int:
	return len(_grid_points)
