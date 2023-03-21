class_name RiverLayer
extends Object


var _rng := RandomNumberGenerator.new()

func _init(rng_seed: int) -> void:
	_rng.seed = rng_seed

func perform() -> void:
	pass
