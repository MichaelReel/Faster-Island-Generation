class_name LakeLayer
extends Object

var _tri_cell_layer: TriCellLayer
var _region_divide_layer: RegionDivideLayer
var _lakes_per_region: int
var _region_cell_layer: RegionCellLayer
var _lake_indices: PackedInt32Array
var _exit_point_index_by_lake_index: Dictionary = {}  # Map from lake's region_index to the exit point_index
var _lake_height_by_region_index: Dictionary = {}  # Map from lake's region_index to the exit point_index
var _water_body_cell_indices: PackedInt32Array = []  # Cells that are in a water body
var _non_water_body_cell_indices: PackedInt32Array = []  # Cells that are NOT in a water body
var _rng := RandomNumberGenerator.new()

func _init(tri_cell_layer: TriCellLayer, region_cell_layer: RegionCellLayer, region_divide_layer: RegionDivideLayer, lakes_per_region: int, rng_seed: int) -> void:
	_tri_cell_layer = tri_cell_layer
	_region_cell_layer = region_cell_layer
	_region_divide_layer = region_divide_layer
	_lakes_per_region = lakes_per_region
	_rng.seed = rng_seed

func perform() -> void:
	_setup_lake_regions()
	
	var expansion_done := false
	while not expansion_done:
		var done = true
		for lake_index in _lake_indices:
			if not _region_cell_layer.expand_region_into_parent(lake_index, _rng):
				done = false
		if done:
			expansion_done = true
	
	for lake_index in _lake_indices:
		_region_divide_layer.reduce_region_and_create_margin(lake_index)
		_perform_lake_smoothing(lake_index)
	
	_frontier_cleanup()
	
	# Discover the inner and outer point perimeters
	_identify_perimeter_points()

func get_lake_region_indices() -> PackedInt32Array:
	return _lake_indices

func lake_has_exit_point(region_index: int) -> bool:
	return _exit_point_index_by_lake_index.has(region_index)

func get_exit_point_index_by_lake_index(region_index: int) -> int:
	"""Return the exit point for the given region or -1 if none was recorded"""
	return _exit_point_index_by_lake_index.get(region_index, -1)

func set_exit_point_index_by_lake_index(point_index: int, region_index: int) -> void:
	_exit_point_index_by_lake_index[region_index] = point_index

func get_lake_height_by_region_index(region_index: int) -> float:
	"""Return the height of the lake, if it has been set. Default to sealevel (0.0) otherwise"""
	return _lake_height_by_region_index.get(region_index, 0.0)

func set_lake_height_by_region_index(height: float, region_index: int) -> void:
	_lake_height_by_region_index[region_index] = height

func get_water_body_cell_indices() -> PackedInt32Array:
	if len(_water_body_cell_indices) == 0:
		_divide_cells_by_water_body()
	return _water_body_cell_indices

func get_non_water_body_cell_indices() -> PackedInt32Array:
	if len(_non_water_body_cell_indices) == 0:
		_divide_cells_by_water_body()
	return _non_water_body_cell_indices

func _setup_lake_regions() -> void:
	var region_indices: PackedInt32Array = _region_divide_layer.get_region_indices()
	for region_index in region_indices:
		var start_triangles = _region_cell_layer.get_some_triangles_in_region(_lakes_per_region, region_index, _rng)
		
		for tri_index in start_triangles:
			var new_lake_region_index = _region_cell_layer.create_new_region(region_index)
			_region_cell_layer.add_cell_to_subregion_front(tri_index, new_lake_region_index)
			_lake_indices.append(new_lake_region_index)

func _create_internal_frontier(lake_region_index: int) -> PackedInt32Array:
	"""Produce an array of the internal cells along the inside edge"""
	var inner_front: PackedInt32Array = []
	for outer_front_cell_index in _region_cell_layer.get_front_cell_indices(lake_region_index):
		for inner_cell in _region_divide_layer.get_indices_of_neighbours_with_parent(
			outer_front_cell_index, lake_region_index
		):
			if not inner_cell in inner_front:
				inner_front.append(inner_cell)
	return inner_front

