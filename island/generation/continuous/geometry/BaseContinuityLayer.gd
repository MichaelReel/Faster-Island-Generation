extends Stage

const TriCellLayer = preload("../../grid/geometry/TriCellLayer.gd")
const CliffLayer = preload("../../cliffs/geometry/CliffLayer.gd")

var readied: bool = false

var _tri_cell_layer: TriCellLayer
var _cliff_layer: CliffLayer

func _init(
	tri_cell_layer: TriCellLayer,
	cliff_layer: CliffLayer,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_cliff_layer = cliff_layer

func perform() -> void:
	readied = true

func get_height_at_xz(xz: Vector2) -> float:
	if not readied:
		return 0.0
	
	# Find the cell this point is in (or not)
	var cell_ind: int = _tri_cell_layer.get_cell_index_at_xz_position(xz)
	if cell_ind < 0 or cell_ind >= _tri_cell_layer.get_total_cell_count():
		return 0.0
	
	# Find the real positions of all the associated corners for this cell 
	var point_indices: PackedInt32Array = _tri_cell_layer.get_triangle_as_point_indices(cell_ind)
	var vertices: PackedVector3Array = PackedVector3Array(
			Array(point_indices).map(
			func (point_index: int): return _tri_cell_layer.get_point_as_vector3(
				point_index, _cliff_layer.get_height_from_cell_and_point_indices(cell_ind, point_index)
			)
		)
	)
	
	# Get the height of the point within the cell
	var normal: Vector3 = _get_normal(vertices)
	return vertices[1].y - (normal.z * (xz.y - vertices[1].z) + normal.x * (xz.x - vertices[1].x)) / normal.y

func _get_normal(points: PackedVector3Array) -> Vector3:
	return (points[1] - points[0]).cross(points[1] - points[2])

