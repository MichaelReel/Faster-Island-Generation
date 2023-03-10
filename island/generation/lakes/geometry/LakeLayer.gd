class_name LakeLayer
extends Object

var _outline_manager: OutlineManager
var _region_divide_layer: RegionDivideLayer
var _lakes_per_region: int
var _region_cell_layer: RegionCellLayer
var _lake_indices: PackedInt64Array
var _rng := RandomNumberGenerator.new()

func _init(outline_manager: OutlineManager, region_divide_layer: RegionDivideLayer, lakes_per_region: int, rng_seed: int) -> void:
	_outline_manager = outline_manager
	_region_divide_layer = region_divide_layer
	_lakes_per_region = lakes_per_region
	_rng.seed = rng_seed
	_region_cell_layer = _outline_manager.get_region_cell_layer()

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
	
	frontier_cleanup()
	
#	for region in _regions:
#		var _lines: Array[Edge] = region.get_perimeter_lines(false)

func get_lake_region_indices() -> PackedInt64Array:
	return _lake_indices

func _setup_lake_regions() -> void:
	var region_indices: PackedInt64Array = _region_divide_layer.get_region_indices()
	for region_index in region_indices:
		var start_triangles = _region_cell_layer.get_some_triangles_in_region(_lakes_per_region, region_index, _rng)
		
		for tri_index in start_triangles:
			var new_lake = Region.new(_region_cell_layer, region_index)
			_region_cell_layer.add_cell_to_subregion_front(tri_index, new_lake.get_region_index())
			_lake_indices.append(new_lake.get_region_index())

func _create_internal_frontier(lake_region_index: int) -> PackedInt64Array:
	"""Produce an array of the internal cells along the inside edge"""
	var inner_front: PackedInt64Array = []
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
	var inner_front: PackedInt64Array = _create_internal_frontier(lake_region_index)
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
	cell_index: int, inner_front: PackedInt64Array, lake_region_index: int
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

func frontier_cleanup() -> void:
	"""
	There will be some frontier cells that (somehow) got left behind by the smoothing step
	In lieu of fixing the code that doesn't remove them, just find and remove them now
	"""
	for cell_index in range(_region_cell_layer.get_cell_count()):
		var fronts_by_cell_index = _region_cell_layer.get_region_fronts_by_cell_index(cell_index)
		if fronts_by_cell_index.is_empty():
			continue
		for region_index in fronts_by_cell_index:
			var has_neighbour_in_region = false
			for neighbour_index in _region_cell_layer.get_edge_sharing_neighbours(cell_index):
				if _region_cell_layer.get_region_by_index_for_cell_index(neighbour_index) == region_index:
					has_neighbour_in_region = true
					break
			
			if not has_neighbour_in_region:
				_region_cell_layer.remove_cell_from_subregion_front(cell_index, region_index)
