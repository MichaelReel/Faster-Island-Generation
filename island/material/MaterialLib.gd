class_name MaterialLib
extends Resource

var _material_dict: Dictionary = {}
var _default_material: Material = StandardMaterial3D.new()

func _ready():
	_default_material.albedo_color = Color8(255, 0, 255, 255)

func set_material(mat_name: String, material: Material) -> void:
	_material_dict[mat_name] = material

func get_material(mat_name: String) -> Material:
	var mat = _material_dict.get(mat_name, _default_material)
	return mat
