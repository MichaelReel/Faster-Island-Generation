extends Stage

const PointLayer: GDScript = preload("geometry/PointLayer.gd")
const TriCellLayer: GDScript = preload("geometry/TriCellLayer.gd")
const GridMesh: GDScript = preload("mesh/GridMesh.gd")

var _data: TerrainData
var _meshes: TerrainMeshes

func _init(
	tri_side: float,
	points_per_row: int,
	material_lib: MaterialLib,
	terrain_data: TerrainData,
	terrain_meshes: TerrainMeshes,
) -> void:
	_data = terrain_data
	_meshes = terrain_meshes
	
	_data.grid_point_layer = PointLayer.new(tri_side, points_per_row)
	_data.grid_tri_cell_layer = TriCellLayer.new(_data.grid_point_layer, tri_side)
	_meshes.grid_mesh = GridMesh.new(_data.grid_point_layer, _data.grid_tri_cell_layer, material_lib)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_data.grid_point_layer.perform()
	emit_signal("percent_complete", self, 33.3)
	_data.grid_tri_cell_layer.perform()
	emit_signal("percent_complete", self, 66.6)
	_meshes.grid_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.GRID

func _to_string() -> String:
	return "Grid Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _meshes.grid_mesh
	}
