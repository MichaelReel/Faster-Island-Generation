extends Stage


enum ORIENTATION { UP, DOWN, UNKNOWN }

const MAX_FLOAT: float = 1.79769e308


const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const LowLODAggregateLayer: GDScript = preload("LowLODAggregateLayer.gd")

var _tri_cell_layer: TriCellLayer
var _low_lod_agg_layer: LowLODAggregateLayer
var _mid_lod_subdivision: int
var _cell_subpoints: Array[PackedVector3Array]
var _cell_orientation: Array[ORIENTATION]

func _init(
	tri_cell_layer: TriCellLayer, low_lod_agg_layer: LowLODAggregateLayer, mid_lod_subdivision: int
) -> void:
	_tri_cell_layer = tri_cell_layer
	_low_lod_agg_layer = low_lod_agg_layer
	_mid_lod_subdivision = mid_lod_subdivision

#
#
# TODO: Point heights don't seem to be getting set correctly!
#
#

func perform() -> void:
	var cell_count = _tri_cell_layer.get_total_cell_count()
	_cell_subpoints.resize(cell_count)
	_cell_orientation.resize(cell_count)
	# Create a new subsectioned triangle grid for every triangle in the tri cell grid
	for cell_index in range(cell_count):
		# Get the points in the cell, the points wont have the cell height yet, but that's okay
		var outer_verts: PackedVector3Array = _tri_cell_layer.get_triangle_as_vector3_array_for_index(cell_index)
		
		var sorted_verts: Array[Vector3] = _sort_vertices_z_x_inc(outer_verts)
		
		_cell_orientation[cell_index] =  _point_up_or_point_down(sorted_verts)
		_cell_subpoints[cell_index] = _subdivide_triangle(
			sorted_verts, _mid_lod_subdivision, _cell_orientation[cell_index]
		)
		 
		# Fit each new vertex to the current height maps 
		_set_heights_to_low_lod_height(_cell_subpoints[cell_index], _low_lod_agg_layer)

func get_cell_subpoints(cell_index: int) -> PackedVector3Array:
	return _cell_subpoints[cell_index]

func get_cell_orientation(cell_index: int) -> ORIENTATION:
	return _cell_orientation[cell_index]

func _sort_vertices_z_x_inc(outer_verts: PackedVector3Array) -> Array[Vector3]:
	var sorted_verts: Array[Vector3] = []
	sorted_verts.assign(outer_verts)
	sorted_verts.sort_custom(
		func(v1: Vector3, v2: Vector3):
			if v1.z < v2.z:
				return true
			return v1.z == v2.z and v1.x < v2.x
	)
	return sorted_verts

func _point_up_or_point_down(sorted_verts: Array[Vector3]) -> ORIENTATION:
	var points_down: bool = sorted_verts[0].z == sorted_verts[1].z
	var points_up: bool = sorted_verts[1].z == sorted_verts[2].z
	
	if points_down == points_up:
		printerr("Unorientated Triangle " + str(sorted_verts))
		return ORIENTATION.UNKNOWN
	
	return ORIENTATION.UP if points_up else ORIENTATION.DOWN if points_down else ORIENTATION.UNKNOWN

func _subdivide_triangle(
	sorted_verts: Array[Vector3], mid_lod_subdivision: int, triangle_orientation
) -> PackedVector3Array:
	# Create a bunch of new vertices
	#
	#  |<------ dx ------>|                points up
	#
	#  0/________________\1           _________0/_________    ___
	#  /\    /\    /\    /\                    /\              ^
	#    \  /  \  /  \  /                     /  \             |
	#     \/____\/____\/      ___            /____\            |
	#      \    /\    /        ^            /\    /\           |
	#       \  /  \  /         | dsz       /  \  /  \          | dz
	#        \/____\/         _v_         /____\/____\         |
	#         \    /                     /\    /\    /\        |
	#          \  /                     /  \  /  \  /  \       |
	#  _________\/_________           \/____\/____\/____\/    _v_
	#           2\                    1\                /2
	#                                       |<---->|
	#       points down                       dsx
	
	# Each dsx will be the dx divided by the mid_lod_subdivision
	# The offset to x will be half dsx for each odd row
	# Each dsz will be the dz divided by the segment count
		
	# Start at lowest z, then lowest x
	# If up triangle start with 1 point, inc z, then 2 points with a negative half dsx offset
	# If down triangle, start by adding mid_lod_subdivision + 1 points,
	#    then reduce by one each row, offsetting by adding half dsx

	if triangle_orientation == ORIENTATION.UP:
		return _subdivide_upward_pointing_triangle(sorted_verts, mid_lod_subdivision)
	
	if triangle_orientation == ORIENTATION.DOWN:
		return _subdivide_downward_pointing_triangle(sorted_verts, mid_lod_subdivision)
	
	return PackedVector3Array()

func _subdivide_upward_pointing_triangle(
	sorted_verts: Array[Vector3], mid_lod_subdivision: int
) -> PackedVector3Array:
	# Start at lowest z
	# If up triangle start with 1 point, inc z, then 2 points with a negative half dsx offset
	var dx: float = sorted_verts[2].x - sorted_verts[1].x
	var dz: float = sorted_verts[1].z - sorted_verts[0].z
	var dsx: float = dx / float(mid_lod_subdivision)
	var dsz: float = dz / float(mid_lod_subdivision)
	var offset: float = -dsx / 2.0
	
	var new_vertices: PackedVector3Array = PackedVector3Array()
	for row: int in range(mid_lod_subdivision + 1):
		for v_in_row: int in range(row + 1):
			new_vertices.append(Vector3(
				sorted_verts[0].x + (v_in_row * dsx) + (row * offset),
				0, # Will update from height map after
				sorted_verts[0].z + (row * dsz)
			))
	
	return new_vertices

func _subdivide_downward_pointing_triangle(
	sorted_verts: Array[Vector3], mid_lod_subdivision: int
) -> PackedVector3Array:
	# Start at lowest x
	# If down triangle, start by adding mid_lod_subdivision + 1 points,
	#    then reduce by one each row, offsetting by adding half dsx
	var dx: float = sorted_verts[1].x - sorted_verts[0].x
	var dz: float = sorted_verts[2].z - sorted_verts[1].z
	var dsx: float = dx / float(mid_lod_subdivision)
	var dsz: float = dz / float(mid_lod_subdivision)
	var offset: float = dsx / 2.0
	
	var new_vertices: PackedVector3Array = PackedVector3Array()
	for row:int in range(mid_lod_subdivision + 1):
		for v_in_row: int in range(mid_lod_subdivision - row + 1):
			new_vertices.append(Vector3(
				sorted_verts[0].x + (v_in_row * dsx) + (row * offset),
				0, # Will update from height map after
				sorted_verts[0].z + (row * dsz)
			))
	
	return new_vertices

func _set_heights_to_low_lod_height(points: PackedVector3Array, low_lod_agg_layer: LowLODAggregateLayer) -> void:
	for point in points:
		point.y = low_lod_agg_layer.get_height_at_xz(Vector2(point.x, point.z))

func _to_string() -> String:
	return "Mid LOD Point Stage"
