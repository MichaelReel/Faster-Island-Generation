class_name DebugRoadMesh
extends ArrayMesh

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _road_layer: RoadLayer
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	road_layer: RoadLayer,
	material_lib: MaterialLib
) -> void:
	_height_layer = height_layer
	_road_layer = road_layer
	_tri_cell_layer = tri_cell_layer
	_material_lib = material_lib

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material = _material_lib.get_material("settlement")
	surface_tool.set_material(material)
	
	for pos in _road_layer.get_road_mid_point_vector3s():
		_add_mid_point_marker_debug_to_mesh(surface_tool, pos, 1.0)
	
	surface_tool.generate_normals()
	surface_tool.commit(self)

func _add_mid_point_marker_debug_to_mesh(surface_tool: SurfaceTool, pos: Vector3, size: float) -> void:
	var vertices: Array[PackedVector3Array] = [
		PackedVector3Array([
			pos,
			pos + (Vector3.UP * size) + (Vector3.LEFT * size * 0.5),
			pos + (Vector3.UP * size) + (Vector3.RIGHT * size * 0.5),
		]),
		PackedVector3Array([
			pos,
			pos + (Vector3.UP * size) + (Vector3.FORWARD * size * 0.5),
			pos + (Vector3.UP * size) + (Vector3.BACK * size * 0.5),
		]),
	]

	for poly in vertices:
		for _i in range(2):
			for vertex in poly:
				surface_tool.add_vertex(vertex)
			poly.reverse()
