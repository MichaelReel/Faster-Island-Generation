extends Stage

const PointLayer: GDScript = preload("geometry/PointLayer.gd")
const TriCellLayer: GDScript = preload("geometry/TriCellLayer.gd")
const GridMesh: GDScript = preload("mesh/GridMesh.gd")

var _point_layer: PointLayer
var _tri_cell_layer: TriCellLayer
var _grid_mesh: GridMesh

func _init(tri_side: float, points_per_row: int, material_lib: MaterialLib) -> void:
	_point_layer = PointLayer.new(tri_side, points_per_row)
	_tri_cell_layer = TriCellLayer.new(_point_layer, tri_side)
	_grid_mesh = GridMesh.new(_point_layer, _tri_cell_layer, material_lib)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_point_layer.perform()
	emit_signal("percent_complete", self, 33.3)
	_tri_cell_layer.perform()
	emit_signal("percent_complete", self, 66.6)
	_grid_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func get_progess_step() -> GlobalStageProgressStep:
	return Stage.GlobalStageProgressStep.GRID

func _to_string() -> String:
	return "Grid Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _grid_mesh
	}

func get_point_layer() -> PointLayer:
	return _point_layer

func get_tri_cell_layer() -> TriCellLayer:
	return _tri_cell_layer
