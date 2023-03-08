class_name Region
extends Object
"""
The generic Region data object
"""

var _region_cell_layer: RegionCellLayer
var _region_front: PackedInt64Array = []  # Indices of cells on the potential boundaries
var _region_cells: PackedInt64Array = []  # Indices of cells in this region
var _parent_index: int  # Index of the region upon which this region is carved
var _region_index: int

func _init(region_cell_layer: RegionCellLayer, parent_index: int) -> void:
	_region_cell_layer = region_cell_layer
	_parent_index = parent_index
	_region_index = _region_cell_layer.register_region(self)

func get_region_index() -> int:
	return _region_index

func get_parent_index() -> int:
	return _parent_index

func add_cell_index_to_front(cell_index: int) -> void:
	if cell_index in _region_cells:
		_region_cells.remove_at(_region_cells.find(cell_index))
	_region_front.append(cell_index)

func add_cell_index_to_region(cell_index: int) -> void:
	if cell_index in _region_front:
		_region_front.remove_at(_region_front.find(cell_index))
	_region_cells.append(cell_index)
	_region_cell_layer.update_cell_to_region(cell_index, _region_index)

func get_cell_count() -> int:
	return len(_region_cells)

func get_cell_indices() -> PackedInt64Array:
	return _region_cells

func front_cell_indices() -> PackedInt64Array:
	return _region_front

func front_empty() -> bool:
	return _region_front.is_empty()

func random_front_cell_index(rng: RandomNumberGenerator) -> int:
	return _region_front[rng.randi_range(0, len(_region_front) - 1)]

func surrounding_cell_with_index(cell_index: int) -> bool:
	return _region_cell_layer.region_surrounds_cell(_region_index, cell_index)
