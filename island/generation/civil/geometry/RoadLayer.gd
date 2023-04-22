extends Object

const TriCellLayer: GDScript = preload("../../grid/geometry/TriCellLayer.gd")
const RegionCellLayer: GDScript = preload("../../region/geometry/RegionCellLayer.gd")
const LakeLayer: GDScript = preload("../../lakes/geometry/LakeLayer.gd")
const HeightLayer: GDScript = preload("../../height/geometry/HeightLayer.gd")
const RiverLayer: GDScript = preload("../../rivers/geometry/RiverLayer.gd")
const SettlementLayer: GDScript = preload("../geometry/SettlementLayer.gd")

const _NORMAL_COST: float = 1.0

var _tri_cell_layer: TriCellLayer
var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _settlement_layer: SettlementLayer
var _slope_penalty: float
var _river_penalty: float

var _cost_to_nearest_by_cell_index: Dictionary = {}  # Dictionary[int, float]
var _direction_to_destination_by_cell_index: Dictionary = {}  # Dictionary[int, int]
var _destination_cell_by_cell_index: Dictionary = {}  # Dictionary[int, int]
var _best_settlement_pair_cost: Dictionary = {}  # Dictionary[String, Dictionary{String, int | float}]
var _road_mid_points: PackedVector3Array = []
var _road_paths: Array[PackedInt32Array] = []
var _all_road_cell_indices: PackedInt32Array = []

func _init(
	tri_cell_layer: TriCellLayer,
	region_cell_layer: RegionCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
	settlement_layer: SettlementLayer,
	slope_penalty: float,
	river_penalty: float,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_lake_layer = lake_layer
	_height_layer = height_layer
	_river_layer = river_layer
	_settlement_layer = settlement_layer
	_slope_penalty = slope_penalty
	_river_penalty = river_penalty

func perform() -> void:
	_path_from_every_settlement()
	_record_all_road_cells()

func get_road_paths() -> Array[PackedInt32Array]:
	return _road_paths

func get_road_mid_point_vector3s() -> PackedVector3Array:
	return _road_mid_points

func get_shared_edge_as_point_indices(cell_a_index: int, cell_b_index: int) -> PackedInt32Array:
	"""Find the 2 points shared by these cells and return as an array"""
	var shared_point_indices: PackedInt32Array = []
	
	var cell_a_point_indices: PackedInt32Array = _tri_cell_layer.get_triangle_as_point_indices(cell_a_index)
	var cell_b_point_indices: PackedInt32Array = _tri_cell_layer.get_triangle_as_point_indices(cell_b_index)
	for cell in cell_a_point_indices:
		if cell in cell_b_point_indices:
			shared_point_indices.append(cell)
	
	if len(shared_point_indices) != 2:
		printerr("%d points shared between cells %d and %d (should be 2)" % [len(shared_point_indices), cell_a_index, cell_b_index])
	
	return shared_point_indices

func cell_has_road(cell_ind: int) -> bool:
	return cell_ind in _all_road_cell_indices

func _path_from_every_settlement() -> void:
	var water_region_indices: PackedInt32Array = _lake_layer.get_lake_region_indices().duplicate()
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
		for neighbour_cell_index in _tri_cell_layer.get_edge_sharing_neighbours(search_cell_index):
			var neighbour_region_index: int = _region_cell_layer.get_region_index_for_cell(neighbour_cell_index)
			if neighbour_region_index in water_region_indices:
				continue
			
			# Up the cost for each new step
			var journey_cost: float = _cost_to_nearest_by_cell_index[search_cell_index]
			journey_cost += _NORMAL_COST
			
			# Up the cost if crossing a river
			var edge_points: PackedInt32Array = get_shared_edge_as_point_indices(search_cell_index, neighbour_cell_index)
			if _river_layer.get_river_following_points(edge_points[0], edge_points[1]) >= 0:
				journey_cost += _river_penalty
			
			# Up the cost a little if going up/down a slope
			journey_cost += _height_layer.get_slope_by_cell_index(neighbour_cell_index) * _slope_penalty
			
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
		for neighbour_cell_index in _tri_cell_layer.get_edge_sharing_neighbours(search_cell_index):
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
		var road_path: PackedInt32Array = []
		_add_a_mid_point_vector_between_cells(cell_index_a, cell_index_b)

		# Work back to cell_a as origin
		var to_origin_index: int = cell_index_a
		while _direction_to_destination_by_cell_index[to_origin_index] != to_origin_index:
			road_path.append(to_origin_index)
			to_origin_index = _direction_to_destination_by_cell_index[to_origin_index]
		road_path.append(to_origin_index)
		road_path.reverse()

		# Work forward to cell_b as path destination
		var to_dest_index = cell_index_b
		while _direction_to_destination_by_cell_index[to_dest_index] != to_dest_index:
			road_path.append(to_dest_index)
			to_dest_index = _direction_to_destination_by_cell_index[to_dest_index]
		road_path.append(to_dest_index)
		_road_paths.append(road_path)

func _record_all_road_cells() -> void:
	for road_path in _road_paths:
		for cell_ind in road_path:
			if not cell_ind in _all_road_cell_indices:
				_all_road_cell_indices.append(cell_ind)

func _sort_by_cost(cell_index_a: int, cell_index_b: int) -> bool:
	return _cost_to_nearest_by_cell_index[cell_index_a] < _cost_to_nearest_by_cell_index[cell_index_b]

func _update_smallest_path_cost_table(cell_index_a: int, cell_index_b: int) -> void:
	var key: String = _get_cell_path_key(cell_index_a, cell_index_b)
	var total_cost: float = (
		_cost_to_nearest_by_cell_index[cell_index_a] + _cost_to_nearest_by_cell_index[cell_index_b]
	)
	var details: Dictionary = {"cell_a": cell_index_a, "cell_b": cell_index_b, "cost": total_cost}
	if not key in _best_settlement_pair_cost.keys():
		_best_settlement_pair_cost[key] = details
		return
	var current_cost: float = _best_settlement_pair_cost[key]["cost"]
	if total_cost < current_cost:
		_best_settlement_pair_cost[key] = details

func _get_cell_path_key(cell_index_a: int, cell_index_b: int) -> String:
	"""Get a key unique to the destination paths of the search cells, order should be unimportant"""
	return KeyUtils.get_combined_key(
		_destination_cell_by_cell_index[cell_index_a], _destination_cell_by_cell_index[cell_index_b]
	)

func _add_a_mid_point_vector_between_cells(cell_index_a: int, cell_index_b: int) -> void:
	var shared_edge: PackedInt32Array = get_shared_edge_as_point_indices(cell_index_a, cell_index_b)
	_road_mid_points.append(
		lerp(
			_tri_cell_layer.get_point_as_vector3(
				shared_edge[0], _height_layer.get_point_height(shared_edge[0])
			),
			_tri_cell_layer.get_point_as_vector3(
				shared_edge[1], _height_layer.get_point_height(shared_edge[1])
			),
			0.5
		)
	)
	
