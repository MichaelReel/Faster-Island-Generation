class_name RoadLayer
extends Object

const _NORMAL_COST: float = 1.0

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _settlement_layer: SettlementLayer
var _slope_penalty: float
var _river_penalty: float

var _cost_to_nearest_by_cell_index: Dictionary = {}  # Dictionary[int, float]
var _direction_to_destination_by_cell_index: Dictionary = {}  # Dictionary[int, int]
var _destination_cell_by_cell_index: Dictionary = {}  # Dictionary[int, int]
var _best_settlement_pair_cost: Dictionary = {}  # Dictionary[String, Dictionary{String, int | float}]
var _road_mid_points: PackedInt64Array = []
var _road_paths: Array[PackedInt64Array] = []

func _init(
	lake_layer: LakeLayer,
	region_cell_layer: RegionCellLayer,
	height_layer: HeightLayer, 
	settlement_layer: SettlementLayer
) -> void:
	_lake_layer = lake_layer
	_region_cell_layer = region_cell_layer
	_height_layer = height_layer
	_settlement_layer = settlement_layer
	_slope_penalty = 2.5  # TODO: Set from args
	_river_penalty = 5.0  # TODO: Set from args

func perform() -> void:
	_path_from_every_settlement()

func get_road_paths() -> Array[PackedInt64Array]:
	return _road_paths

func get_road_mid_points() -> PackedInt64Array:
	return _road_mid_points

func _path_from_every_settlement() -> void:
	var water_region_indices: PackedInt64Array = _lake_layer.get_lake_region_indices().duplicate()
	water_region_indices.append(_region_cell_layer.get_root_region_index())
	
	var search_front: Array[int] = []  # Array because we'll want to sort, etc
	
	# Start by setting a search cell in each settlement with a zero score
	# No need to order yet, as all have the same cost
	for cell_index in _settlement_layer.get_settlement_cell_indices():
		_cost_to_nearest_by_cell_index[cell_index] = 0
		_direction_to_destination_by_cell_index[cell_index] = cell_index
		_destination_cell_by_cell_index[cell_index] = cell_index
		search_front.append(cell_index)

	# While there are still cells in the list of search cells,
	# Spread out from the settlements and score each cell by proximity 
	while not search_front.is_empty():
		var search_cell_index = search_front.pop_front()
		
		# Get neighbour cells to valid path
		for neighbour_cell_index in _region_cell_layer.get_edge_sharing_neighbours(search_cell_index):
			var neighbour_region_index: int = _region_cell_layer.get_region_index_for_cell(neighbour_cell_index)
			if neighbour_region_index in water_region_indices:
				continue
			
			# Up the cost for each new step
			var journey_cost: float = _cost_to_nearest_by_cell_index[search_cell_index]
			journey_cost += _NORMAL_COST
			
