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
	
