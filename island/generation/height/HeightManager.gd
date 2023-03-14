class_name HeightManager
extends Stage

var _grid_manager: GridManager
var _outline_manager: OutlineManager
var _lake_manager: LakeManager
#var _height_layer: HeightLayer
var _height_mesh: HeightMesh
var _rng := RandomNumberGenerator.new()

func _init(
	grid_manager: GridManager,
	outline_manager: OutlineManager,
	lake_manager: LakeManager,
	material_lib: MaterialLib,
	rng_seed: int
) -> void:
	_grid_manager = grid_manager
	_outline_manager = outline_manager
	_lake_manager = lake_manager
	_rng.seed = rng_seed

#	_height_layer = HeightLayer()
	_height_mesh = HeightMesh.new(
		_grid_manager.get_tri_cell_layer(),
		_outline_manager.get_region_cell_layer(),
		_lake_manager.get_lake_layer(),
		_outline_manager.get_island_region_index(),
		material_lib
	)

func perform() -> void:
	emit_signal("percent_complete", self, 0.0)
#	_height_layer.perform()
	emit_signal("percent_complete", self, 50.0)
	_height_mesh.perform()
	emit_signal("percent_complete", self, 100.0)

func _to_string() -> String:
	return "Height Stage"

func get_mesh_dict() -> Dictionary:
	return {
		"terrain": _height_mesh
	}
