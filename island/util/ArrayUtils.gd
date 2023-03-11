class_name ArrayUtils
extends Object


static func shuffle_int64(rng: RandomNumberGenerator, target: PackedInt64Array) -> void:
	for i in range(len(target)):
		var j: int = rng.randi_range(0, len(target) - 1)
		var swap = target[i]
		target[i] = target[j]
		target[j] =swap
