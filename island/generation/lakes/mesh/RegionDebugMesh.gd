class_name RegionDebugMesh
extends ArrayMesh
"""
Mesh for debugging the region portion of the island generation
"""

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _material_lib: MaterialLib
var _island_region_index: int

func _init(
	tri_cell_layer: TriCellLayer, region_cell_layer: RegionCellLayer, island_region_index: int, material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_island_region_index = island_region_index
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
	
	var base_region_index: int = _region_cell_layer.get_region_ref()
	
	for cell_index in range(_tri_cell_layer.get_cell_count()):
		var surface_tool: SurfaceTool
		match _region_cell_layer.get_region_by_index_for_cell_index(cell_index):
			_island_region_index:
				surface_tool = ground_surface_tool
			base_region_index:
				surface_tool = sub_surface_tool
			_:
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
