@tool
extends Node3D

@export var bounds_side: float = 50.0
@export var tri_side: float = 1.0
@export var random_seed: int = -2147483648

@onready var bounds : Mesh = $BoundsMesh.mesh

var _terrain_manager : TerrainManager

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_tool_execute(delta)
	if not Engine.is_editor_hint():
		_game_execute(delta)

func _tool_execute(_delta: float) -> void:
	bounds.size = Vector2.ONE * bounds_side

func _game_execute(_delta: float) -> void:
	bounds.size = Vector2.ONE * bounds_side
	_terrain_manager = TerrainManager.new(random_seed, tri_side, bounds_side)
	_terrain_manager.perform()
