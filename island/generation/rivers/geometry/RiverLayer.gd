class_name RiverLayer
extends Object

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _river_count: int
var _erode_depth: float
var _rng := RandomNumberGenerator.new()
var _rivers_by_index: Array[River] = []
var _erosion_by_point_index: PackedFloat32Array = []

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

func get_river_midstream_point_indices_by_index(river_index) -> PackedInt64Array:
	return _rivers_by_index[river_index].midstream_point_indices

func get_total_river_count() -> int:
	return len(_rivers_by_index)

func river_starts_at_lake(river_index: int) -> bool:
	return _rivers_by_index[river_index].starts_from_lake

func _setup_rivers():
	# Get a copy of the list of lakes (will add the sea futher down)
	var river_points: PackedInt64Array = []
	var lake_region_indices: PackedInt64Array = _lake_layer.get_lake_region_indices()
	
	# Find all the points not in the lakes OR the sea
	var water_bodies: PackedInt64Array = lake_region_indices.duplicate()
	water_bodies.append(_region_cell_layer.get_root_region_index())
	var all_water_body_point_indices: PackedInt64Array = (
		_region_cell_layer.get_all_point_indices_for_region_indices_in_list(water_bodies)
	)
	var all_land_point_indices: PackedInt64Array = (
		_region_cell_layer.get_all_point_indices_not_in_point_index_list(all_water_body_point_indices)
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
		neighbour_point_indices.sort_custom(ascending_by_height)
		if len(neighbour_point_indices) > 0:
			var river_index = _create_new_river(true)
			_extend_river_by_point_index(river_index, exit_point_index)
			_extend_river_by_point_index(river_index, neighbour_point_indices[0])
			river_points.append_array([exit_point_index, neighbour_point_indices[0]])
	
	# Pick random land points as river start points
	ArrayUtils.shuffle_int64(_rng, all_land_point_indices)
	for i in range(_river_count - len(_rivers_by_index)):
		var river_index = _create_new_river()
		var land_point_index: int = all_land_point_indices[i]
		_extend_river_by_point_index(river_index, land_point_index)
		river_points.append(land_point_index)
	
	for river_index in range(len(_rivers_by_index)):
		continue_river_by_index(river_index, all_land_point_indices, river_points)
	
	for river_index in range(len(_rivers_by_index)):
		_erode_river(river_index, _erode_depth)

func _create_new_river(starts_from_lake: bool = false) -> int:
	var river_index = len(_rivers_by_index)
	_rivers_by_index.append(River.new())
	_rivers_by_index[river_index].starts_from_lake = starts_from_lake
	return river_index

func _extend_river_by_point_index(river_index: int, point_index: int) -> void:
	_rivers_by_index[river_index].midstream_point_indices.append(point_index)

func _get_lowest_point_in_river(river_index: int) -> int:
	return _rivers_by_index[river_index].midstream_point_indices[-1]

func _erode_river(river_index: int, erosion_depth: float) -> void:
	for point_index in _rivers_by_index[river_index].midstream_point_indices:
		if _erosion_by_point_index[point_index] > 0.0:
			# Point already eroded, skip
			continue
		_erosion_by_point_index[point_index] = erosion_depth
		_height_layer.edit_point_height(point_index, -erosion_depth)

func get_point_eroded_depth(point_index: int) -> float:
	return _erosion_by_point_index[point_index]

func continue_river_by_index(
	river_index: int, available_point_indices: PackedInt64Array, all_river_points: PackedInt64Array
) -> void:
	"""
	Continue a river (referred by its index) until it reaches another river
	or until it reaches a water body such as a lake or the sea
	"""
	# Find the lowest neighbour point that is in the available points
	var last_river_point: int = _get_lowest_point_in_river(river_index)
	while true:
		var neighbour_point_indices: Array = Array(
			_region_cell_layer.get_connected_point_indices_by_point_index(last_river_point)
		)
		neighbour_point_indices.sort_custom(ascending_by_height)
		var lowest_neighbour: int = neighbour_point_indices[0]
		if not lowest_neighbour in available_point_indices:
			break
		
		if lowest_neighbour in all_river_points:
			break
		
		_extend_river_by_point_index(river_index, lowest_neighbour)
		all_river_points.append(lowest_neighbour)
	
	# Add the lowest point (likely in a water body or river) to finish
	var neighbour_point_indices: Array = Array(
		_region_cell_layer.get_connected_point_indices_by_point_index(last_river_point)
	)
	neighbour_point_indices.sort_custom(ascending_by_height)
	var lowest_neighbour: int = neighbour_point_indices[0]
	_extend_river_by_point_index(river_index, lowest_neighbour)
	all_river_points.append(lowest_neighbour)
	
func ascending_by_height(index_a: int, index_b: int) -> bool:
	return _height_layer.get_point_height(index_a) < _height_layer.get_point_height(index_b)
