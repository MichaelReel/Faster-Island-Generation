extends ArrayMesh
"""
Mesh for height map portion of the island generation
"""

const PointLayer: GDScript = preload("../../grid/geometry/PointLayer.gd")
const NoiseAddLayer: GDScript = preload("../geometry/NoiseAddLayer.gd")

var _point_layer: PointLayer
var _noise_add_layer: NoiseAddLayer
var _tri_side: float
var _bounds_side: float
var _upper_ground_cell_size: float
var _material_lib: MaterialLib

func _init(
	point_layer: PointLayer,
	noise_add_layer: NoiseAddLayer,
	tri_side: float,
	bounds_side: float,
	upper_ground_cell_size: float,
	material_lib: MaterialLib
) -> void:
	_point_layer = point_layer
	_noise_add_layer = noise_add_layer
	_tri_side = tri_side
	_bounds_side = bounds_side
	_upper_ground_cell_size = upper_ground_cell_size
	_material_lib = material_lib

func perform() -> void:
	var upper_ground_surface_tool: SurfaceTool = SurfaceTool.new()
	upper_ground_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_ground_surface_tool.set_material(_material_lib.get_material("ground"))
	
	var x_limit_bounds: float = (_tri_side * _bounds_side - 2 * _tri_side) * 0.5
	var z_limit_bounds: float = (_tri_side * _bounds_side - _tri_side) * 0.5
	var start_xz: Vector2 = Vector2(-x_limit_bounds, -z_limit_bounds)
	var end_xz: Vector2 =  Vector2(x_limit_bounds, z_limit_bounds)
	
	var z: float = start_xz.y
	while z < end_xz.y:
		var x: float = start_xz.x
		while x < end_xz.x:
			_add_quad_to_surface(upper_ground_surface_tool, x, z, _upper_ground_cell_size)
			x += _upper_ground_cell_size
		z += _upper_ground_cell_size
		
	upper_ground_surface_tool.generate_normals()
	upper_ground_surface_tool.commit(self)

func _add_quad_to_surface(surface_tool: SurfaceTool, x: float, z: float, size: float) -> void:
	var top_down_vertices: Array[Vector2] = [
		Vector2(x, z),
		Vector2(x + size, z),
		Vector2(x, z + size),
		Vector2(x + size, z + size),
	]
	var vertices: Array = top_down_vertices.map(
		func (xz: Vector2): return Vector3(xz.x, _noise_add_layer.get_height_at_xz(xz), xz.y)
	)
	
	surface_tool.add_vertex(vertices[0])
	surface_tool.add_vertex(vertices[1])
	surface_tool.add_vertex(vertices[2])
	
	surface_tool.add_vertex(vertices[1])
	surface_tool.add_vertex(vertices[3])
	surface_tool.add_vertex(vertices[2])
