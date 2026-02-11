extends Stage

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const MidLODPointLayer: GDScript = preload("MidLODPointLayer.gd")

var _tri_cell_layer: TriCellLayer
var _mid_lod_point_layer: MidLODPointLayer
var _mid_lod_subdivision: int

var _cell_up_subtriangles: PackedInt32Array
var _cell_down_subtriangles: PackedInt32Array

func _init(
	tri_cell_layer: TriCellLayer,
	mid_lod_point_layer: MidLODPointLayer,
	mid_lod_subdivision: int,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_mid_lod_point_layer = mid_lod_point_layer
	_mid_lod_subdivision = mid_lod_subdivision


#
#
# TODO: Reverse the vertex order of all the triangle!
#    - Note, code fix is easy, need to update docs/examples here too!
#


func perform() -> void:
	# We don't need to go through each triangle,
	# we only need to know the orientation
	# and the triangles will have the same indices for each cell orientation
	
	#  0/____1_____2_____\3                     _________0/_________    row
	#  /\ t0 /\ t2 /\ t4 /\                              /\              
	#    \  /t1\  /t3\  /                               /t0\             0
	#    4\/____\/____\/6                             1/____\2           
	#      \ t5 /\ t7 /                               /\ t2 /\           
	#       \  /t6\  /                               /t1\  /t3\          1
	#       7\/____\/8                             3/____\/____\5        
	#         \ t8 /                               /\ t5 /\ t7 /\        
	#          \  /                               /t4\  /t6\  /t8\       2
	#  _________\/_________                     \/____\/____\/____\/     
	#           9\                              6\    7     8     /9     

	# 1,0,4  1,4,5  2,1,5  2,5,6  3,2,6                0,1,2
	#        5,4,7  5,7,8  6,5,8                1,3,4  1,4,2  2,4,5
	#               8,7,9                3,6,7  3,7,4  4,7,8  4,8,5  5,8,9
	#                             6,A,B  6,B,7  7,B,C  7,C,8  8,C,D  8,D,9  9,D,E
	

	_cell_up_subtriangles = _create_cell_up_subtriangles(_mid_lod_subdivision)
	_cell_down_subtriangles = _create_cell_down_subtriangles(
		_mid_lod_subdivision, _cell_up_subtriangles
	)
	
func _create_cell_up_subtriangles(mid_lod_subdivision: int) -> PackedInt32Array:
	var tri_indices: PackedInt32Array = PackedInt32Array()

	# Upward cells always start and continue the same way
	# 
	#     row            _________0/_________ 
	#                             /\          
	#      0                     /t0\         
	#                          1/____\2       
	#                          /\ t2 /\       
	#      1                  /t1\  /t3\      
	#                       3/____\/____\5    
	#                       /\ t5 /\ t7 /\    
	#      2               /t4\  /t6\  /t8\   
	#                    \/____\/____\/____\/ 
	#                    6\    7     8     /9 
 
	#                           0,1,2
	#                    1,3,4  1,4,2  2,4,5
	#             3,6,7  3,7,4  4,7,8  4,8,5  5,8,9
	# 6,10,11  6,11,7  7,11,12  7,12,8  8,12,13  8,13,9  9,13,14
	#                         ...etc...
	
	var tri_1_start_point: int = 0
	for row: int in range(mid_lod_subdivision):
		var cells_in_row: int = row * 2 + 1
		
		# Each row of points starts with a trangular number 0, 1, 3, 6, 10 etc.
		tri_1_start_point += row
		# Each second point starts with the next trianglular number up
		var tri_2_start_point: int = tri_1_start_point + row + 1
		# The third point will start on the second row of points, just after the second point
		var tri_3_start_point_a: int = tri_2_start_point + 1
		# The third point will alternatve to the first row
		var tri_3_start_point_b: int = tri_1_start_point + 1
		
		for cell_in_row: int in range(cells_in_row):
			# First points all increment every even one across 0, 1 1 2, 3 3 4 4 5, 6 6 7 7 8 8 9
			var tri_1: int = tri_1_start_point + cell_in_row / 2
			# Second points all increment every odd one across 1, 3 4 4, 6 7 7 8 8, 10 11 11 12 12 13 13 
			var tri_2: int = tri_2_start_point + (cell_in_row + 1) / 2
			# Third points alternate between rows, evens to a, odds to b
			# 2, 4 2 5, 7 4 8 5 9, 11 7 12 8 13 9 14
			var tri_3: int = cell_in_row / 2 + (
				tri_3_start_point_a if cell_in_row % 2 == 0 else tri_3_start_point_b
			)

			tri_indices.append(tri_1)
			tri_indices.append(tri_2)
			tri_indices.append(tri_3)
	
	return tri_indices

func _create_cell_down_subtriangles(
	mid_lod_subdivision: int, cell_up_subtriangles: PackedInt32Array
) -> PackedInt32Array:
	var tri_indices: PackedInt32Array = PackedInt32Array()

	# The downwards triangle can be made from the upwards list
	# Find the max point index, then foreach trio from the back of the upward list:
	#   deduct each index from max point index
	#   add each index to the down indices, rotating slightly

	#  0/____1_____2_____\3              
	#  /\ t0 /\ t2 /\ t4 /\              
	#    \  /t1\  /t3\  /                
	#    4\/____\/____\/6                
	#      \ t5 /\ t7 /                  
	#       \  /t6\  /                   
	#       7\/____\/8                   
	#         \ t8 /                     
	#          \  /                      
	#  _________\/_________              
	#           9\                       
	#
	# 1,0,4  1,4,5  2,1,5  2,5,6  3,2,6  
	#        5,4,7  5,7,8  6,5,8         
	#               8,7,9                
	#                                    
	
	var points_per_side: int = mid_lod_subdivision + 1
	var max_point_index: int = points_per_side * (points_per_side + 1) / 2 - 1
	var pos: int = len(cell_up_subtriangles)
	
	while pos > 0:
		pos -= 3
		var tri_1: int = max_point_index - cell_up_subtriangles[pos]
		var tri_2: int = max_point_index - cell_up_subtriangles[pos + 1]
		var tri_3: int = max_point_index - cell_up_subtriangles[pos + 2]
		
		tri_indices.append(tri_2)
		tri_indices.append(tri_3)
		tri_indices.append(tri_1)
	
	return tri_indices

func get_subcell_index_by_coords() -> int:

	# Need to think about how to reference a subcell

	return 0

	#                          point columns
	#                 0         1         2         3   
	#             ,-------. ,-------. ,-------. ,-------. 
	#            |         |         |         |         | 
	#      0--    ______________________________________
	#             \        /\        /\        /\       
	#              \(0,0) /  \(2,0) /  \(4,0) /  \(6,0)  
	#               \    /    \    /    \    /    \    /   - Triangle row 0
	#                \  /(1,0) \  /(3,0) \  /(5,0) \  / 
	#      1--        \/________\/________\/________\/  
	#  p              /\        /\        /\        /\  
	#  o             /  \(1,1) /  \(3,1) /  \(5,1) /  \ 
	#  i            /    \    /    \    /    \    /    \   - Triangle row 1
	#  n           /(0,1) \  /(2,1) \  /(4,1) \  /(6,1)  
	#  t   2--    /________\/________\/________\/_______
	#             \        /\        /\        /\       
	#  r           \(0,2) /  \(2,2) /  \(4,2) /  \(6,2)  
	#  o            \    /    \    /    \    /    \    /   - Triangle row 2
	#  w             \  /(1,2) \  /(3,2) \  /(5,2) \  / 
	#  s   3--        \/________\/________\/________\/  
	#                 /\        /\        /\        /\  
	#                /  \(1,3) /  \(3,3) /  \(5,3) /  \ 
	#               /    \    /    \    /    \    /    \   - Triangle row 3
	#              /(0,3) \  /(2,3) \  /(4,3) \  /(6,3)  
	#      4--    /________\/________\/________\/_______
	#             \        /\        /\        /\       
	#  
	#                 ^    ^    ^    ^    ^    ^    ^
	#                 0    1    2    3    4    5    6
	#                         Triangle columns


func get_subtriangles_as_vector3(cell_index: int) -> PackedVector3Array:
	var subpoints: PackedVector3Array = _mid_lod_point_layer.get_cell_subpoints(cell_index)
	var subtriangles_as_vectors: PackedVector3Array = PackedVector3Array()
	var cell_subtriangle_indices: PackedInt32Array = (
		_cell_up_subtriangles
		if _mid_lod_point_layer.get_cell_orientation(cell_index) == MidLODPointLayer.ORIENTATION.UP
		else _cell_down_subtriangles
	)
	
	for point_index in cell_subtriangle_indices:
		subtriangles_as_vectors.append(subpoints[point_index])
	
	return subtriangles_as_vectors


func _to_string() -> String:
	return "Mid LOD Triangle Stage"
