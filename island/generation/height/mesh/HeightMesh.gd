class_name HeightMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _island_region_index: int
var _height_layer: HeightLayer
var _material_lib: MaterialLib

func _init(
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	island_region_index: int,
	height_layer: HeightLayer,
	material_lib: MaterialLib
) -> void:
	_region_cell_layer = regional_cell_layer
	_lake_layer = lake_layer
	_island_region_index = island_region_index
	_height_layer = height_layer
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	var lake_surface_tool: SurfaceTool = SurfaceTool.new()
	var debug_surface_tool: SurfaceTool = SurfaceTool.new()
	
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	lake_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	debug_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	lake_surface_tool.set_material(_material_lib.get_material("lake_debug"))
	debug_surface_tool.set_material(_material_lib.get_material("region_debug"))
	
	
	for cell_index in range(_region_cell_layer.get_cell_count()):
		var region_index: int = _region_cell_layer.get_region_by_index_for_cell_index(cell_index)
		var triangle_vertices = _height_layer.get_triangle_as_vector3_array_for_index_with_heights(cell_index)
		if len(_region_cell_layer.get_region_fronts_by_cell_index(cell_index)) > 0:
			for vertex in triangle_vertices:
				debug_surface_tool.add_vertex(vertex)
		elif region_index == _island_region_index:
			for vertex in triangle_vertices:
				sub_surface_tool.add_vertex(vertex)
		elif region_index in _lake_layer.get_lake_region_indices():
			for vertex in triangle_vertices:
				lake_surface_tool.add_vertex(vertex)
		else:
			for vertex in triangle_vertices:
				ground_surface_tool.add_vertex(vertex)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	lake_surface_tool.generate_normals()
	debug_surface_tool.generate_normals()
	
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
	lake_surface_tool.commit(self)
	debug_surface_tool.commit(self)
