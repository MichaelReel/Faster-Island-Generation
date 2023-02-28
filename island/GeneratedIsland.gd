@tool
extends Node3D

@export var bounds_size: Vector2 = Vector2(2, 2)
@export var random_seed: int = -2147483648

@onready var bounds : Mesh = $BoundsMesh.mesh

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_tool_execute(delta)
	if not Engine.is_editor_hint():
		_game_execute(delta)

func _tool_execute(_delta: float) -> void:
	bounds.size = bounds_size

func _game_execute(_delta: float) -> void:
	bounds.size = bounds_size
