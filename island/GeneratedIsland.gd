@tool
extends Node3D

@export_category("In Editor Only")
@export var tool_changes_pending: bool = false
@export var editor_display: Stage.GlobalStageProgressStep = Stage.GlobalStageProgressStep.OUTLINE

@export_category("Base Settings")
@export var random_seed: int = -2147483648
@export var terrain_config: TerrainConfig = TerrainConfig.new()

@export_category("Mesh Materials")
@export var sub_water: Material = Material.new()
@export var ground: Material = Material.new()
@export var water_surface: Material = Material.new()
@export var region_debug: Material = Material.new()
@export var settlement: Material = Material.new()
@export var road: Material = Material.new()
@export var cliff: Material = Material.new()

@onready var bounds : Mesh = $BoundsMesh.mesh
@onready var material_lib: MaterialLib = MaterialLib.new()

var _runtime_changes_pending: bool = true
var _terrain_manager : TerrainManager
var _mesh_instance_dict : Dictionary = {}

func _ready() -> void:
	material_lib.set_material("sub_water", sub_water)
	material_lib.set_material("ground", ground)
	material_lib.set_material("water_surface", water_surface)
	material_lib.set_material("region_debug", region_debug)
	material_lib.set_material("settlement", settlement)
	material_lib.set_material("road", road)
	material_lib.set_material("cliff", cliff)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and tool_changes_pending:
		_tool_execute(delta)
		tool_changes_pending = false
	
	if not Engine.is_editor_hint() and _runtime_changes_pending:
		_game_execute(delta)
		_runtime_changes_pending = false

func get_height_at_xz(xz: Vector2) -> float:
	if _terrain_manager:
		return _terrain_manager.get_height_at_xz(xz)
	else:
		return 0.0

func _tool_execute(_delta: float) -> void:
	for mesh_name in _mesh_instance_dict.keys().duplicate():
		remove_child(_mesh_instance_dict[mesh_name])
		_mesh_instance_dict.erase(mesh_name)
	bounds.size = Vector2.ONE * terrain_config.bounds_side
	_terrain_manager = TerrainManager.new(
		random_seed,
		material_lib,
		terrain_config,
	)
	var _err2 = _terrain_manager.connect("stage_complete", _on_stage_complete)
	_terrain_manager.perform(editor_display)

func _game_execute(_delta: float) -> void:
	bounds.size = Vector2.ONE * terrain_config.bounds_side
	_terrain_manager = TerrainManager.new(
		random_seed,
		material_lib,
		terrain_config,
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
