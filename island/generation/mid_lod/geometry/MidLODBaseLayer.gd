extends Stage


const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const LowLODAggregateLayer: GDScript = preload("LowLODAggregateLayer.gd")

var _tri_cell_layer: TriCellLayer
var _low_lod_agg_layer: LowLODAggregateLayer
var _mid_lod_subdivision: int

func _init(
	tri_cell_layer: TriCellLayer, low_lod_agg_layer: LowLODAggregateLayer, mid_lod_subdivision: int
) -> void:
	_tri_cell_layer = tri_cell_layer
	_low_lod_agg_layer = low_lod_agg_layer
	_mid_lod_subdivision = mid_lod_subdivision

func perform() -> void:
	
	# Create a new subsectioned triangle grid for every triangle in the tri cell grid
	for cell_index in range(_tri_cell_layer.get_total_cell_count()):
		# Get the points in the cell, the points wont have the cell height yet, but that's okay
		var outer_verts: PackedVector3Array = _tri_cell_layer.get_triangle_as_vector3_array_for_index(cell_index)
	
		# Create a bunch of new vertices
		#
		#  |<------ dx ------>|                points up
		#
		#  \/________________\/           _________\/_________    ___
		#  /\    /\    /\    /\                    /\              ^
		#    \  /  \  /  \  /                     /  \             |
		#     \/____\/____\/      ___            /____\            |
		#      \    /\    /        ^            /\    /\           |
		#       \  /  \  /         | dsz       /  \  /  \          | dz
		#        \/____\/         _v_         /____\/____\         |
		#         \    /                     /\    /\    /\        |
		#          \  /                     /  \  /  \  /  \       |
		#  _________\/_________           \/____\/____\/____\/    _v_
		#           /\                    /\                /\
		#                                       |<---->|
		#       points down                       dsx
		
		# Each dsx will be the dx divided by the mid_lod_subdivision
		# The offset to x will be half dsx for each odd row
		# Each dsz will be the dz divided by the segment countw
		
		var sub_vertices: PackedVector3Array = _subdivide_triangle(outer_verts)
		

		# Fit each new vertex to the current height map
		
		# Store the vertices - do we need to replicate the point layer?
		
		
func _subdivide_triangle(outer_verts: PackedVector3Array) -> PackedVector3Array:
	var sub_vertices: PackedVector3Array = PackedVector3Array()
	# Start at lowest z, then lowest x
	# If up triangle start with 1 point, inc z, then 2 points with a negative half dsx offset
	# If down triangle, start by adding mid_lod_subdivision + 1 points,
	#    then reduce by one each row, offsetting by adding half dsx
	
	
	return sub_vertices
	

func _to_string() -> String:
	return "Mid LOD Stage"
