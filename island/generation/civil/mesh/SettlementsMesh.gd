class_name SettlementsMesh
extends ArrayMesh

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _settlement_layer: SettlementLayer
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	settlement_layer: SettlementLayer,
	material_lib: MaterialLib
) -> void:
	_height_layer = height_layer
	_settlement_layer = settlement_layer
	_tri_cell_layer = tri_cell_layer
	_material_lib = material_lib

func perform() -> void:
	var clearance: float = 0.05
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material = _material_lib.get_material("settlement")
	surface_tool.set_material(material)
	for cell_index in _settlement_layer.get_settlement_cell_indices():
		_add_settlement_debug_to_mesh(surface_tool, cell_index, clearance)
	
	surface_tool.generate_normals()
	surface_tool.commit(self)

func _add_settlement_debug_to_mesh(surface_tool: SurfaceTool, cell_index: int, clearance: float) -> void:
	var point_indices: PackedInt64Array = _tri_cell_layer.get_triangle_as_point_indices(cell_index)
	
	for point_index in point_indices:
		var point_height: float =  _height_layer.get_point_height(point_index) + clearance
		var vertex: Vector3 = _tri_cell_layer.get_point_as_vector3(point_index, point_height)
		surface_tool.add_vertex(vertex)
