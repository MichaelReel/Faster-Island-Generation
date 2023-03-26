class_name IslandOutlineMesh
extends ArrayMesh

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _material_lib: MaterialLib
var _island_outline_layer: IslandOutlineLayer

func _init(
	tri_cell_layer: TriCellLayer, region_cell_layer: RegionCellLayer, island_outline_layer: IslandOutlineLayer, material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_island_outline_layer = island_outline_layer
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	
	for cell_index in range(_tri_cell_layer.get_total_cell_count()):
		var surface_tool = sub_surface_tool
		
		var region_index = _region_cell_layer.get_region_index_for_cell(cell_index)
		if region_index == _island_outline_layer.get_island_region_index():
			surface_tool = ground_surface_tool
		
		var triangle_vertices = _tri_cell_layer.get_triangle_as_vector3_array_for_index(cell_index)
		for vertex in triangle_vertices:
			surface_tool.add_vertex(vertex)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
