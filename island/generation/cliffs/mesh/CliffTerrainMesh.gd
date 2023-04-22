extends ArrayMesh
"""
Mesh for height map portion of the island generation, including cliff tops
"""

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const RegionCellLayer: GDScript = preload("../../region/geometry/RegionCellLayer.gd")
const LakeLayer: GDScript = preload("../../lakes/geometry/LakeLayer.gd")
const CliffLayer: GDScript = preload("../geometry/CliffLayer.gd")

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _root_region_index: int
var _lake_layer: LakeLayer
var _cliff_layer: CliffLayer
var _material_lib: MaterialLib

func _init(
	tri_cell_layer: TriCellLayer,
	regional_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	cliff_layer: CliffLayer,
	material_lib: MaterialLib
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = regional_cell_layer
	_root_region_index = _region_cell_layer.get_root_region_index()
	_lake_layer = lake_layer
	_cliff_layer = cliff_layer
	_material_lib = material_lib

func perform() -> void:
	var sub_surface_tool: SurfaceTool = SurfaceTool.new()
	var ground_surface_tool: SurfaceTool = SurfaceTool.new()
	var cliff_surface_tool: SurfaceTool = SurfaceTool.new()
	
	sub_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	cliff_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	sub_surface_tool.set_material(_material_lib.get_material("sub_water"))
	ground_surface_tool.set_material(_material_lib.get_material("ground"))
	cliff_surface_tool.set_material(_material_lib.get_material("cliff"))
	
	_create_updated_terrain(sub_surface_tool, ground_surface_tool)
	_create_cliff_faces(cliff_surface_tool)
	
	sub_surface_tool.generate_normals()
	ground_surface_tool.generate_normals()
	cliff_surface_tool.generate_normals()
	
	sub_surface_tool.commit(self)
	ground_surface_tool.commit(self)
	cliff_surface_tool.commit(self)


func _create_updated_terrain(sub_surface_tool: SurfaceTool, ground_surface_tool: SurfaceTool) -> void:
	for cell_index in range(_tri_cell_layer.get_total_cell_count()):
		var region_index: int = _region_cell_layer.get_region_index_for_cell(cell_index)
		var triangle_point_indices = _tri_cell_layer.get_triangle_as_point_indices(cell_index)
		
#		var triangle_vertices = _height_layer.get_triangle_as_vector3_array_for_index_with_heights(cell_index)
		
		if region_index == _root_region_index:
			for point_ind in triangle_point_indices:
				var vertex: Vector3 = _tri_cell_layer.get_point_as_vector3(
					point_ind, _cliff_layer.get_height_from_cell_and_point_indices(cell_index, point_ind)
				)
				sub_surface_tool.add_vertex(vertex)
		elif region_index in _lake_layer.get_lake_region_indices():
			for point_ind in triangle_point_indices:
				var vertex: Vector3 = _tri_cell_layer.get_point_as_vector3(
					point_ind, _cliff_layer.get_height_from_cell_and_point_indices(cell_index, point_ind)
				)
				sub_surface_tool.add_vertex(vertex)
		else:
			for point_ind in triangle_point_indices:
				var vertex: Vector3 = _tri_cell_layer.get_point_as_vector3(
					point_ind, _cliff_layer.get_height_from_cell_and_point_indices(cell_index, point_ind)
				)
				ground_surface_tool.add_vertex(vertex)

func _create_cliff_faces(cliff_surface_tool: SurfaceTool) -> void:
	var cliff_lines: Array[PackedInt32Array] = _cliff_layer.get_cliff_base_lines()
	for cliff_index in range(len(cliff_lines)):
		# Get cliff point information, grid position and both heights
		var cliff_point_indices: PackedInt32Array = cliff_lines[cliff_index]
		var cliff_evelvation_references: Array[PackedFloat32Array] = (
			_cliff_layer.get_cliff_elevation_lines(cliff_index)
		)
		var base_heights: PackedFloat32Array = cliff_evelvation_references[0]
		var top_heights: PackedFloat32Array = cliff_evelvation_references[1]
		
		# TODO: Reverse chains as necessary
		
		# Draw triangle pairs between the top and bottoms of the cliff section
		for cliff_sequence_index in range(len(cliff_point_indices) - 1):
			var point_index_a = cliff_point_indices[cliff_sequence_index]
			var point_index_b = cliff_point_indices[cliff_sequence_index + 1]
			_get_cliff_faces_for_vertices(
				cliff_surface_tool,
				_tri_cell_layer.get_point_as_vector3(point_index_a, top_heights[cliff_sequence_index]),
				_tri_cell_layer.get_point_as_vector3(point_index_b, top_heights[cliff_sequence_index + 1]),
				_tri_cell_layer.get_point_as_vector3(point_index_a, base_heights[cliff_sequence_index]),
				_tri_cell_layer.get_point_as_vector3(point_index_b, base_heights[cliff_sequence_index + 1]),
			)

func _get_cliff_faces_for_vertices(
	cliff_surface_tool: SurfaceTool,
	top_a: Vector3,
	top_b: Vector3,
	bottom_a: Vector3,
	bottom_b: Vector3,
) -> void:
	# When the first or last points match, we only need a single triangle
	if top_a == bottom_a:
		cliff_surface_tool.add_vertex(top_a)
		cliff_surface_tool.add_vertex(top_b)
		cliff_surface_tool.add_vertex(bottom_b)
		return
	
	if top_b == bottom_b:
		cliff_surface_tool.add_vertex(top_a)
		cliff_surface_tool.add_vertex(top_b)
		cliff_surface_tool.add_vertex(bottom_a)
		return
	
	cliff_surface_tool.add_vertex(top_a)
	cliff_surface_tool.add_vertex(top_b)
	cliff_surface_tool.add_vertex(bottom_a)
	
	cliff_surface_tool.add_vertex(top_b)
	cliff_surface_tool.add_vertex(bottom_b)
	cliff_surface_tool.add_vertex(bottom_a)
