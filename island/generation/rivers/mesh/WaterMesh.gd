class_name WaterMesh
extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _material_lib: MaterialLib

func _init(
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
	material_lib: MaterialLib
) -> void:
	_region_cell_layer = regional_cell_layer
	_lake_layer = lake_layer
	_height_layer = height_layer
	_river_layer = river_layer
	_material_lib = material_lib

func perform() -> void:
	_create_sea_body_mesh()
	
	for lake_index in _lake_layer.get_lake_region_indices():
		_create_lake_mesh(lake_index)
	
	for river_index in range(_river_layer.get_total_river_count()):
		_create_river_surface_mesh(river_index)

func _create_river_surface_mesh(river_index: int) -> void:
	var midstream_point_indices: PackedInt64Array = _river_layer.get_river_midstream_point_indices_by_index(river_index)
	var ratio = 0.75
	var surface_tool: SurfaceTool = SurfaceTool.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("water_surface"))
	
	for pos_down_river in range(len(midstream_point_indices)):
		var point_index: int = midstream_point_indices[pos_down_river]
		var drop_depth: Vector3 = Vector3.DOWN * _river_layer.get_point_eroded_depth(point_index) * ratio
		# Ignore the drop depth if this is an end point at a water body
		if (
			(pos_down_river == 0 and _river_layer.river_starts_at_lake(river_index)) 
			or pos_down_river == len(midstream_point_indices) - 1
		):
			drop_depth = Vector3.ZERO
		
		

#	for triangle in river.get_adjacent_triangles():
#		for vertex in triangle.get_vertices():
#			if lake_stage.point_in_water_body(vertex):
#				surface_tool.add_vertex(vertex.get_uneroded_vector())
#			else:
#				surface_tool.add_vertex(vertex.get_uneroded_vector() + drop_depth)

	surface_tool.generate_normals()
	surface_tool.commit(self)

func _create_lake_mesh(lake_region_index: int) -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("water_surface"))
	for cell_index in _region_cell_layer.get_region_cell_indices_by_region_index(lake_region_index):
		var lake_height: float = _lake_layer.get_lake_height_by_region_index(lake_region_index)
		for point_index in _region_cell_layer.get_triangle_as_point_indices(cell_index):
			surface_tool.add_vertex(_region_cell_layer.get_point_as_vector3(point_index, lake_height))
	
	surface_tool.generate_normals()
	surface_tool.commit(self)

func _create_sea_body_mesh() -> void:
	var sea_level_height: float = 0.0
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("water_surface"))
	
	for cell_index in _region_cell_layer.get_region_cell_indices_by_region_index(
		_region_cell_layer.get_root_region_index()
	):
		for point_index in _region_cell_layer.get_triangle_as_point_indices(cell_index):
			surface_tool.add_vertex(_region_cell_layer.get_point_as_vector3(point_index, sea_level_height))
	
	surface_tool.generate_normals()
	surface_tool.commit(self)
