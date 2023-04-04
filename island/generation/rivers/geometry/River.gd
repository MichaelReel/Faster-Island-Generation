class_name River
extends Object
"""
This is just a data structure for specific river data
"""

var midstream_point_indices: PackedInt32Array = []  # Indices of the points mid stream
var adjacent_cell_indices: PackedInt32Array = []  # Non water-body cells following the river
var starts_from_lake: bool = false
