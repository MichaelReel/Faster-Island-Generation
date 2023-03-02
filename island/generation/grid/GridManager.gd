class_name GridManager
extends Stage

var _point_layer: PointLayer
var _edge_layer: EdgeLayer
var _tri_cell_layer: TriCellLayer
var _grid_mesh: GridMesh

func _init(tri_side: float, points_per_row: int) -> void:
	_point_layer = PointLayer.new(tri_side, points_per_row)
	_edge_layer = EdgeLayer.new(_point_layer)
	_tri_cell_layer = TriCellLayer.new(_point_layer, _edge_layer)
	_grid_mesh = GridMesh.new(_point_layer, _tri_cell_layer)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_point_layer.perform()
	emit_signal("percent_complete", self, 25.0)
	_edge_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_tri_cell_layer.perform()
	emit_signal("percent_complete", self, 75.0)
	_grid_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Grid Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _grid_mesh
	}
