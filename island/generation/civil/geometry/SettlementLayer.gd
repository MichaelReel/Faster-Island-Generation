class_name SettlementLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _settlement_spread: int
var _settlement_cell_indices: PackedInt32Array

func _init(
	tri_cell_layer: TriCellLayer,
	region_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer, 
	settlement_spread: int,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_lake_layer = lake_layer
	_height_layer = height_layer
	_settlement_spread = settlement_spread

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
	var water_region_indices: PackedInt32Array = _lake_layer.get_lake_region_indices().duplicate()
	water_region_indices.append(_region_cell_layer.get_root_region_index())
	
	for cell_ind in _lake_layer.get_non_water_body_cell_indices():
		# Only accept plain areas for settlements
		if not _cell_is_flat(cell_ind):
			continue
		# But only accept settlements near to water
		if not _cell_is_beside_region_in_list(cell_ind, water_region_indices):
			continue
		# Don't have settlements too close to other settlements
		var skip: bool = false
		for other_cell in _settlement_cell_indices:
			var cell_distance: int = _get_cell_distance_between_cells_by_indices(cell_ind, other_cell)
			if cell_distance <= _settlement_spread:
				skip = true
				break
		if skip:
			continue
		
		_settlement_cell_indices.append(cell_ind)

func _cell_is_flat(cell_ind: int) -> bool:
	var corner_indices: Array = Array(_tri_cell_layer.get_triangle_as_point_indices(cell_ind))
	var heights: Array = corner_indices.map(
		func(point_index) -> float: return _height_layer.get_point_height(point_index)
	)
	
	return (
		heights[0] == heights[1]
		and heights[1] == heights[2]
	)

func _cell_is_beside_region_in_list(cell_index: int, region_indices: PackedInt32Array) -> bool:
	return Array(_tri_cell_layer.get_edge_sharing_neighbours(cell_index)).any(
		func(neighbour_index): return _region_cell_layer.get_region_index_for_cell(neighbour_index) in region_indices
	)

func _get_cell_distance_between_cells_by_indices(cell_ind: int, other_cell: int) -> int:
	"""
	Calculate the number of edges that would have to be crossed 
	to traverse from one cell to another
	"""
	var pos_a: Vector2i = _tri_cell_layer.get_tri_cell_vector2i_for_index(cell_ind)
	var pos_b: Vector2i = _tri_cell_layer.get_tri_cell_vector2i_for_index(other_cell)
	var vert_diff = abs(pos_a.x - pos_b.x)
	var hort_diff = abs(pos_a.y - pos_b.y)
	
	# Most of the time the distance is just the dx and dy, as long as dx is equal or greater than dy
	if vert_diff >= hort_diff:
		return vert_diff + hort_diff
	
	# Depending on the polarity of the start an finish (details in TriangleGridDistance.md)
	# Apply some special rules to allow for the orientation of the start and end triangles
	
	var odd_ax: bool = (pos_a.x % 2 == 1)
	var even_ax: bool = (pos_a.x % 2 == 0)
	var even_ay: bool = (pos_a.y % 2 == 0)
	var odd_bx: bool = (pos_b.x % 2 == 1)
	var even_bx: bool = (pos_b.x % 2 == 0)
	var even_by: bool = (pos_b.y % 2 == 0)
	
	# 100% certain this can be greatly improved, but for now, this works
	if even_ay:
		if even_by:
			if even_ax and odd_bx:
				return hort_diff * 2 + 1
			if odd_ax and even_bx:
				return hort_diff * 2 - 1
		
		else:
			if even_ax and even_bx:
				return hort_diff * 2 + 1
			if odd_ax and odd_bx:
				return hort_diff * 2 - 1
	
	else:
		if even_by:
			if odd_ax and odd_bx:
				return hort_diff * 2 + 1
			if even_ax and even_bx:
				return hort_diff * 2 - 1
		
		else:
			if odd_ax and even_bx:
				return hort_diff * 2 + 1
			if even_ax and odd_bx:
				return hort_diff * 2 - 1
	
	# If non of the other special rules applied, then apply the last special rull
	return hort_diff * 2

func cell_is_potential_settlement(cell_ind: int) -> bool:
	return cell_ind in _settlement_cell_indices

func get_settlement_cell_indices() -> PackedInt32Array:
	return _settlement_cell_indices
