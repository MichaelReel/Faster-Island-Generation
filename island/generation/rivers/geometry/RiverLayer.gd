class_name RiverLayer
extends Object

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _river_count: int
var _erode_depth: float
var _rng := RandomNumberGenerator.new()
var _rivers_by_index: Array[River] = []
var _edges_following_river: Dictionary = {}  # Dictionary[String, int]
var _erosion_by_point_index: PackedFloat32Array = []
var _all_water_body_point_indices: PackedInt32Array = []
var _all_adjacent_cell_indices: PackedInt32Array = []

func _init(
	lake_layer: LakeLayer,
	region_cell_layer: RegionCellLayer,
	height_layer: HeightLayer, 
	river_count: int,
	erode_depth: float,
	rng_seed: int,
) -> void:
	_lake_layer = lake_layer
	_region_cell_layer = region_cell_layer
	_height_layer = height_layer
	_river_count = river_count
	_erode_depth = erode_depth
	_rng.seed = rng_seed

func perform() -> void:
	_erosion_by_point_index.resize(_region_cell_layer.get_total_point_count())
	
	_setup_rivers()

func get_river_midstream_point_indices_by_index(river_index) -> PackedInt32Array:
	return _rivers_by_index[river_index].midstream_point_indices

func get_total_river_count() -> int:
	return len(_rivers_by_index)

func river_starts_at_lake(river_index: int) -> bool:
	return _rivers_by_index[river_index].starts_from_lake

func get_all_water_body_point_indices() -> PackedInt32Array:
	return _all_water_body_point_indices

func get_river_adjacent_cell_indices(river_index: int) -> PackedInt32Array:
	return _rivers_by_index[river_index].adjacent_cell_indices

func get_point_eroded_depth(point_index: int) -> float:
	return _erosion_by_point_index[point_index]

func get_river_following_points(point_a_index: int, point_b_index: int) -> int:
	"""Get the river flowing between these 2 points, else return -1 if no river present"""
	var key: String = KeyUtils.get_combined_key(point_a_index, point_b_index)
	if key in _edges_following_river:
		return _edges_following_river[key]
	return -1

func cell_touches_river(cell_ind: int) -> bool:
	return cell_ind in _all_water_body_point_indices

func _setup_rivers():
	# Get a copy of the list of lakes (will add the sea further down)
	var river_points: PackedInt32Array = []
	var lake_region_indices: PackedInt32Array = _lake_layer.get_lake_region_indices()
	
	# Find all the points not in the lakes OR the sea
	var water_bodies: PackedInt32Array = lake_region_indices.duplicate()
	water_bodies.append(_region_cell_layer.get_root_region_index())
	_all_water_body_point_indices = (
		_region_cell_layer.get_all_point_indices_for_region_indices_in_list(water_bodies)
	)
	var all_land_point_indices: PackedInt32Array = (
		_region_cell_layer.get_all_point_indices_not_in_point_index_list(_all_water_body_point_indices)
	)
	
	# For each lake outlet, get first point is the exit point of the lake
	for lake_index in lake_region_indices:
		var exit_point_index: int = _lake_layer.get_exit_point_index_by_lake_index(lake_index)
		if exit_point_index < 0:
			printerr("Lake %d didn't have an exit point, probably empty ¯\\_(ツ)_/¯" % lake_index)
			continue
		
		# Check we can extend to the second point immediately, it'll be the lowest non water point
		var neighbour_point_indices: Array = Array(
			_region_cell_layer.get_connected_point_indices_by_point_index(exit_point_index)
		).filter(
			func(point_index: int): return point_index in all_land_point_indices
		)
		neighbour_point_indices.sort_custom(_ascending_by_height)
		if len(neighbour_point_indices) > 0:
			var river_index = _create_new_river(true)
			_extend_river_by_point_index(river_index, exit_point_index)
			_extend_river_by_point_index(river_index, neighbour_point_indices[0])
			river_points.append_array([exit_point_index, neighbour_point_indices[0]])
	
	# Pick random land points as river start points
	ArrayUtils.shuffle_int32(_rng, all_land_point_indices)
	for i in range(_river_count - len(_rivers_by_index)):
		var river_index = _create_new_river()
		var land_point_index: int = all_land_point_indices[i]
		_extend_river_by_point_index(river_index, land_point_index)
		river_points.append(land_point_index)
	
	for river_index in range(len(_rivers_by_index)):
		_continue_river_by_index(river_index, all_land_point_indices, river_points)
	
	for river_index in range(len(_rivers_by_index)):
		_erode_river(river_index, _erode_depth)