#			# Up the cost if crossing a river
#			var shared_edge = search_cell.get_triangle().get_shared_edge(neighbour_tri)
#			if shared_edge.has_river():
#				journey_cost += _river_penalty
			
			# Up the cost a little if going up/down a slope
			journey_cost += _get_slope_by_cell_index(neighbour_cell_index) * _slope_penalty
			
			# Check if this cell has been visited before
			if neighbour_cell_index in _cost_to_nearest_by_cell_index:
				# update it if cost is cheaper, and re-insert to front to propagate
				if _cost_to_nearest_by_cell_index[neighbour_cell_index] > journey_cost:
					_cost_to_nearest_by_cell_index[neighbour_cell_index] = journey_cost
					_direction_to_destination_by_cell_index[neighbour_cell_index] = search_cell_index
					_destination_cell_by_cell_index[neighbour_cell_index] = _destination_cell_by_cell_index[search_cell_index]
					
					# Remove and re-insert, but at an appropriate position in the queue
					if neighbour_cell_index in search_front:
						search_front.erase(neighbour_cell_index)
					var ind = search_front.bsearch_custom(neighbour_cell_index, _sort_by_cost)
					search_front.insert(ind, neighbour_cell_index)
				continue
			
			# Insert a new search cell into the queue, sorted by journey cost
			_cost_to_nearest_by_cell_index[neighbour_cell_index] = journey_cost
			_direction_to_destination_by_cell_index[neighbour_cell_index] = search_cell_index
			_destination_cell_by_cell_index[neighbour_cell_index] = _destination_cell_by_cell_index[search_cell_index]
			var ind = search_front.bsearch_custom(neighbour_cell_index, _sort_by_cost)
			search_front.insert(ind, neighbour_cell_index)
	
	# Of all the search cells, find all the best search cell pairs that link any 2 settlements
	for search_cell_index in _cost_to_nearest_by_cell_index.keys():
		for neighbour_cell_index in _region_cell_layer.get_edge_sharing_neighbours(search_cell_index):
			# If neighbour cell isn't tracked, it's not a valid path
			if not neighbour_cell_index in _cost_to_nearest_by_cell_index.keys():
				continue
			# For now, lets skip cells pairs in settlements
			if (
				_cost_to_nearest_by_cell_index[search_cell_index] == 0.0 
				or _cost_to_nearest_by_cell_index[neighbour_cell_index] == 0.0
			):
				continue
			
			# Skip pairs of cells that point to the same destination
			if (
				_destination_cell_by_cell_index[search_cell_index]
				== _destination_cell_by_cell_index[neighbour_cell_index]
			):
				continue
			
			# Submit this cell pair for evaluation
			_update_smallest_path_cost_table(search_cell_index, neighbour_cell_index)

	# Create the paths from all the best settlement meetings we cound find
	for path_details in _best_settlement_pair_cost.values():
		var cell_index_a: int = path_details["cell_a"]
		var cell_index_b: int = path_details["cell_b"]
		var road_path: PackedInt64Array = []
		_road_mid_points.append(cell_index_a)

		# Work back to cell_a as origin
		var to_origin_index: int = cell_index_a
		while _direction_to_destination_by_cell_index[to_origin_index] != to_origin_index:
			road_path.append(to_origin_index)
			to_origin_index = _direction_to_destination_by_cell_index[to_origin_index]
		road_path.reverse()

		# Work forward to cell_b as path destination
		var to_dest_index = cell_index_b
		while _direction_to_destination_by_cell_index[to_dest_index] != to_dest_index:
			road_path.append(to_dest_index)
			to_dest_index = _direction_to_destination_by_cell_index[to_dest_index]

		_road_paths.append(road_path)

func _sort_by_cost(cell_index_a: int, cell_index_b: int) -> bool:
	return _cost_to_nearest_by_cell_index[cell_index_a] < _cost_to_nearest_by_cell_index[cell_index_b]

func _get_slope_by_cell_index(cell_index: int) -> float:
	"""
	Not a real slope calculation, just return the difference in height
	between the lowest and highest of the 3 corners of the cell
	"""
	var heights: Array = Array(
		_region_cell_layer.get_triangle_as_point_indices(cell_index)
	).map(func(point_index): return _height_layer.get_point_height(point_index))
	heights.sort()
	return heights[2] - heights[0]

func _update_smallest_path_cost_table(cell_index_a: int, cell_index_b: int) -> void:
	var key: String = _get_cell_path_key(cell_index_a, cell_index_b)
	var total_cost: float = _cost_to_nearest_by_cell_index[cell_index_a] + _cost_to_nearest_by_cell_index[cell_index_b]
	var details: Dictionary = {"cell_a": cell_index_a, "cell_b": cell_index_b, "cost": total_cost}
	if not key in _best_settlement_pair_cost.keys():
		_best_settlement_pair_cost[key] = details
		return
	var current_cost: float = _best_settlement_pair_cost[key]["cost"]
	if total_cost < current_cost:
		_best_settlement_pair_cost[key] = details

func _get_cell_path_key(cell_index_a: int, cell_index_b: int) -> String:
	"""Get a key unique to the destination paths of the search cells, order should be unimportant"""
	return "%d:%d" % ([cell_index_a, cell_index_b] if cell_index_a < cell_index_b else [cell_index_b, cell_index_a])
