extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const HeightLayer: GDScript = preload("../../height/geometry/HeightLayer.gd")
const RiverLayer: GDScript = preload("../geometry/RiverLayer.gd")

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_height_layer = height_layer
	_river_layer = river_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	for river_index in range(_river_layer.get_total_river_count()):
		var river: PackedInt32Array = _river_layer.get_river_midstream_point_indices_by_index(river_index)
		for list_position in range(len(river) - 1):
			var point_index_a: int = river[list_position]
			var point_index_b: int = river[list_position + 1]
			var height_a: float = _height_layer.get_point_height(point_index_a)
			var height_b: float = _height_layer.get_point_height(point_index_b)
			var vertex_a: Vector3 = _tri_cell_layer.get_point_as_vector3(point_index_a, height_a + 0.05)
			var vertex_b: Vector3 = _tri_cell_layer.get_point_as_vector3(point_index_b, height_b + 0.05)
			surface_tool.add_vertex(vertex_a)
			surface_tool.add_vertex(vertex_b)

	surface_tool.commit(self)
