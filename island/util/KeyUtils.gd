class_name KeyUtils
extends Object


static func get_combined_key(key_a: int, key_b: int) -> String:
	"""Get a key unique to the 2 values order should be unimportant"""
	return "%d:%d" % ([key_a, key_b] if key_a < key_b else [key_b, key_a])
