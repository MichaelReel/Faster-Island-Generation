class_name HeightMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _island_region_index: int
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	regional_cell_layer: RegionCellLayer,
	island_region_index: int,
	material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = regional_cell_layer
	_island_region_index = island_region_index
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	var debug_surface_tool: SurfaceTool = SurfaceTool.new()
	
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	debug_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	debug_surface_tool.set_material(_material_lib.get_material("region_debug"))
	
	
	for cell_index in range(_tri_cell_layer.get_cell_count()):
		var region_index: int = _region_cell_layer.get_region_by_index_for_cell_index(cell_index)
		var triangle_vertices = _tri_cell_layer.get_triangle_as_vector3_array_for_index(cell_index)
		if len(_region_cell_layer._region_fronts_by_cell_index[cell_index]) > 0:
			for vertex in triangle_vertices:
				debug_surface_tool.add_vertex(vertex)
		elif region_index == _island_region_index:
			for vertex in triangle_vertices:
				sub_surface_tool.add_vertex(vertex) 
		else:
			for vertex in triangle_vertices:
				ground_surface_tool.add_vertex(vertex)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	debug_surface_tool.generate_normals()
	
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
	debug_surface_tool.commit(self)
