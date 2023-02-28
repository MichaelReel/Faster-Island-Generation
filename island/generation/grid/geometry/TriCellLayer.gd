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
			var new_triangle: PackedInt64Array = _create_tricell(Vector2i(tri_col_ind, tri_row_ind))
			_cells.append(new_triangle)
	
	for tri_cell_ind in range(len(_cells)):
		_update_neighbours(tri_cell_ind, _cells[tri_cell_ind])

func get_tricell_index_for_vector2i(vector: Vector2i) -> int:
	return vector.x + (vector.y * _tri_per_row)

func _create_tricell(vector: Vector2i) -> PackedInt64Array:
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

func _update_neighbours(tri_cell_ind: int, tri_cell: PackedInt64Array) -> void:
	# TODO
	pass
