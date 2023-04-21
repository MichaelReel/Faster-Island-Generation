extends ArrayMesh
"""
Line mesh for base outline of lakes
"""

const TriCellLayer = preload("../../grid/geometry/TriCellLayer.gd")
const RegionCellLayer = preload("../../region/geometry/RegionCellLayer.gd")
const LakeLayer = preload("../geometry/LakeLayer.gd")

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer

func _init(
	tri_cell_layer: TriCellLayer,
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = regional_cell_layer
	_lake_layer = lake_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	for lake_ind in _lake_layer.get_lake_region_indices():
		var point_indices: PackedInt32Array = _region_cell_layer.get_outer_perimeter_point_indices(lake_ind)
		var point_connections: Dictionary = _region_cell_layer.get_valid_adjacent_point_indices_from_list(point_indices)
		
		for point_index in point_indices:
			for other_point_index in point_connections[point_index]:
				surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(point_index, 0.05))
				surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(other_point_index, 0.05))

	surface_tool.commit(self)
