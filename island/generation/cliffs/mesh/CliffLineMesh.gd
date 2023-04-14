class_name CliffLineMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _cliff_layer: CliffLayer

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	cliff_layer: CliffLayer
) -> void:
	_tri_cell_layer = tri_cell_layer
	_height_layer = height_layer
	_cliff_layer = cliff_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var cliff_base_lines: Array[PackedInt32Array] = _cliff_layer._cliff_base_chains
	for cliff_as_point_indices in cliff_base_lines:
		for cliff_index in range(len(cliff_as_point_indices) - 1):
			var point_index_a = cliff_as_point_indices[cliff_index]
			var point_index_b = cliff_as_point_indices[cliff_index + 1]
			
			var vertex_a = _tri_cell_layer.get_point_as_vector3(point_index_a, _height_layer.get_point_height(point_index_a) + 0.05)
			var vertex_b = _tri_cell_layer.get_point_as_vector3(point_index_b, _height_layer.get_point_height(point_index_b) + 0.05)
		
			surface_tool.add_vertex(vertex_a)
			surface_tool.add_vertex(vertex_b)

	surface_tool.commit(self)
