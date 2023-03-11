class_name HeightLayer
extends Object

var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _rng := RandomNumberGenerator.new()

func _init(outline_manager: OutlineManager, lake_manager: LakeManager, rng_seed: int) -> void:
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_rng.seed = rng_seed

func perform() -> void:
	pass
