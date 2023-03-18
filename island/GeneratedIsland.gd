@tool
extends Node3D

@export var bounds_side: float = 50.0 :
	set(value):
		bounds_side = value
		_changes_pending = true

@export var tri_side: float = 1.0 :
	set(value):
		tri_side = value
		_changes_pending = true

@export var island_cell_count: int = 1000 :
	set(value):
		island_cell_count = value
		_changes_pending = true

@export var random_seed: int = -2147483648 :
	set(value):
		random_seed = value
		_changes_pending = true

@export_category("lake_creation")
@export var max_lake_regions: int = 6
@export var max_lakes_per_region: int = 3

@export_category("height_map_creation")
@export var diff_height: float = 0.2
@export var diff_max_multi: int = 3

@export_category("debug_materials")
@export var sub_water: Material = Material.new()
@export var ground: Material = Material.new()
@export var lake_debug: Material = Material.new()
@export var region_debug: Material = Material.new()

@onready var bounds : Mesh = $BoundsMesh.mesh
@onready var material_lib: MaterialLib = MaterialLib.new()

var _terrain_manager : TerrainManager
var _changes_pending : bool = true
var _mesh_instance_dict : Dictionary = {}

func _ready() -> void:
	material_lib.set_material("sub_water", sub_water)
	material_lib.set_material("ground", ground)
	material_lib.set_material("lake_debug", lake_debug)
	material_lib.set_material("region_debug", region_debug)

func _process(delta: float) -> void:
	if not _changes_pending:
		return
	if Engine.is_editor_hint():
		_tool_execute(delta)
	if not Engine.is_editor_hint():
		_game_execute(delta)
	_changes_pending = false

func _tool_execute(_delta: float) -> void:
	bounds.size = Vector2.ONE * bounds_side
	_terrain_manager = TerrainManager.new(
		random_seed,
		material_lib,
		tri_side,
		bounds_side,
		island_cell_count,
		max_lake_regions,
		max_lakes_per_region,
		diff_height,
		diff_max_multi,
	)
	var _err2 = _terrain_manager.connect("stage_complete", _on_stage_complete)
	_terrain_manager.perform("Outline Stage")

func _game_execute(_delta: float) -> void:
	bounds.size = Vector2.ONE * bounds_side
	_terrain_manager = TerrainManager.new(
		random_seed,
		material_lib,
		tri_side,
		bounds_side,
		island_cell_count,
		max_lake_regions,
		max_lakes_per_region,
		diff_height,
		diff_max_multi,
	)
	var _err1 = _terrain_manager.connect("all_stages_complete", _on_all_stages_complete)
	var _err2 = _terrain_manager.connect("stage_complete", _on_stage_complete)
	var _err3 = _terrain_manager.connect("stage_percent_complete", _on_stage_percent_complete)
	_terrain_manager.perform()

func _on_stage_percent_complete(stage: Stage, percent: float) -> void:
	print("%3d%% of %s completed at t: %7.6f sec" % [percent, stage, Time.get_ticks_usec() / 1000000.0])

func _on_stage_complete(stage: Stage, duration: int) -> void:
	print("        %s completed in %d usecs" % [stage, duration])
	_update_meshes_by_dictionary(stage.get_mesh_dict())

func _on_all_stages_complete() -> void:
	print("High Level Terrain stages complete")

func _update_meshes_by_dictionary(mesh_dict: Dictionary) -> void:
	for mesh_name in mesh_dict:
		if mesh_name in _mesh_instance_dict:
			remove_child(_mesh_instance_dict[mesh_name])
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var new_mesh = mesh_dict[mesh_name]
		mesh_instance.mesh = new_mesh
		_mesh_instance_dict[mesh_name] = mesh_instance
		add_child(mesh_instance)
