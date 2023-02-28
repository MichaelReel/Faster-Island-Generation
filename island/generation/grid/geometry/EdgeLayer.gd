class_name EdgeLayer
extends Object

var _point_layer: PointLayer
var _connections: Array[PackedInt64Array] = []

func _init(point_layer: PointLayer) -> void:
	_point_layer = point_layer
 
func perform() -> void:
	var points_per_row = _point_layer.get_points_per_row()
	var point_rows = _point_layer.get_row_count()
	
	for _i in range(_point_layer.get_total_point_count()):
		_connections.append(PackedInt64Array())
	
	"""Layout, join and record edges between points"""
	for row_ind in range(point_rows):
		# parity should be +1 on odd, -1 on even
		var parity: int = (row_ind % 2) * 2 - 1
		for col_ind in range(points_per_row):
			var point_layer_ind = _point_layer.get_point_index_for_vector2i(Vector2i(col_ind, row_ind))
			if col_ind > 0:
				var other_ind = _point_layer.get_point_index_for_vector2i(Vector2i(col_ind - 1, row_ind))
				_add_grid_line(point_layer_ind, other_ind)
			if row_ind > 0 and col_ind < points_per_row:
				var other_ind = _point_layer.get_point_index_for_vector2i(Vector2i(col_ind, row_ind - 1))
				_add_grid_line(other_ind, point_layer_ind)
			if row_ind > 0 and col_ind + parity >= 0 and col_ind + parity < points_per_row:
				var other_ind = _point_layer.get_point_index_for_vector2i(Vector2i(col_ind + parity, row_ind - 1))
				_add_grid_line(other_ind, point_layer_ind)

func _add_grid_line(point_index_a: int, point_index_b: int) -> void:
	if not point_index_b in _connections[point_index_a]:
		_connections[point_index_a].append(point_index_b)
	if not point_index_a in _connections[point_index_b]:
		_connections[point_index_b].append(point_index_a)