func _perform_lake_smoothing(lake_region_index: int) -> void:
	"""
	Smooth the edges of the lakes to remove flat internal edge areas
	"""
	# Create an internal frontier for the lake
	var inner_front: PackedInt32Array = _create_internal_frontier(lake_region_index)
	var parent_index: int = _region_cell_layer.get_parent_index_by_region_index(lake_region_index)
	# Remove internal frontier cells that are surrounded
	var still_smoothing: bool = true
	while still_smoothing:
		still_smoothing = false
		for cell_ind in inner_front:
			if _region_cell_layer.region_surrounds_cell(parent_index, cell_ind):
				_move_cell_from_inner_front_to_outer_front(cell_ind, inner_front, lake_region_index)
				still_smoothing = true


func _move_cell_from_inner_front_to_outer_front(
	cell_index: int, inner_front: PackedInt32Array, lake_region_index: int
) -> void:
	"""
	This will perform:
	- the move from a cell to the parent, 
	- update of the frontier, 
	- and update of the inner_frontier
	"""
	var parent_index: int = _region_cell_layer.get_parent_index_by_region_index(lake_region_index)
	
	# Move the cell out of the region and into to front
	_region_cell_layer.remove_cell_from_current_subregion(cell_index)
	_region_cell_layer.add_cell_to_subregion_front(cell_index, lake_region_index)
	
	# Update the frontier cells
	for neighbour_ind in _region_divide_layer.get_indices_of_edge_and_corner_neighbours_with_parent(cell_index, parent_index):
		if neighbour_ind in _region_cell_layer.get_front_cell_indices(lake_region_index):
			# Check if need to remove from frontier
			if _region_divide_layer.count_neighbours_with_parent(neighbour_ind, lake_region_index) == 0:
				_region_cell_layer.remove_cell_from_subregion_front(neighbour_ind, lake_region_index)
		else:
			# Check if need to add to frontier
			if _region_divide_layer.count_neighbours_with_parent(neighbour_ind, lake_region_index) > 0:
				_region_cell_layer.add_cell_to_subregion_front(neighbour_ind, lake_region_index)
	
	# Update the inner frontier
	inner_front.remove_at(inner_front.find(cell_index))
	for neighbour_ind in _region_divide_layer.get_indices_of_neighbours_with_parent(cell_index, lake_region_index):
		if not neighbour_ind in inner_front:
			inner_front.append(neighbour_ind)

func _frontier_cleanup() -> void:
	"""
	There will be some frontier cells that (somehow) got left behind by the smoothing step
	In lieu of fixing the code that doesn't remove them, just find and remove them now
	"""
	for cell_index in range(_tri_cell_layer.get_total_cell_count()):
		var fronts_by_cell_index = _region_cell_layer.get_region_fronts_by_cell_index(cell_index)
		if fronts_by_cell_index.is_empty():
			continue
		for region_index in fronts_by_cell_index:
			var has_neighbour_in_region = false
			for neighbour_index in _tri_cell_layer.get_edge_sharing_neighbours(cell_index):
				if _region_cell_layer.get_region_index_for_cell(neighbour_index) == region_index:
					has_neighbour_in_region = true
					break
			
			if not has_neighbour_in_region:
				_region_cell_layer.remove_cell_from_subregion_front(cell_index, region_index)

func _identify_perimeter_points() -> void:
	for region_index in _lake_indices:
		_region_cell_layer.identify_perimeter_points_for_region(region_index)

func _divide_cells_by_water_body() -> void:
	var water_region_indices: PackedInt32Array = _lake_indices.duplicate()
	water_region_indices.append(_region_cell_layer.get_root_region_index())
	
	for cell_ind in range(_tri_cell_layer.get_total_cell_count()):
		# Include under water cells in water cell, else include in non water cells
		var region_index: int = _region_cell_layer.get_region_index_for_cell(cell_ind)
		if region_index in water_region_indices:
			_water_body_cell_indices.append(cell_ind)
		else:
			_non_water_body_cell_indices.append(cell_ind)
