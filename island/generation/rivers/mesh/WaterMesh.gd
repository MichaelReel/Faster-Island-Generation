extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const RegionCellLayer: GDScript = preload("../../region/geometry/RegionCellLayer.gd")
const LakeLayer: GDScript = preload("../../lakes/geometry/LakeLayer.gd")
const HeightLayer: GDScript = preload("../../height/geometry/HeightLayer.gd")
const RiverLayer: GDScript = preload("../geometry/RiverLayer.gd")

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
	material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
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
	var surface_drop = 0.05
	var surface_tool: SurfaceTool = SurfaceTool.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("water_surface"))
	
	for cell_index in _river_layer.get_river_adjacent_cell_indices(river_index):
		for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_index):
			# Set the normal river height to below the uneroded height, but above the terrain
			var height: float = _height_layer.get_point_height(point_index)
			height += _river_layer.get_point_eroded_depth(point_index)
			height -= surface_drop
			
			# If point is on the edge of a water body, draw at the uneroded height
			if point_index in _river_layer.get_all_water_body_point_indices():
				height = _height_layer.get_point_height(point_index)
				height += _river_layer.get_point_eroded_depth(point_index)
			
			surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(point_index, height))

	surface_tool.generate_normals()
	surface_tool.commit(self)

func _create_lake_mesh(lake_region_index: int) -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(_material_lib.get_material("water_surface"))
	for cell_index in _region_cell_layer.get_region_cell_indices_by_region_index(lake_region_index):
		var lake_height: float = _lake_layer.get_lake_height_by_region_index(lake_region_index)
		for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_index):
			surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(point_index, lake_height))
	
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
		for point_index in _tri_cell_layer.get_triangle_as_point_indices(cell_index):
			surface_tool.add_vertex(_tri_cell_layer.get_point_as_vector3(point_index, sea_level_height))
	
	surface_tool.generate_normals()
	surface_tool.commit(self)
