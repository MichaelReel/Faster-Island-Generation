class_name RiverMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer

func _init(
	regional_cell_layer: RegionCellLayer,
	height_layer: HeightLayer,
) -> void:
	_region_cell_layer = regional_cell_layer
	_height_layer = height_layer

func perform() -> void:
	
	debug_lines()

func debug_lines() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var point_indices: PackedInt64Array = _height_layer._sealevel_point_indices
	var point_connections: Dictionary = _region_cell_layer.get_valid_adjacent_point_indices_from_list(point_indices)
	
	for point_index in point_indices:
		for other_point_index in point_connections[point_index]:
			surface_tool.add_vertex(_region_cell_layer.get_point_as_vector3(point_index, 0.05))
			surface_tool.add_vertex(_region_cell_layer.get_point_as_vector3(other_point_index, 0.05))

	surface_tool.commit(self)
