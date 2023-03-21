class_name HeightMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _region_cell_layer: RegionCellLayer
var _root_region_index: int
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _material_lib: MaterialLib

func _init(
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer,
	material_lib: MaterialLib
) -> void:
	_region_cell_layer = regional_cell_layer
	_root_region_index = _region_cell_layer.get_root_region_index()
	_lake_layer = lake_layer
	_height_layer = height_layer
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	
	
	for cell_index in range(_region_cell_layer.get_total_cell_count()):
		var region_index: int = _region_cell_layer.get_region_by_index_for_cell_index(cell_index)
		var triangle_vertices = _height_layer.get_triangle_as_vector3_array_for_index_with_heights(cell_index)
		if region_index == _root_region_index:
			for vertex in triangle_vertices:
				sub_surface_tool.add_vertex(vertex)
		elif region_index in _lake_layer.get_lake_region_indices():
			for vertex in triangle_vertices:
				sub_surface_tool.add_vertex(vertex)
		else:
			for vertex in triangle_vertices:
				ground_surface_tool.add_vertex(vertex)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
