class_name GridManager
extends Stage

var _point_layer: PointLayer
var _edge_layer: EdgeLayer
var _tri_cell_layer: TriCellLayer

func _init(tri_side: float, points_per_row: int) -> void:
	_point_layer = PointLayer.new(tri_side, points_per_row)
	_edge_layer = EdgeLayer.new(_point_layer)
	_tri_cell_layer = TriCellLayer.new(_point_layer, _edge_layer)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_point_layer.perform()
	emit_signal("percent_complete", self, 33.3)
	_edge_layer.perform()
	emit_signal("percent_complete", self, 66.0)
	_tri_cell_layer.perform()
	emit_signal("percent_complete", self, 100.0)
