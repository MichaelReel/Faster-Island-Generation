class_name HeightLayer
extends Object

var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _region_cell_layer: RegionCellLayer
var _lake_layer: LakeLayer
var _sealevel_point_indices: PackedInt64Array = []
var _uphill_front_indices: PackedInt64Array = []
var _downhill_front_indices: PackedInt64Array = []
var _sealevel_started: bool = false
var _height_fronts_started: bool = false
var _downhill_complete: bool = false
var _uphill_complete: bool = false
var _point_height_set: Array[bool] = []
var _point_height: PackedFloat32Array = []
var _diff_height: float = 1.0
var _diff_height_max_multiplier: int = 1
var _uphill_height: float = _diff_height
var _downhill_height: float = -_diff_height

var _rng := RandomNumberGenerator.new()

func _init(outline_manager: OutlineManager, lake_manager: LakeManager, diff_height: float, diff_max_multi: int, rng_seed: int) -> void:
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_region_cell_layer = _outline_manager.get_region_cell_layer()
	_lake_layer = _lake_manager.get_lake_layer()
	_diff_height = diff_height
	_diff_height_max_multiplier = diff_max_multi
	_downhill_height = -_diff_height
	_uphill_height = _diff_height
	_rng.seed = rng_seed

func perform() -> void:
	_point_height_set.resize(_region_cell_layer.get_total_cell_count())
	_point_height.resize(_region_cell_layer.get_total_cell_count())
	
	while not _uphill_complete:
		if not _sealevel_started:
			_setup_sealevel()
			_sealevel_started = true
			continue
		
		if not _height_fronts_started:
			_setup_height_fronts()
			_height_fronts_started = true
			continue
		
		if not _downhill_complete:
			_step_downhill()
			if _downhill_front_indices.is_empty():
				_downhill_complete = true
			continue
		
		if not _uphill_complete:
			_step_uphill()
			if _uphill_front_indices.is_empty():
				_uphill_complete = true
			continue

func set_point_height(point_index: int, height: float) -> void:
	_point_height[point_index] = height
	_point_height_set[point_index] = true

func is_point_height_set(point_index: int) -> bool:
	return _point_height_set[point_index]

func get_point_height(point_index: int) -> float:
	return _point_height[point_index]

func edit_point_height(point_index: int, increment: float) -> void:
	"""Adjust the height of the point by adding the increment"""
	_point_height[point_index] += increment

func _setup_sealevel() -> void:
	""" Record each point on the edges between the island region frontier and the region itself """
	var island_region_index: int = _outline_manager.get_island_region_index()
	var front_cell_indices: PackedInt64Array = _region_cell_layer.get_front_cell_indices(island_region_index)
	var temp_sealevel_point_indices: Array[int] = []
	for front_cell_index in front_cell_indices:
		for point_index in _region_cell_layer.get_region_front_point_indices_by_front_cell_index(island_region_index, front_cell_index):
			if not point_index in temp_sealevel_point_indices:
				set_point_height(point_index, 0.0)
				temp_sealevel_point_indices.append(point_index)
	
	_sealevel_point_indices = temp_sealevel_point_indices

func _setup_height_fronts() -> void:
	"""Create the initial uphill and downhill point frontiers"""
	for center_point in _sealevel_point_indices:
		for point_index in _region_cell_layer.get_connected_point_indices_by_point_index(center_point):
			if not is_point_height_set(point_index):
				# Uphill or downhill neighbour?
				if not _region_cell_layer.point_has_any_cell_with_parent(point_index, _region_cell_layer.get_root_region_index()):
					set_point_height(point_index, _uphill_height)
					_uphill_front_indices.append(point_index)
				else:
					set_point_height(point_index, _downhill_height)
					_downhill_front_indices.append(point_index)

func _step_downhill() -> void:
	_downhill_height -= _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
	var new_downhill_front_indices: PackedInt64Array = []
	for center_point in _downhill_front_indices:
		for point_index in _region_cell_layer.get_connected_point_indices_by_point_index(center_point):
			if not is_point_height_set(point_index):
				set_point_height(point_index, _downhill_height)
				new_downhill_front_indices.append(point_index)
	_downhill_front_indices = new_downhill_front_indices

func _step_uphill() -> void:
	var lake_region_indices: PackedInt64Array = _lake_layer.get_lake_region_indices()
	_uphill_height += _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
	var new_uphill_front_indices: PackedInt64Array = []
	for center_point in _uphill_front_indices:
		for point_index in _region_cell_layer.get_connected_point_indices_by_point_index(center_point):
			if not is_point_height_set(point_index):
				new_uphill_front_indices.append(point_index)
				# If this point is on a sub-region lake,
				var lake_as_region_index: int = _region_cell_layer.point_has_any_cell_with_parent_in_list_get_region_index(
					point_index, lake_region_indices
				)
				if lake_as_region_index > -1 and not _lake_layer.lake_has_exit_point(lake_as_region_index):
					# Assume water can exit on this side, and lake is at this height
					_lake_layer.set_exit_point_index_by_lake_index(point_index, lake_as_region_index)
					_lake_layer.set_lake_height_by_region_index(_uphill_height, lake_as_region_index)
					# Add the lake perimeter points to the uphill
					new_uphill_front_indices.append_array(
						_region_cell_layer.get_outer_perimeter_point_indices(lake_as_region_index)
					)
					# Add any inside points to the downhill
					var inside_point_indices : PackedInt64Array = _region_cell_layer.get_inner_perimeter_point_indices(lake_as_region_index)
					if not inside_point_indices.is_empty():
						# Reset the downhill state, and set the downhill height
						_downhill_height = _uphill_height - _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
						_downhill_front_indices.append_array(inside_point_indices)
						_downhill_complete = false
	
	for point_index in new_uphill_front_indices:
		set_point_height(point_index, _uphill_height)
	_uphill_front_indices = new_uphill_front_indices
	
	# If a lake edge encountered, setup the downhill to form the bowl
	for point_index in _downhill_front_indices:
		set_point_height(point_index, _downhill_height)

func get_total_cell_count() -> int:
	return _region_cell_layer.get_total_cell_count()

func get_triangle_as_vector3_array_for_index_with_heights(cell_index) -> PackedVector3Array:
	var triangle_as_point_indices: PackedInt64Array = (
		_region_cell_layer.get_triangle_as_point_indices(cell_index)
	)
	return Array(triangle_as_point_indices).map(get_vector3_with_height_for_point_index)

func get_vector3_with_height_for_point_index(point_index: int) -> Vector3:
	return _region_cell_layer.get_point_as_vector3(point_index, _point_height[point_index])
