class_name RiverMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer

func _init(
	regional_cell_layer: RegionCellLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
) -> void:
	_region_cell_layer = regional_cell_layer
	_height_layer = height_layer
	_river_layer = river_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var rivers: Array[PackedInt64Array] = _river_layer.get_rivers()
	for river in rivers:
		for list_position in range(len(river) - 1):
			var point_index_a: int = river[list_position]
			var point_index_b: int = river[list_position + 1]
			var height_a: float = _height_layer.get_point_height(point_index_a)
			var height_b: float = _height_layer.get_point_height(point_index_b)
			var vertex_a: Vector3 = _region_cell_layer.get_point_as_vector3(point_index_a, height_a + 0.05)
			var vertex_b: Vector3 = _region_cell_layer.get_point_as_vector3(point_index_b, height_b + 0.05)
			surface_tool.add_vertex(vertex_a)
			surface_tool.add_vertex(vertex_b)

	surface_tool.commit(self)
