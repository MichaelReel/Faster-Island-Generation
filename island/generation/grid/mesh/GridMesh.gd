class_name GridMesh
extends ArrayMesh

var _point_layer: PointLayer
var _tri_cell_layer: TriCellLayer

func _init(point_layer: PointLayer, tri_cell_layer: TriCellLayer) -> void:
	_point_layer = point_layer
	_tri_cell_layer = tri_cell_layer

func perform() -> void:
	var triangle_arrays: = _tri_cell_layer.get_triangles_as_vector3_arrays()
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle_vertices in triangle_arrays:
		for vertex in triangle_vertices:
			surface_tool.add_vertex(vertex)
	surface_tool.generate_normals()
	surface_tool.commit(self)
