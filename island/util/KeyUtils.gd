class_name KeyUtils
extends Object


static func get_combined_key(key_a: int, key_b: int) -> String:
	"""Get a key unique to the 2 values order should be unimportant"""
	return "%d:%d" % ([key_a, key_b] if key_a < key_b else [key_b, key_a])


static func get_combined_key_for_int32_array(key_array: PackedInt32Array) -> String:
	"""
	Get a key unique from the first 2 values in an int array
	the order should be unimportant
	"""
	return get_combined_key(key_array[0], key_array[1])


static func key_for_cell_and_point(cell_ind: int, point_ind: int) -> String:
	"""Get a key unique to the cell and the point used within that cell"""
	return "%d:%d" % [cell_ind, point_ind]
	
