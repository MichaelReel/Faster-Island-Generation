class_name SettlementLayer
extends Object

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _settlement_cell_indices: PackedInt64Array

func _init(
	lake_layer: LakeLayer,
	region_cell_layer: RegionCellLayer,
	height_layer: HeightLayer, 
) -> void:
	_lake_layer = lake_layer
	_region_cell_layer = region_cell_layer
	_height_layer = height_layer

func perform() -> void:
	_locate_potential_settlements()

func _locate_potential_settlements() -> void:
	"""
	Find and record all the cells that are:
	- flat (level),
	- not in a water body
	- beside a water body
	"""
	# Get a list of regions that are lakes OR the sea
	var water_region_indices: PackedInt64Array = _lake_layer.get_lake_region_indices().duplicate()
	water_region_indices.append(_region_cell_layer.get_root_region_index())
	
	for cell_ind in range(_region_cell_layer.get_total_cell_count()):
		
		if not _cell_is_flat(cell_ind):
			continue
		var region_index: int = _region_cell_layer.get_region_index_for_cell(cell_ind)
		if region_index in water_region_indices:
			continue
		if not _cell_is_beside_region_in_list(cell_ind, water_region_indices):
			continue
		
		_settlement_cell_indices.append(cell_ind)

func _cell_is_flat(cell_ind: int) -> bool:
	var corner_indices: Array = Array(_region_cell_layer.get_triangle_as_point_indices(cell_ind))
	var heights: Array = corner_indices.map(
		func(point_index) -> float: return _height_layer.get_point_height(point_index)
	)
	
	return (
		heights[0] == heights[1]
		and heights[1] == heights[2]
	)

func _cell_is_beside_region_in_list(cell_index: int, region_indices: PackedInt64Array) -> bool:
	return Array(_region_cell_layer.get_edge_sharing_neighbours(cell_index)).any(
		func(neighbour_index): return _region_cell_layer.get_region_index_for_cell(neighbour_index) in region_indices
	)

func cell_is_potential_settlement(cell_ind: int) -> bool:
	return cell_ind in _settlement_cell_indices

func get_settlement_cell_indices() -> PackedInt64Array:
	return _settlement_cell_indices
