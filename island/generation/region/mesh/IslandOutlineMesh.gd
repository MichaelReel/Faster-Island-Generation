extends ArrayMesh
"""
Line mesh for outline of the island region
"""

const TriCellLayer = preload("../../grid/geometry/TriCellLayer.gd")
const IslandOutlineLayer = preload("../geometry/IslandOutlineLayer.gd")
const RegionCellLayer = preload("../geometry/RegionCellLayer.gd")

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _island_outline_layer: IslandOutlineLayer

func _init(
	tri_cell_layer: TriCellLayer,
	regional_cell_layer: RegionCellLayer,
	island_outline_layer: IslandOutlineLayer,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = regional_cell_layer
	_island_outline_layer = island_outline_layer

func perform() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var island_ind: int = _island_outline_layer.get_island_region_index()
	var point_indices: PackedInt32Array = _region_cell_layer.get_outer_perimeter_point_indices(island_ind)
	var point_connections: Dictionary = _region_cell_layer.get_valid_adjacent_point_indices_from_list(point_indices)
	
	for point_index in point_indices:
		for other_point_index in point_connections[point_index]:
			surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(point_index, 0.05))
			surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(other_point_index, 0.05))

	surface_tool.commit(self)
