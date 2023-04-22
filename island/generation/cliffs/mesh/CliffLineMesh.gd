extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const CliffLayer: GDScript = preload("../geometry/CliffLayer.gd")

var _tri_cell_layer: TriCellLayer
var _cliff_layer: CliffLayer

func _init(
	tri_cell_layer: TriCellLayer,
	cliff_layer: CliffLayer
) -> void:
	_tri_cell_layer = tri_cell_layer
	_cliff_layer = cliff_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var cliff_base_lines: Array[PackedInt32Array] = _cliff_layer._cliff_base_chains
	for cliff_index in range(len(cliff_base_lines)):
		var cliff_as_point_indices: PackedInt32Array = cliff_base_lines[cliff_index]
		var base_and_top_elevations: Array[PackedFloat32Array] = _cliff_layer.get_cliff_elevation_lines(cliff_index)
		var cliff_base_heights: PackedFloat32Array = base_and_top_elevations[0]
		var cliff_top_heights: PackedFloat32Array = base_and_top_elevations[1]
		
		for index_in_cliff in range(len(cliff_as_point_indices) - 1):
			var point_index_a = cliff_as_point_indices[index_in_cliff]
			var point_index_b = cliff_as_point_indices[index_in_cliff + 1]
			
			var vertex_a = _tri_cell_layer.get_point_as_vector3(point_index_a, cliff_base_heights[index_in_cliff] + 0.05)
			var vertex_b = _tri_cell_layer.get_point_as_vector3(point_index_b, cliff_base_heights[index_in_cliff + 1] + 0.05)
		
			surface_tool.add_vertex(vertex_a)
			surface_tool.add_vertex(vertex_b)
			
			var top_vertex_a = _tri_cell_layer.get_point_as_vector3(point_index_a, cliff_top_heights[index_in_cliff] + 0.05)
			var top_vertex_b = _tri_cell_layer.get_point_as_vector3(point_index_b, cliff_top_heights[index_in_cliff + 1] + 0.05)
		
			surface_tool.add_vertex(top_vertex_a)
			surface_tool.add_vertex(top_vertex_b)

	surface_tool.commit(self)
