extends ArrayMesh

const PointLayer = preload("../geometry/PointLayer.gd")
const TriCellLayer = preload("../geometry/TriCellLayer.gd")

var _point_layer: PointLayer
var _tri_cell_layer: TriCellLayer
var _material_lib: MaterialLib

func _init(point_layer: PointLayer, tri_cell_layer: TriCellLayer, material_lib: MaterialLib) -> void:
	_point_layer = point_layer
	_tri_cell_layer = tri_cell_layer
	_material_lib = material_lib

func perform() -> void:
	var triangle_arrays: = _tri_cell_layer.get_triangles_as_vector3_arrays()
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material = _material_lib.get_material("sub_water")
	surface_tool.set_material(material)
	for triangle_vertices in triangle_arrays:
		for vertex in triangle_vertices:
			surface_tool.add_vertex(vertex)
	surface_tool.generate_normals()
	surface_tool.commit(self)
