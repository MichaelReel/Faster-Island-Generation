class_name RoadsMesh
extends ArrayMesh

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
	road_clearance: float = 0.1,
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
	
	for road in _road_layer.get_road_paths():
		if len(road) == 0:
			continue
		_get_road_surface_mesh_for_path(road, surface_tool)
		
	surface_tool.generate_normals()
	surface_tool.commit(self)

func _get_road_surface_mesh_for_path(road: PackedInt64Array, surface_tool: SurfaceTool) -> void:
	
	## TEMP DEBUG
	for cell_index in road:
		for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_index):
			var height = _height_layer.get_point_height(point_index) + _road_clearance
			var vertex = _tri_cell_layer.get_point_as_vector3(point_index, height)
			surface_tool.add_vertex(vertex)
	
#	# Draw a little bit of road for each pair of edges
#	var edge_pair_list = road_path.get_path_pair_edges()
#	for edge_pair in edge_pair_list:
#		var vertices: Array[Vector3] = _get_road_vertices_for_edges(edge_pair[0], edge_pair[1], width, clearance)
#		for vertex in vertices:
#			surface_tool.set_color(debug_color_dict.road_color)
#			surface_tool.add_vertex(vertex + clearance * Vector3.UP)

#
#static func _get_road_vertices_for_edges(edge_1: Edge, edge_2: Edge, width: float, clearance: float) -> Array[Vector3]:
#	var shared_point = edge_1.shared_point(edge_2)
#	var other_1 = edge_1.other_point(shared_point)
#	var other_2 = edge_2.other_point(shared_point)
#	var clearance_adjust = clearance * Vector3.UP
#	var vertices: Array[Vector3] = [
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#	]
#	return vertices
