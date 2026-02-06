extends Stage

const LowLODLayer: GDScript = preload("LowLODLayer.gd")

var _base_continuity_layer: LowLODLayer
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_height: float

func _init(
	base_continuity_layer: LowLODLayer,
	rng_seed: int,
	noise_height: float,
) -> void:
	_base_continuity_layer = base_continuity_layer
	_noise.seed = rng_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.fractal_lacunarity = 4.0
	_noise_height = noise_height

func perform() -> void:
	pass

func get_height_at_xz(xz: Vector2) -> float:
	var base_height: float = _base_continuity_layer.get_height_at_xz(xz)
	var noise: float = (_noise.get_noise_2dv(xz) * _noise_height) + 0.5 * _noise_height
	return base_height + noise

func _to_string() -> String:
	return "Noise Stage"
