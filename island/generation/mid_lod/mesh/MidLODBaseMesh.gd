extends ArrayMesh

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const MidLODTriCellLayer: GDScript = preload("../geometry/MidLODTriCellLayer.gd")

var _tri_cell_layer: TriCellLayer
var _mid_lod_cell_layer: MidLODTriCellLayer
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer, mid_lod_cell_layer: MidLODTriCellLayer, material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_mid_lod_cell_layer = mid_lod_cell_layer
	_material_lib = material_lib
	
func perform() -> void:
	
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material = _material_lib.get_material("sub_water")
	surface_tool.set_material(material)
	
	# This might be too much to render everything, may need to get more selective
	for cell_index in _tri_cell_layer.get_total_cell_count():
		var triangle_vertices: PackedVector3Array = _mid_lod_cell_layer.get_subtriangles_as_vector3(cell_index)
		for vertex in triangle_vertices:
			surface_tool.add_vertex(vertex)
		
	surface_tool.generate_normals()
	surface_tool.commit(self)
	
