class_name CliffLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _lake_layer: LakeLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _road_layer: RoadLayer
var _min_slope: float
var _cliff_max_height: float
var _point_cliff_top_cell_map: Dictionary = {}  # Dictionary[int, PackedInt32Array]
var _cliff_base_chains: Array[PackedInt32Array] = []
var _cliff_base_elevations: Array[PackedFloat32Array] = []
var _cliff_top_elevations: Array[PackedFloat32Array] = []
var _cell_and_point_to_cliff_top_height: Dictionary = {}  # Dictionary[String, float]

func _init(
	tri_cell_layer: TriCellLayer,
	lake_layer: LakeLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
	road_layer: RoadLayer,
	min_slope: float,
	cliff_max_height: float,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_lake_layer = lake_layer
	_height_layer = height_layer
	_river_layer = river_layer
	_road_layer = road_layer
	_min_slope = min_slope
	_cliff_max_height = cliff_max_height

func perform() -> void:
	_get_all_the_cliff_base_chains()
	_split_grid_along_cliff_lines()
	_record_deviations_from_height_layer()

func get_cliff_base_lines() -> Array[PackedInt32Array]:
	"""
	Return all the cliff point indices as an array of point_index arrays
	The index of each sub array in the returned array can be considered to be the `cliff_index`
	"""
	return _cliff_base_chains

func get_cliff_elevation_lines(cliff_index: int) -> Array[PackedFloat32Array]:
	"""Return the base and top elevations for the given cliff index"""
	return [_cliff_base_elevations[cliff_index], _cliff_top_elevations[cliff_index]]

func get_height_from_cell_and_point_indices(cell_ind: int , point_ind: int) -> float:
	var key = KeyUtils.key_for_cell_and_point(cell_ind, point_ind)
	if key in _cell_and_point_to_cliff_top_height:
		return _cell_and_point_to_cliff_top_height[key]
	return _height_layer.get_point_height(point_ind)

func _get_all_the_cliff_base_chains() -> void:
	"""
	Identify and record likely places we can extend the landscape to create cliffs
	Scan the above water cells for steep faces
	Find chains of steep faces that don't cross roads, rivers
	"""
	var cliff_edges_keys_to_array: Dictionary = {}  # Dictionary[String, PackedInt32Array]
	for cell_ind in _lake_layer.get_non_water_body_cell_indices():
		var slope_height_diff: float = _height_layer.get_slope_by_cell_index(cell_ind)
		# Only include cells that have a given minimum height difference (slope)
		if slope_height_diff < _min_slope:
			continue
		
		var point_indices_in_height_order: PackedInt32Array = (
			_height_layer.get_cell_as_point_indices_ordered_by_height(cell_ind)
		)
		# If only 1 point is low enough to touch the cliff, mark it
		if _height_layer.get_lower_edge_slope_by_cell_index(cell_ind) > (slope_height_diff * 0.5):
			_put_cliff_point_top_cell(point_indices_in_height_order[0], cell_ind)
			continue
		
		if _road_layer.cell_has_road(cell_ind):
			# Ignore cells with roads
			continue
		
		if _river_layer.cell_touches_river(cell_ind):
			# Ignore cells with rivers
			continue

		# Include the bottom edges of steep slopes
		var lower_edge_as_point_indices: PackedInt32Array = point_indices_in_height_order.slice(0,2)
		var edge_as_ordered_key: String = KeyUtils.get_combined_key_for_int32_array(lower_edge_as_point_indices)
		# remove *all* duplicate copies,
		# this prevents infinite looping when finding linked ridges later
		if edge_as_ordered_key in cliff_edges_keys_to_array:
			cliff_edges_keys_to_array.erase(edge_as_ordered_key)
		else:
			cliff_edges_keys_to_array[edge_as_ordered_key] = lower_edge_as_point_indices
			# Map the edge points to the cliff TOP cell
			_put_cliff_point_top_cell(lower_edge_as_point_indices[0], cell_ind)
			_put_cliff_point_top_cell(lower_edge_as_point_indices[1], cell_ind)
	
	# Find all the cliff chains
	var chains: Array[PackedInt32Array] = CliffLayer._extract_chains_from_edges(cliff_edges_keys_to_array)

	for chain in chains:
		# Don't keep any chains that are too short to draw
		if len(chain) <= 3:
			continue
		
		# Which cliff top cell do both points belong to?
		var cell_indices: Array = Array(_point_cliff_top_cell_map[chain[0]]).filter(
			func (cell_ind: int): return cell_ind in _point_cliff_top_cell_map[chain[1]]
		)
		if len(cell_indices) != 1:
			printerr("Can't find single cliff top cell sharing points %d and %d (found %s)" % [chain[0], chain[1], cell_indices])
		var cell_index: int = cell_indices[0]
		
		# Do the first 2 points go "clockwise" or "anticlockwise" along the top of cliff cell?
		var cell_rotation = _tri_cell_layer.get_rotation_direction_around_cell(chain[0], chain[1], cell_index)
		
		# Reverse any chains that orient the wrong way to keep faces outwards
		if cell_rotation == 1:
			chain.reverse()
		
		_cliff_base_chains.append(chain)

func _put_cliff_point_top_cell(point_ind: int, cell_ind: int) -> void:
	if point_ind in _point_cliff_top_cell_map.keys():
		_point_cliff_top_cell_map[point_ind].append(cell_ind)
	else:
		_point_cliff_top_cell_map[point_ind] = PackedInt32Array([cell_ind])

func _split_grid_along_cliff_lines() -> void:
	"""
	Separate the grid where the cliffs are located
	"""
	for cliff_chain in _cliff_base_chains:
		_split_grid_along_cliff_line(cliff_chain)

func _split_grid_along_cliff_line(cliff_chain: PackedInt32Array) -> void:
	"""
	Create a set of new heights for the tops of the cliffs,
	these should be made discoverable by referencing the combination of cell and point
	"""
	var cliff_bottom_heights = PackedFloat32Array(
		Array(cliff_chain).map(
			func (point_ind: int): return _height_layer.get_point_height(point_ind)
		)
	)
	var cliff_top_heights: PackedFloat32Array = []
	var cliff_length: int = len(cliff_chain)
	for cliff_index in range(cliff_length):
		if cliff_index == 0 or cliff_index == cliff_length - 1:
			# Just set the ends to the same height as the bottoms
			# The algoritm below might hav got close, but just to avoid float precision errors
			cliff_top_heights.append(cliff_bottom_heights[cliff_index])
			continue
		
		# To work out the cliff "curve" the following algorithm will give a reasonable curve:
		# https://www.desmos.com/calculator/lajhzxtfl0
		# height = cos( PI * (x - length * 0.5) / length ) * max_height
		var length = cliff_length - 1
		var cliff_height = cos(PI * (cliff_index - 0.5 * length) / length) * _cliff_max_height
		cliff_top_heights.append(cliff_bottom_heights[cliff_index] + cliff_height)
		
	_cliff_base_elevations.append(cliff_bottom_heights)
	_cliff_top_elevations.append(cliff_top_heights)

func _record_deviations_from_height_layer() -> void:
	"""Make it easy to get the correct height for a given cell and corner point"""
	# _cell_and_point_to_cliff_top_height

	# Go through all the cliff points
	for cliff_index in range(len(_cliff_base_chains)):
		var cliff_point_indices: PackedInt32Array = _cliff_base_chains[cliff_index]
		for cliff_sequence_ind in range(len(cliff_point_indices)):
			var cliff_point_ind: int = cliff_point_indices[cliff_sequence_ind]
			# Make a record of the cells connected by top points
			if cliff_point_ind in _point_cliff_top_cell_map:
				for point_cell_ind in _point_cliff_top_cell_map[cliff_point_ind]:
					var key = KeyUtils.key_for_cell_and_point(point_cell_ind, cliff_point_ind)
					_cell_and_point_to_cliff_top_height[key] = (
						_cliff_top_elevations[cliff_index][cliff_sequence_ind]
					)

static func _extract_chains_from_edges(cliff_edges_keys_to_array: Dictionary) -> Array[PackedInt32Array]: 
	# (cliff_edges_keys_to_array: Dictionary[String, PackedInt32Array])
	"""
	Given an dictionary of unordered Edges
	Return an array, each element of which is an array of Edges ordered by connection.
	"""
	# TODO: Add to doc if: This is destructive and will leave the input dictionary empty.
	
	# Re-index the edges dictionary as a search dictionary of points to keys
	var point_indices_to_edge_keys: Dictionary = {}  # Dictionary[int, Array[String]]
	var all_edge_keys: Array = cliff_edges_keys_to_array.keys().duplicate()  # Array[String]
	for edge_key in all_edge_keys:
		var edge: PackedInt32Array = cliff_edges_keys_to_array[edge_key]
		for point_ind in edge:
			if point_ind in point_indices_to_edge_keys:
				point_indices_to_edge_keys[point_ind].append(edge_key)
			else:
				point_indices_to_edge_keys[point_ind] = [edge_key]
	
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array[PackedInt32Array] = []
	while not all_edge_keys.is_empty():
		# Setup the next chain, pick the end of a line
		var chain_done = false
		var chain_flipped = false
		var chain: PackedInt32Array = []
		var next_chain_edge_key: String = all_edge_keys.pop_back()
		var next_chain_edge: PackedInt32Array = cliff_edges_keys_to_array[next_chain_edge_key]
		var start_chain_point_ind: int = next_chain_edge[0]
		var next_chain_point_ind: int = next_chain_edge[1]
		
		# Follow the lines until we run out of edges
		chain.append(start_chain_point_ind)
		while not chain_done:
			chain.append(next_chain_point_ind)
			
			# Along which edge can we go from this point?
			# - excluding current edge and 
			# - including unvisited edges
			var connection_edge_keys: Array = point_indices_to_edge_keys[next_chain_point_ind].filter(
				func (key: String): return key != next_chain_edge_key and key in all_edge_keys
			)
			
			# If there's too many ways to go, something probably went wrong
			if len(connection_edge_keys) > 1:
				printerr("Error: Too many available directions! ")
			
			# If there's only one way to go, go that way
			elif len(connection_edge_keys) == 1:
				next_chain_edge_key = connection_edge_keys.front()
				next_chain_edge = cliff_edges_keys_to_array[next_chain_edge_key]
				next_chain_point_ind = (
					next_chain_edge[0]
					if next_chain_point_ind != next_chain_edge[0]
					else next_chain_edge[1]
				)
				all_edge_keys.erase(next_chain_edge_key)
			
			else:
				# There are no ways to go
				if chain_flipped:
					# This chain has previously been flipped, both ends are now found
					# Push this chain back into the output list
					chains.append(chain)
					chain_done = true
					continue
				
				# One end has been found, so flip it around and go the other way
				chain.reverse()
				var last_2_keys: PackedInt32Array = chain.slice(-2)
				next_chain_edge_key = KeyUtils.get_combined_key_for_int32_array(last_2_keys)
				next_chain_edge = cliff_edges_keys_to_array[next_chain_edge_key]
				next_chain_point_ind = chain[-1]
				chain.remove_at(len(chain)-1)
				chain_flipped = true
	
	return chains