func _create_new_river(starts_from_lake: bool = false) -> int:
	var river_index = len(_rivers_by_index)
	_rivers_by_index.append(River.new())
	_rivers_by_index[river_index].starts_from_lake = starts_from_lake
	return river_index

func _extend_river_by_point_index(river_index: int, point_index: int) -> void:
	if len(_rivers_by_index[river_index].midstream_point_indices) > 0:
		var last_point_index : int = _rivers_by_index[river_index].midstream_point_indices[-1]
		_update_edges_following_river(last_point_index, point_index, river_index)
	_rivers_by_index[river_index].midstream_point_indices.append(point_index)
	_update_river_adjacent_triangles(river_index, point_index)

func _update_river_adjacent_triangles(river_index: int, new_point_index: int) -> void:
	for cell_index in _region_cell_layer.get_triangles_using_point_by_index(new_point_index):
		if cell_index in _rivers_by_index[river_index].adjacent_cell_indices:
			continue
		var region_index: int = _region_cell_layer.get_region_index_for_cell(cell_index)
		if region_index in _lake_layer.get_lake_region_indices():
			continue
		if region_index == _region_cell_layer.get_root_region_index():
			continue
		_rivers_by_index[river_index].adjacent_cell_indices.append(cell_index)
		if not cell_index in _all_water_body_point_indices:
			_all_water_body_point_indices.append(cell_index)

func _get_most_downstream_point_in_river(river_index: int) -> int:
	return _rivers_by_index[river_index].midstream_point_indices[-1]

func _erode_river(river_index: int, erosion_depth: float) -> void:
	for point_index in _rivers_by_index[river_index].midstream_point_indices:
		if _erosion_by_point_index[point_index] > 0.0:
			# Point already eroded, skip
			continue
		_erosion_by_point_index[point_index] = erosion_depth
		_height_layer.edit_point_height(point_index, -erosion_depth)

func _continue_river_by_index(
	river_index: int, available_point_indices: PackedInt32Array, all_river_points: PackedInt32Array
) -> void:
	"""
	Continue a river (referred by its index) until it reaches another river
	or until it reaches a water body such as a lake or the sea
	"""
	# Find the lowest neighbour point that is in the available points
	var last_river_point: int = _get_most_downstream_point_in_river(river_index)
	var river_complete: bool = false
	while not river_complete:
		var neighbour_point_indices: Array = Array(
			_region_cell_layer.get_connected_point_indices_by_point_index(last_river_point)
		)
		neighbour_point_indices.sort_custom(_ascending_by_height)
		var lowest_neighbour: int = neighbour_point_indices[0]
		
		# If this river has no more available land based points to flow into
		if not lowest_neighbour in available_point_indices:
			river_complete = true
		
		# If this river has reached another river
		if lowest_neighbour in all_river_points:
			river_complete = true
		
		# Add the next (or last) river point
		_extend_river_by_point_index(river_index, lowest_neighbour)
		all_river_points.append(lowest_neighbour)
		last_river_point = _get_most_downstream_point_in_river(river_index)

func _ascending_by_height(index_a: int, index_b: int) -> bool:
	return _height_layer.get_point_height(index_a) < _height_layer.get_point_height(index_b)

func _update_edges_following_river(
	point_a_index: int, point_b_index: int, river_index: int
) -> void:
	"""Update the record of edges between cells along which rivers flow"""
	var key: String = KeyUtils.get_combined_key(point_a_index, point_b_index)
	_edges_following_river[key] = river_index


