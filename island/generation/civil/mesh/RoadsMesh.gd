extends ArrayMesh

const TriCellLayer = preload("../../grid/geometry/TriCellLayer.gd")
const HeightLayer = preload("../../height/geometry/HeightLayer.gd")
const RoadLayer = preload("../geometry/RoadLayer.gd")

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _road_layer: RoadLayer
var _material_lib: MaterialLib
var _road_width: float
var _road_clearance: float

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	road_layer: RoadLayer,
	material_lib: MaterialLib,
	road_width: float = 0.25,
	road_clearance: float = 0.05,
) -> void:
	_height_layer = height_layer
	_road_layer = road_layer
	_tri_cell_layer = tri_cell_layer
	_material_lib = material_lib
	_road_width = road_width
	_road_clearance = road_clearance

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("road"))
	
	for road in _road_layer.get_road_paths():
		if len(road) == 0:
			continue
		_get_road_surface_mesh_for_path(road, surface_tool)
		
	surface_tool.generate_normals()
	surface_tool.commit(self)

func _get_road_surface_mesh_for_path(road: PackedInt32Array, surface_tool: SurfaceTool) -> void:
	# Get the path as triangles (point arrays) where the middle point is the inside "curve"
	var path_pair_edges: Array[PackedInt32Array] = _get_path_pair_edges(road)
	
	# Draw a little bit of road for each pair of edges
	for path_edge_pair in path_pair_edges:
		var vertices: Array[Vector3] = _get_road_vertices_for_edges(path_edge_pair)
		for vertex in vertices:
			surface_tool.add_vertex(vertex)

func _get_road_vertices_for_edges(edge_pair: PackedInt32Array) -> Array[Vector3]:
	"""
	Return the six points required to draw a path between the centers of 2 edges
	The 2 edges in edge_pair are defined by 3 points where they join at the middle point
	"""
	var point_1: Vector3 = _tri_cell_layer.get_point_as_vector3(edge_pair[0], _height_layer.get_point_height(edge_pair[0]))
	var shared_point: Vector3 = _tri_cell_layer.get_point_as_vector3(edge_pair[1], _height_layer.get_point_height(edge_pair[1]))
	var point_3: Vector3 = _tri_cell_layer.get_point_as_vector3(edge_pair[2], _height_layer.get_point_height(edge_pair[2]))
	var clearance_adjust: Vector3 = _road_clearance * Vector3.UP
	var vertices: Array[Vector3] = [
		lerp(shared_point, point_1, 0.5 - 0.5 * _road_width) + clearance_adjust,
		lerp(shared_point, point_3, 0.5 - 0.5 * _road_width) + clearance_adjust,
		lerp(shared_point, point_3, 0.5 + 0.5 * _road_width) + clearance_adjust,
		lerp(shared_point, point_3, 0.5 + 0.5 * _road_width) + clearance_adjust,
		lerp(shared_point, point_1, 0.5 + 0.5 * _road_width) + clearance_adjust,
		lerp(shared_point, point_1, 0.5 - 0.5 * _road_width) + clearance_adjust,
	]
	return vertices

func _get_path_pair_edges(road: PackedInt32Array) -> Array[PackedInt32Array]:
	"""Return a list of point_index arrays, where 3 points represent 2 edges in clockwise rotation order"""
	
	var edges_as_point_lists: Array[PackedInt32Array] = _get_shared_edges_in_cell_path(road)
	
	var edge_pair_list: Array[PackedInt32Array] = []
	for i in range(len(edges_as_point_lists) - 1):
		edge_pair_list.append(
			_get_edges_as_point_indices_in_clockwise_order(
				edges_as_point_lists[i], edges_as_point_lists[i + 1], road[i + 1]
			)
		)
	
	return edge_pair_list

func _get_edges_as_point_indices_in_clockwise_order(
	edge_a: PackedInt32Array, edge_b: PackedInt32Array, cell_ind: int
) -> PackedInt32Array:
	"""
	Returns the edges as an array in clockwise order
	The shared point in the array is the middle point where the edges join.
	The first point should be the rotationally anti-clockwise point from the joint
	and the second point the rotationally clockwise point from the joint
	"""
	
	# The cells in the triangle are already in clockwise order
	var points_indices_in_triangle: PackedInt32Array = (
		_tri_cell_layer.get_triangle_as_point_indices(cell_ind)
	)
	
	# Order the edge points by the cell point order
	_order_values_in_edge_by_triangle_array(edge_a, points_indices_in_triangle)
	_order_values_in_edge_by_triangle_array(edge_b, points_indices_in_triangle)
	
	# Where the edges join determines the output
	if edge_a[0] == edge_b[1]:
		# Rotate from edge_b first around to edge_a
		return PackedInt32Array([edge_b[0], edge_a[0], edge_a[1]])
	elif edge_a[1] == edge_b[0]:
		# Rotate from edge_a first around to edge_b
		return PackedInt32Array([edge_a[0], edge_a[1], edge_b[1]])
	
	printerr("Edge %s and %s dont appear to join" % [edge_a, edge_b])
	return []

func _order_values_in_edge_by_triangle_array(
	edge: PackedInt32Array, triangle: PackedInt32Array
) -> void:
	"""
	Assuming the edge points are withing the triangle points
	Ensure the order of the edges points matches the rotational order of the triangle
	"""
	for i in range(len(triangle)):
		if edge[0] == triangle[i]:
			if edge[1] == triangle[(i + 1) % 3]:
				return
			if edge[1] == triangle[(i + 2) % 3]:
				edge.reverse()
				return
	
	printerr("Edge cells %s do not appear to be in triangle %s" % [edge, triangle])

func _get_shared_edges_in_cell_path(road: PackedInt32Array) -> Array[PackedInt32Array]:
	"""Get the sequence of edges crossing when traversing along cells in the road"""
	var shared_edge_sequence: Array[PackedInt32Array] = []
	for i in range(len(road) -1):
		var edge_as_point_indices: PackedInt32Array = _road_layer.get_shared_edge_as_point_indices(road[i], road[i + 1])
		shared_edge_sequence.append(edge_as_point_indices)
	
	return shared_edge_sequence
