class_name HeightManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
var _height_layer: HeightLayer
var _height_mesh: HeightMesh
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_manager: LakeManager,
	diff_height: float,
	diff_max_multi: int,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_rng.seed = rng_seed

	_height_layer = HeightLayer.new(
		_outline_manager, _lake_manager, diff_height, diff_max_multi, _rng.randi()
	)
	_height_mesh = HeightMesh.new(
		_outline_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_outline_manager.get_island_region_index(),
		_height_layer,
		material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
	_height_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_height_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Height Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _height_mesh
	}
