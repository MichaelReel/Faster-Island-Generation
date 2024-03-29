extends Object
"""
This is just a data structure for specific region data
"""

var region_front: PackedInt32Array = []  # Indices of cells on the potential boundaries
var region_cells: PackedInt32Array = []  # Indices of cells in this region
var parent_index: int  # Index of the region upon which this region is carved
var region_index: int
var point_indices_calculated: bool
var point_indices_in_region: PackedInt32Array = []
var outer_perimeter_point_indices: PackedInt32Array = []
var inner_perimeter_point_indices: PackedInt32Array = []

