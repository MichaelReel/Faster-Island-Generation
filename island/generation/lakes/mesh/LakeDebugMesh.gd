class_name LakeDebugMesh
extends ArrayMesh
"""
Mesh for debugging the region and lake portion of the island generation
"""

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _island_outline_layer: IslandOutlineLayer
var _region_indices: PackedInt32Array
var _lake_indices: PackedInt32Array
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	region_cell_layer: RegionCellLayer,
	island_outline_layer: IslandOutlineLayer,
	region_indices: PackedInt32Array,
	lake_indices: PackedInt32Array,
	material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_island_outline_layer = island_outline_layer
	_region_indices = region_indices
	_lake_indices = lake_indices
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	var region_debug_tool: SurfaceTool = SurfaceTool.new()
	
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	region_debug_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	region_debug_tool.set_material(_material_lib.get_material("region_debug"))
	
	var base_region_index: int = _region_cell_layer.get_root_region_index()
	
	for cell_index in range(_tri_cell_layer.get_total_cell_count()):
		var surface_tool: SurfaceTool
		var island_region_index: int = _island_outline_layer.get_island_region_index()
		match _region_cell_layer.get_region_index_for_cell(cell_index):
			island_region_index:
				surface_tool = ground_surface_tool
			base_region_index:
				surface_tool = sub_surface_tool
			var region_index:
				if region_index in _lake_indices:
					surface_tool = sub_surface_tool
				else:
					surface_tool = region_debug_tool

		var triangle_vertices = _tri_cell_layer.get_triangle_as_vector3_array_for_index(cell_index)
		for vertex in triangle_vertices:
			surface_tool.add_vertex(vertex)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	region_debug_tool.generate_normals()
	
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
	region_debug_tool.commit(self)
